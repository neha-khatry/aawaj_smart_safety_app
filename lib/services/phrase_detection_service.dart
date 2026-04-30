// lib/services/phrase_detection_service.dart
// =============================================
// Aawaj Phrase Detection Service
//
// Architecture:
//   1. Flutter speech_to_text → transcribes mic input continuously
//   2. On-device keyword check (instant, no internet)
//   3. Django ML API (fallback, richer classification)
//   4. SOS trigger if emergency detected
//
// The service runs in background, listens for speech, and fires
// a callback when an emergency phrase is detected.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_error.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import'../utils/constants.dart';

// ── Emergency keywords (on-device fallback — no internet needed) ─────────
const List<String> _emergencyKeywordsEn = [
  "help me", "help please", "somebody help", "help help",
  "i need help", "emergency", "call the police", "call police",
  "i am in danger", "danger", "i am being attacked", "let me go",
  "stop stop", "save me", "i am trapped", "i am hurt",
  "he is hurting me", "she is hurting me", "they are hurting me",
  "please help", "call 100", "call ambulance", "i am being abused",
  "help me escape", "i am being followed", "i am being harassed",
  "please save me", "leave me alone",
];

const List<String> _emergencyKeywordsNp = [
  "bachau", "bachau malaai", "madad", "madad gara",
  "madad chaincha", "koi madad gara", "help gara", "help garnus",
  "khatara chha", "khatara khatara", "malaai chhad", "police bolau",
  "police lai phone gara", "aafat pariyo", "malaai bachau",
  "bachau mero jaan", "mero jaan khatara", "chhad malaai",
  "nacha nai", "koi aau", "koi bolau", "bachao"
];

final List<String> allEmergencyKeywords = [
  ..._emergencyKeywordsEn,
  ..._emergencyKeywordsNp,
];

// ── Models ───────────────────────────────────────────────────────────────

class PhraseDetectionResult {
  final bool isEmergency;
  final double confidence;
  final String text;
  final String method;        // "on_device" | "api_ml" | "api_keyword"
  final String? matchedKeyword;
  final DateTime timestamp;

  PhraseDetectionResult({
    required this.isEmergency,
    required this.confidence,
    required this.text,
    required this.method,
    this.matchedKeyword,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ── Service ───────────────────────────────────────────────────────────────

class PhraseDetectionService extends ChangeNotifier {
// Change to your Django server IP
//static const String _baseUrl = 'http://10.0.2.2:8000/api/v1/phrase';
  static const String _baseUrl = '${Constants.baseUrl}/v1/phrase';

  static const Duration _timeout = Duration(seconds: 8);
  static const Duration _restartDelay = Duration(seconds: 2);

// Listening config
  static const int _listenDurationSec  = 10;  // listen window per cycle
  static const double _minConfidence   = 0.70; // speech confidence threshold
  static const double _emergencyConfidence = 0.60; // ML confidence threshold

  final stt.SpeechToText _speech = stt.SpeechToText();
  final http.Client _client = http.Client();

  bool _isInitialized   = false;
  bool _isListening     = false;
  bool _isActive        = false;  // user toggled on/off
  bool _isProcessing    = false;

  String _currentText   = '';
  String _statusMessage = 'Phrase detection off';
  PhraseDetectionResult? _lastResult;
  String _deviceId      = 'aawaj-device';

  Timer? _restartTimer;
  Timer? _cooldownTimer;
  bool _inCooldown      = false;  // prevent multiple triggers in quick succession

// Callbacks
  Function(PhraseDetectionResult)? onEmergencyDetected;
  Function(String)?                onStatusChanged;

// ── Getters ─────────────────────────────────────────────────────────
  bool get isActive       => _isActive;
  bool get isListening    => _isListening;
  bool get isInitialized  => _isInitialized;
  String get statusMessage => _statusMessage;
  String get currentText  => _currentText;
  PhraseDetectionResult? get lastResult => _lastResult;

// ── Init ─────────────────────────────────────────────────────────────
  Future<bool> initialize(String deviceId, {bool autoStart = false}) async {
    _deviceId = deviceId;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError:  _onSpeechError,
        debugLogging: kDebugMode,
      );
      _updateStatus(_isInitialized
          ? 'Phrase detection ready'
          : 'Microphone unavailable');
      notifyListeners();
      if (_isInitialized && autoStart) {
        await startListening();   // 🔥 starts listening automatically
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('[PhraseDetection] Init error: $e');
      _updateStatus('Microphone init failed');
      notifyListeners();
      return false;
    }
  }

// ── Start/Stop ────────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (!_isInitialized || _isActive) return;
    _isActive = true;
    _updateStatus('Listening for emergency phrases...');
    notifyListeners();
    await _startListenCycle();
  }

  Future<void> stopListening() async {
    _isActive = false;
    _restartTimer?.cancel();
    _cooldownTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    _currentText = '';
    _updateStatus('Phrase detection off');
    notifyListeners();
  }

// ── Listen Cycle ─────────────────────────────────────────────────────
  Future<void> _startListenCycle() async {
    if (!_isActive || _isListening) return;

    try {
      await _speech.listen(
        onResult:           _onSpeechResult,
        listenFor:          Duration(seconds: _listenDurationSec),
        pauseFor:           const Duration(seconds: 3),
        localeId:           'en_US',   // English + partial Nepali
        listenMode:         stt.ListenMode.dictation,
        cancelOnError:      false,
        partialResults:     true,
        onSoundLevelChange: null,
      );
      _isListening = true;
      _updateStatus('🎤 Listening...');
      notifyListeners();
    } catch (e) {
      debugPrint('[PhraseDetection] Listen error: $e');
      _scheduleRestart();
    }
  }

// ── Speech Results ────────────────────────────────────────────────────
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    _currentText = text;
    notifyListeners();

// Only process final results or high-confidence partials
    final confident = result.confidence >= _minConfidence || result.finalResult;
    if (!confident && !result.finalResult) return;

// Skip if in cooldown (already triggered recently)
    if (_inCooldown || _isProcessing) return;

    debugPrint('[PhraseDetection] Transcribed: "$text" (conf: ${result.confidence})');

// On-device check first (instant, no internet)
    final onDeviceResult = _onDeviceCheck(text);
    if (onDeviceResult != null) {
      _handleEmergency(onDeviceResult);
      return;
    }

// API check for ambiguous phrases
    if (result.finalResult) {
      _apiCheck(text);
    }
  }

// ── On-Device Keyword Check ───────────────────────────────────────────
  PhraseDetectionResult? _onDeviceCheck(String text) {
    final lower = text.toLowerCase();
    for (final kw in allEmergencyKeywords) {
      if (lower.contains(kw)) {
        return PhraseDetectionResult(
          isEmergency:    true,
          confidence:     0.95,
          text:           text,
          method:         'on_device',
          matchedKeyword: kw,
        );
      }
    }
    return null;
  }

// ── API ML Check ──────────────────────────────────────────────────────
  Future<void> _apiCheck(String text) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/detect/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': _deviceId,
          'text':      text,
          'auto_sos':  false,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = PhraseDetectionResult(
          isEmergency:    data['is_emergency'] ?? false,
          confidence:     (data['confidence'] ?? 0.0).toDouble(),
          text:           text,
          method:         'api_${data['method'] ?? 'ml'}',
          matchedKeyword: data['matched_keyword'],
        );

        if (result.isEmergency && result.confidence >= _emergencyConfidence) {
          _handleEmergency(result);
        }
      }
    } catch (e) {
      debugPrint('[PhraseDetection] API check failed: $e (on-device only)');
    } finally {
      _isProcessing = false;
    }
  }

// ── Handle Emergency ─────────────────────────────────────────────────
  void _handleEmergency(PhraseDetectionResult result) {
    if (_inCooldown) return;

    _inCooldown = true;
    _lastResult = result;

    debugPrint(
        '[PhraseDetection] 🆘 EMERGENCY DETECTED! '
            'text="${result.text}" '
            'confidence=${result.confidence} '
            'method=${result.method} '
            'keyword=${result.matchedKeyword}'
    );

    _updateStatus('🆘 Emergency phrase detected!');
    notifyListeners();

// Fire callback
    onEmergencyDetected?.call(result);

// Cooldown: prevent re-trigger for 15 seconds
    _cooldownTimer = Timer(const Duration(seconds: 15), () {
      _inCooldown = false;
      if (_isActive) {
        _updateStatus('🎤 Listening...');
        notifyListeners();
      }
    });
  }

// ── Speech Callbacks ─────────────────────────────────────────────────
  void _onSpeechStatus(String status) {
    debugPrint('[PhraseDetection] Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      if (_isActive) _scheduleRestart();
    }
  }

  void _onSpeechError(stt.SpeechRecognitionError error) {
    debugPrint('[PhraseDetection] Speech error: ${error.errorMsg}');
    _isListening = false;
    if (_isActive) _scheduleRestart();
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(_restartDelay, () {
      if (_isActive) _startListenCycle();
    });
  }

  void _updateStatus(String msg) {
    _statusMessage = msg;
    onStatusChanged?.call(msg);
  }

  @override
  void dispose() {
    stopListening();
    _restartTimer?.cancel();
    _cooldownTimer?.cancel();
    _client.close();
    super.dispose();
  }
}