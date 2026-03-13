import 'dart:async';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

/// Defines a single looping music layer with its own chord/note progression.
///
/// Add entries to [intensityLayers] to create additional intensity levels.
/// Each layer is activated on top of the previous ones as the player gets
/// closer to the target.
class MusicLayer {
  /// Each entry is a list of MIDI note numbers played simultaneously per step.
  final List<List<int>> chords;

  /// MIDI channel used for this layer.
  final int channel;

  /// Duration of each chord step in milliseconds (before tempo scaling).
  final int baseDurationMs;

  /// If non-null, each note is automatically stopped after this many
  /// milliseconds (useful for percussion hits).
  final int? noteStopMs;

  /// Velocity (loudness) for notes in this layer (0–127).
  final int velocity;

  /// SoundFont bank number.
  final int bank;

  /// MIDI program number (instrument).
  final int program;

  const MusicLayer({
    required this.chords,
    required this.channel,
    this.baseDurationMs = 500,
    this.noteStopMs,
    this.velocity = 80,
    this.bank = 0,
    this.program = 0,
  });
}

/// Ordered list of intensity layers. Layer 0 is always playing; each
/// subsequent layer is added as the player gets closer to the target.
///
/// To add a new intensity level, simply append a [MusicLayer] entry here.
/// The distance thresholds in [getProximityIntensity] will auto-adjust when
/// the [numLevels] argument is set to `intensityLayers.length`.
const List<MusicLayer> intensityLayers = [
  // Layer 0: Base chord progression (C – Am – F – G), always playing.
  MusicLayer(
    chords: [
      [60, 64, 67], // C major
      [57, 60, 64], // A minor
      [53, 57, 60], // F major
      [55, 59, 62], // G major
    ],
    channel: 0,
    baseDurationMs: 2000,
    bank: 0,
    program: 43,
  ),
  // Layer 1: Backing percussion — kick on beats 1 & 3, snare on beats 2 & 4.
  MusicLayer(
    chords: [
      [36], // kick drum
      [38], // snare drum
      [36], // kick drum
      [38], // snare drum
    ],
    channel: 9,
    baseDurationMs: 500,
    noteStopMs: 100,
    velocity: 100,
    bank: 128,
    program: 0,
  ),
  // Layer 2: High melody (C5 – A4 – F4 – G4), added when very close.
  MusicLayer(
    chords: [
      [72], // C5
      [69], // A4
      [65], // F4
      [67], // G4
    ],
    channel: 1,
    baseDurationMs: 500,
    bank: 0,
    program: 73, // flute
  ),
];

/// A continuously looping MIDI player driven by [intensityLayers].
///
/// Call [setIntensityLevel] to activate layers incrementally as the player
/// approaches the target. Supports tempo scaling via [speedUp].
class MidiPlayer {
  final MidiPro _midiPro = MidiPro();
  int? _sfId;

  late final List<int> _stepIndices;
  late final List<Timer?> _timers;
  int _activeLayerCount = 0;
  double _tempo = 1.0;
  bool _isInitialized = false;

  MidiPlayer() {
    _stepIndices = List.filled(intensityLayers.length, 0);
    _timers = List.filled(intensityLayers.length, null);
  }

  /// Loads the soundfont and configures MIDI instruments for all layers.
  Future<void> initialize() async {
    _sfId = await _midiPro.loadSoundfontAsset(
      assetPath: 'assets/weedsgm3.sf2',
      bank: 0,
      program: 0,
    );
    // Configure each unique channel once.
    final configured = <int>{};
    for (final layer in intensityLayers) {
      if (configured.add(layer.channel)) {
        await _midiPro.selectInstrument(
          sfId: _sfId!,
          channel: layer.channel,
          bank: layer.bank,
          program: layer.program,
        );
      }
    }
    _isInitialized = true;
  }

  /// Starts the base layer (layer 0) looping.
  void start() {
    if (!_isInitialized) return;
    _startLayer(0);
    _activeLayerCount = 1;
  }

  /// Activates all layers up to (and including) [level].
  ///
  /// [level] is clamped to the range [1, intensityLayers.length]. Layers are
  /// never deactivated once started, matching the original one-way behaviour.
  void setIntensityLevel(int level) {
    if (!_isInitialized) return;
    final target = level.clamp(1, intensityLayers.length);
    while (_activeLayerCount < target) {
      _startLayer(_activeLayerCount);
      _activeLayerCount++;
    }
  }

  /// Scales the playback tempo by [multiplier] (e.g. 2.0 = twice as fast).
  void speedUp(double multiplier) {
    _tempo = multiplier;
    for (int i = 0; i < _activeLayerCount; i++) {
      _timers[i]?.cancel();
      _scheduleStep(i);
    }
  }

  void _startLayer(int index) {
    _playStep(index);
    _scheduleStep(index);
  }

  void _scheduleStep(int index) {
    final layer = intensityLayers[index];
    final duration = (layer.baseDurationMs / _tempo).round();
    _timers[index] = Timer(Duration(milliseconds: duration), () {
      _stopStep(index);
      _stepIndices[index] = (_stepIndices[index] + 1) % layer.chords.length;
      _playStep(index);
      _scheduleStep(index);
    });
  }

  void _playStep(int index) {
    if (_sfId == null) return;
    final layer = intensityLayers[index];
    for (final note in layer.chords[_stepIndices[index]]) {
      _midiPro.playNote(
          sfId: _sfId!,
          channel: layer.channel,
          key: note,
          velocity: layer.velocity,
      );
      if (layer.noteStopMs != null) {
        Timer(Duration(milliseconds: layer.noteStopMs!), () {
          _midiPro.stopNote(sfId: _sfId!, channel: layer.channel, key: note);
        });
      }
    }
  }

  void _stopStep(int index) {
    if (_sfId == null) return;
    final layer = intensityLayers[index];
    // Percussion notes stop themselves via noteStopMs; skip explicit stop.
    if (layer.noteStopMs != null) return;
    for (final note in layer.chords[_stepIndices[index]]) {
      _midiPro.stopNote(sfId: _sfId!, channel: layer.channel, key: note);
    }
  }

  /// Stops all active layers.
  void stop() {
    for (int i = 0; i < intensityLayers.length; i++) {
      _timers[i]?.cancel();
    }
    if (_isInitialized) {
      for (int i = 0; i < _activeLayerCount; i++) {
        _stopStep(i);
      }
    }
  }

  /// Stops playback and releases resources.
  void dispose() {
    stop();
    _isInitialized = false;
  }
}