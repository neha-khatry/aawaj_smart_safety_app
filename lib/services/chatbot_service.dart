// lib/services/chatbot_service.dart
// =====================================
// HTTP service layer for Aawaj mental health chatbot.
// Handles all API communication with the Django backend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';


// ── Models ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String role;       // 'user' | 'bot'
  final String content;
  final String? intent;
  final double? confidence;
  final bool isCrisis;
  final DateTime timestamp;
  final BreathingExercise? exercise;

  ChatMessage({
    required this.role,
    required this.content,
    this.intent,
    this.confidence,
    this.isCrisis = false,
    DateTime? timestamp,
    this.exercise,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isBot  => role == 'bot';
}

class BreathingExercise {
  final String name;
  final String description;
  final List<String> steps;

  BreathingExercise({
    required this.name,
    required this.description,
    required this.steps,
  });

  factory BreathingExercise.fromJson(Map<String, dynamic> json) {
    return BreathingExercise(
      name:        json['name'] ?? '',
      description: json['description'] ?? '',
      steps:       List<String>.from(json['steps'] ?? []),
    );
  }
}

class ChatResponse {
  final int sessionId;
  final String intent;
  final double confidence;
  final String message;
  final bool isCrisis;
  final BreathingExercise? exercise;
  final DateTime timestamp;

  ChatResponse({
    required this.sessionId,
    required this.intent,
    required this.confidence,
    required this.message,
    required this.isCrisis,
    this.exercise,
    required this.timestamp,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      sessionId:  json['session_id'] ?? 0,
      intent:     json['intent'] ?? 'fallback',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      message:    json['message'] ?? '',
      isCrisis:   json['is_crisis'] ?? false,
      exercise:   json['exercise'] != null
          ? BreathingExercise.fromJson(json['exercise'])
          : null,
      timestamp:  json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ── Service ──────────────────────────────────────────────────────────────

class ChatbotService {
  ///static const String _baseUrl = 'http://192.168.1.71:8000/api/v1/chatbot';
  // for running on chrome
  // static const String _baseUrl = 'http://127.0.0.1:8000/api/v1/chatbot';
  // For physical device on same network: 'http://192.168.1.x:8000/api/v1/chatbot'

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  ChatbotService({http.Client? client}) : _client = client ?? http.Client();

  // ── Start new session ────────────────────────────────────────────────
  Future<ChatResponse?> startSession(String deviceId) async {
    try {
      final response = await _client
          .post(
        Uri.parse('${Constants.baseUrl}/v1/chatbot/session/new/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}),
      )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      }
    } catch (e) {
      print('[ChatbotService] startSession error: $e');
    }
    return null;
  }

  // ── Send message ─────────────────────────────────────────────────────
  Future<ChatResponse?> sendMessage({
    required String deviceId,
    required String message,
    int? sessionId,
  }) async {
    try {
      final body = {
        'device_id': deviceId,
        'message':   message,
        if (sessionId != null) 'session_id': sessionId,
      };

      final response = await _client
          .post(
        Uri.parse('${Constants.baseUrl}/v1/chatbot/message/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      }
    } catch (e) {
      print('[ChatbotService] sendMessage error: $e');
    }
    return null;
  }

  // ── Health check ─────────────────────────────────────────────────────
  Future<bool> isHealthy() async {
    try {
      final response = await _client
          .get(Uri.parse('${Constants.baseUrl}/v1/chatbot/health/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}