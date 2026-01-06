import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'scream_listener_service.dart';

/// Handles continuous voice & scream detection while the app is open
class SOSMonitorTask {
  late stt.SpeechToText _speech;
  bool _isListening = false; // Tracks if voice loop is active
  final ScreamListenerService _screamService = ScreamListenerService();

  /// Callback invoked when SOS is detected (via scream or voice phrase)
  void Function()? onSOSDetected;

  bool isActive = false; // Whether monitoring is currently active

  /// Initialize services (do not start recording yet)
  Future<void> init() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize();
    if (!available) {
      debugPrint("Speech recognition unavailable!");
      return;
    }

    await _screamService.init();

    // Setup scream detection callback
    _screamService.onScreamDetected = () {
      debugPrint("SOS triggered by scream!");
      _triggerSOS();
    };
  }

  /// Start monitoring both voice phrase & scream detection
  void start() {
    if (isActive) return; // Already active
    isActive = true;

    // Start scream detection
    _screamService.startListening();

    // Start voice phrase detection loop
    _startVoiceLoop();
  }

  /// Stop monitoring
  void stop() {
    if (!isActive) return; // Already stopped
    isActive = false;

    _screamService.stopListening();

    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  /// Voice recognition loop (continuous while active)
  void _startVoiceLoop() {
    if (!isActive || _isListening) return;

    _isListening = true;

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains("help me aawaj")) {
          debugPrint("SOS triggered by voice phrase!");
          _triggerSOS();
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 1),
      partialResults: true,
      localeId: 'en_US',
    );

    // Automatically restart listening when done
    _speech.statusListener = (status) {
      if (status == "done" && isActive) {
        _isListening = false;
        _startVoiceLoop();
      }
    };
  }

  /// Internal method to trigger SOS callback
  void _triggerSOS() {
    debugPrint("SOS TRIGGERED!");
    onSOSDetected?.call();
  }

  /// Dispose services safely
  void dispose() {
    stop();
    _screamService.dispose();
  }
}
