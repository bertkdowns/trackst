import 'package:audioplayers/audioplayers.dart';

/// Ordered list of asset paths for each intensity layer.
///
/// Layer 0 is always audible; subsequent layers are faded in as the player
/// gets closer to the target.  All files MUST be the same duration and loop
/// seamlessly so that every layer stays in sync.
///
/// To add a new intensity level:
///   1. Place the audio file in the `assets/` folder.
///   2. Declare it in `pubspec.yaml` under `flutter › assets`.
///   3. Append its asset path here.
const List<String> layerAssets = [
  'layer_0.mp3', // base layer – audible when intensity level ≥ 1
  'layer_1.mp3', // added at medium proximity (intensity level ≥ 2)
  'layer_2.mp3', // added at close proximity  (intensity level ≥ 3)
];

/// Manages multiple looping audio layers that play simultaneously.
///
/// All layers start playing immediately (looped) but at zero volume.  Calling
/// [setIntensityLevel] raises the volume of the layers that should currently
/// be audible and silences the rest, keeping every layer in perfect sync
/// because they are always running.
///
/// Volume of individual layers can also be adjusted at any time with
/// [setLayerVolume] – useful for smooth fade-in/out effects.
class AudioLayerPlayer {
  late final List<AudioPlayer> _players;
  bool _isInitialized = false;

  AudioLayerPlayer() {
    _players = List.generate(layerAssets.length, (_) => AudioPlayer());
  }

  /// Prepares all audio players and starts them looping at volume 0.
  ///
  /// Call this once before using [setIntensityLevel].
  Future<void> initialize() async {
    for (int i = 0; i < _players.length; i++) {
      final player = _players[i];
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.0);
      await player.play(AssetSource(layerAssets[i]));
    }
    _isInitialized = true;
  }

  /// Makes layers 0 through [level]-1 audible (volume 1.0) and silences the
  /// rest (volume 0.0).  For example, level 1 turns on only layer 0; level 3
  /// turns on layers 0, 1, and 2.
  ///
  /// [level] is clamped to [0, layerAssets.length].  Passing 0 silences
  /// every layer (but they keep looping so they remain in sync).
  void setIntensityLevel(int level) {
    if (!_isInitialized) return;
    final target = level.clamp(0, layerAssets.length);
    for (int i = 0; i < _players.length; i++) {
      _players[i].setVolume(i < target ? 1.0 : 0.0);
    }
  }

  /// Sets the volume of a single layer to [volume] (0.0–1.0).
  ///
  /// Useful for implementing gradual fade-in/out effects on individual layers
  /// without affecting others.
  void setLayerVolume(int layerIndex, double volume) {
    if (!_isInitialized) return;
    if (layerIndex < 0 || layerIndex >= _players.length) return;
    _players[layerIndex].setVolume(volume.clamp(0.0, 1.0));
  }

  /// Pauses all layers.
  Future<void> pause() async {
    for (final player in _players) {
      await player.pause();
    }
  }

  /// Resumes all layers simultaneously.
  Future<void> resume() async {
    for (final player in _players) {
      await player.resume();
    }
  }

  /// Stops all layers and releases audio resources.
  Future<void> dispose() async {
    for (final player in _players) {
      await player.dispose();
    }
    _isInitialized = false;
  }
}
