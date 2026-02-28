import 'dart:async';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';

enum MidiLayer {
  harmony,
  beat,
}

class MidiLoopController {
  MidiLoopController._();

  static final MidiLoopController instance = MidiLoopController._();

  final MidiPro _midiPro = MidiPro();

  int? _soundFontId;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _tempoMultiplier = 1.0;
  final Set<MidiLayer> _activeLayers = <MidiLayer>{MidiLayer.harmony};

  Timer? _scheduler;
  final List<_ChordStep> _progression = const <_ChordStep>[
    _ChordStep(notes: <int>[60, 64, 67], beats: 4), // C major
    _ChordStep(notes: <int>[57, 60, 64], beats: 4), // A minor
    _ChordStep(notes: <int>[53, 57, 60], beats: 4), // F major
    _ChordStep(notes: <int>[55, 59, 62], beats: 4), // G major
  ];

  Duration get _beatDuration {
    const double baseBpm = 90;
    final double bpm = baseBpm * _tempoMultiplier;
    final int msPerBeat = (60000 / bpm).round();
    return Duration(milliseconds: msPerBeat);
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _soundFontId = await _midiPro.loadSoundfontAsset(
      assetPath: 'assets/weedsgm3.sf2',
      bank: 0,
      program: 0,
    );

    final int soundFontId = _soundFontId!;

    await _midiPro.selectInstrument(
      sfId: soundFontId,
      channel: 0,
      bank: 0,
      program: 0,
    );

    await _midiPro.selectInstrument(
      sfId: soundFontId,
      channel: 9,
      bank: 128,
      program: 0,
    );

    _isInitialized = true;
  }

  Future<void> startLoop() async {
    await initialize();

    if (_isPlaying) {
      return;
    }

    _isPlaying = true;
    _runLoop();
  }

  Future<void> stopLoop() async {
    _isPlaying = false;
    _scheduler?.cancel();
    _scheduler = null;
  }

  Future<void> setTempoMultiplier(double multiplier) async {
    _tempoMultiplier = multiplier.clamp(0.5, 3.0);

    if (_isPlaying) {
      _scheduler?.cancel();
      _runLoop();
    }
  }

  Future<void> setLayerEnabled(MidiLayer layer, bool enabled) async {
    if (enabled) {
      _activeLayers.add(layer);
    } else {
      _activeLayers.remove(layer);
    }
  }

  Future<void> applyProximity(double normalizedProximity) async {
    final double value = normalizedProximity.clamp(0.0, 1.0);

    await setTempoMultiplier(1 + value);
    await setLayerEnabled(MidiLayer.beat, value > 0.55);
  }

  void _runLoop() {
    int stepIndex = 0;

    void scheduleStep() {
      if (!_isPlaying || _soundFontId == null) {
        return;
      }

      final _ChordStep step = _progression[stepIndex];
      _playChord(step.notes, step.beats);

      final Duration nextStepIn = Duration(
        milliseconds: _beatDuration.inMilliseconds * step.beats,
      );

      stepIndex = (stepIndex + 1) % _progression.length;
      _scheduler = Timer(nextStepIn, scheduleStep);
    }

    scheduleStep();
  }

  void _playChord(List<int> notes, int beats) {
    final int soundFontId = _soundFontId!;
    final Duration beatLength = _beatDuration;
    final Duration chordLength = Duration(
      milliseconds: beatLength.inMilliseconds * beats,
    );

    if (_activeLayers.contains(MidiLayer.harmony)) {
      for (final int note in notes) {
        _midiPro.playNote(
          sfId: soundFontId,
          channel: 0,
          key: note,
          velocity: 95,
        );

        Timer(chordLength, () {
          _midiPro.stopNote(
            sfId: soundFontId,
            channel: 0,
            key: note,
          );
        });
      }
    }

    if (_activeLayers.contains(MidiLayer.beat)) {
      for (int beat = 0; beat < beats; beat++) {
        final Duration offset = Duration(
          milliseconds: beatLength.inMilliseconds * beat,
        );
        Timer(offset, () {
          _midiPro.playNote(
            sfId: soundFontId,
            channel: 9,
            key: 36,
            velocity: 100,
          );
          Timer(const Duration(milliseconds: 120), () {
            _midiPro.stopNote(
              sfId: soundFontId,
              channel: 9,
              key: 36,
            );
          });
        });
      }
    }
  }
}

class _ChordStep {
  const _ChordStep({required this.notes, required this.beats});

  final List<int> notes;
  final int beats;
}
