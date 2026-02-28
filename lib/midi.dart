import 'dart:async';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

/// A continuously looping MIDI player with a simple chord progression.
///
/// Plays a C – Am – F – G chord loop and supports increasing the tempo
/// and adding an extra percussion layer as the player approaches a target.
class MidiPlayer {
  final MidiPro _midiPro = MidiPro();
  int? _sfId;

  // Chord progression: C major – A minor – F major – G major
  static const List<List<int>> _chords = [
    [60, 64, 67], // C major
    [57, 60, 64], // A minor
    [53, 57, 60], // F major
    [55, 59, 62], // G major
  ];

  // Backing beat: kick (36) on beats 1 & 3, snare (38) on beats 2 & 4
  static const List<int> _beatPattern = [36, 38, 36, 38];

  int _currentChordIndex = 0;
  int _currentBeatIndex = 0;
  double _tempo = 1.0;
  bool _beatLayerEnabled = false;
  bool _isInitialized = false;
  Timer? _chordTimer;
  Timer? _beatTimer;

  // Base durations in milliseconds
  static const int _baseChordDurationMs = 2000;
  static const int _baseBeatDurationMs = 500;

  /// Loads the soundfont and configures MIDI instruments.
  Future<void> initialize() async {
    _sfId = await _midiPro.loadSoundfontAsset(
      assetPath: 'assets/weedsgm3.sf2',
      bank: 0,
      program: 0,
    );
    await _midiPro.selectInstrument(
      sfId: _sfId!,
      channel: 0,
      bank: 0,
      program: 0,
    );
    // Channel 9 is the GM percussion channel
    await _midiPro.selectInstrument(
      sfId: _sfId!,
      channel: 9,
      bank: 128,
      program: 0,
    );
    _isInitialized = true;
  }

  /// Starts the looping chord progression.
  void start() {
    if (!_isInitialized) return;
    _playCurrentChord();
    _scheduleChordTransition();
  }

  void _scheduleChordTransition() {
    final duration = (_baseChordDurationMs / _tempo).round();
    _chordTimer = Timer(Duration(milliseconds: duration), () {
      _stopCurrentChord();
      _currentChordIndex = (_currentChordIndex + 1) % _chords.length;
      _playCurrentChord();
      _scheduleChordTransition();
    });
  }

  void _playCurrentChord() {
    if (_sfId == null) return;
    for (final note in _chords[_currentChordIndex]) {
      _midiPro.playNote(sfId: _sfId!, channel: 0, key: note, velocity: 80);
    }
  }

  void _stopCurrentChord() {
    if (_sfId == null) return;
    for (final note in _chords[_currentChordIndex]) {
      _midiPro.stopNote(sfId: _sfId!, channel: 0, key: note);
    }
  }

  /// Increases the playback speed by [multiplier] (e.g. 2.0 = twice as fast).
  void speedUp(double multiplier) {
    _tempo = multiplier;
    _chordTimer?.cancel();
    if (_isInitialized) {
      _scheduleChordTransition();
      if (_beatLayerEnabled) {
        _beatTimer?.cancel();
        _scheduleBeat();
      }
    }
  }

  /// Enables the backing percussion layer (kick + snare).
  void addLayer() {
    if (!_isInitialized || _beatLayerEnabled) return;
    _beatLayerEnabled = true;
    _scheduleBeat();
  }

  void _scheduleBeat() {
    _playBeat();
    final duration = (_baseBeatDurationMs / _tempo).round();
    _beatTimer = Timer(Duration(milliseconds: duration), () {
      _currentBeatIndex = (_currentBeatIndex + 1) % _beatPattern.length;
      _scheduleBeat();
    });
  }

  void _playBeat() {
    if (_sfId == null) return;
    final note = _beatPattern[_currentBeatIndex];
    _midiPro.playNote(sfId: _sfId!, channel: 9, key: note, velocity: 100);
    // Stop the percussion note after a short duration to ensure a clean hit
    Timer(const Duration(milliseconds: 100), () {
      _midiPro.stopNote(sfId: _sfId!, channel: 9, key: note);
    });
  }

  /// Stops all playback.
  void stop() {
    _chordTimer?.cancel();
    _beatTimer?.cancel();
    if (_isInitialized) _stopCurrentChord();
  }

  /// Stops playback and releases resources.
  void dispose() {
    stop();
    _isInitialized = false;
  }
}