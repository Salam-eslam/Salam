// lib/services/audio_player_service.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _isManualStop = false; // Flag to track manual stops

  late StreamSubscription _completeSubscription;
  late StreamSubscription _stateSubscription;

  AudioPlayerService() {
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!_isDisposed && !_isManualStop) {
        // Only emit completion event if it's a natural completion, not a manual stop
        _isPlaying = false;
        _onCompleteController.add(null);
        notifyListeners();
      }
      // Reset the flag after handling
      _isManualStop = false;
    });

    _stateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!_isDisposed) {
        _isPlaying = state == PlayerState.playing;
        notifyListeners();
      }
    });
  }

  final StreamController<void> _onCompleteController =
      StreamController<void>.broadcast();
  Stream<void> get onComplete => _onCompleteController.stream;

  Future<void> play(String url) async {
    if (_isDisposed) return;

    try {
      // Set flag before playing to prevent onComplete from firing when stopping previous audio
      _isManualStop = true;
      await _audioPlayer.play(UrlSource(url));
      if (!_isDisposed) {
        _isPlaying = true;
        // Reset flag after successful play - this audio should complete naturally
        _isManualStop = false;
        notifyListeners();
      }
    } catch (e) {
      // Handle play failure
      _isManualStop = false; // Reset flag on error
      if (!_isDisposed) {
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    if (_isDisposed) return;

    _isManualStop = true; // Set flag when manually stopping
    await _audioPlayer.stop();
    if (!_isDisposed) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  bool get isPlaying => _isPlaying;

  @override
  void dispose() {
    _isDisposed = true;
    _completeSubscription.cancel();
    _stateSubscription.cancel();
    _onCompleteController.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
