import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL of your Django backend.
/// Android emulator uses 10.0.2.2 to reach your PC (localhost).
const String _baseUrl = 'http://10.0.2.2:8000/api/v1/checkin';

class CheckInApi {
  final String accessToken;

  CheckInApi(this.accessToken);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  /// Schedule a new check-in at [scheduledAt].
  Future<bool> schedule(DateTime scheduledAt) async {
    final url = Uri.parse('$_baseUrl/schedule/');
    final body = {
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    };

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// Confirm a check-in as safe or not safe.
  Future<bool> confirm(
      String checkInId, {
        required bool isSafe,
        String? mood,
        String? message,
      }) async {
    final url = Uri.parse('$_baseUrl/confirm/$checkInId/');
    final body = {
      'is_safe': isSafe,
      if (mood != null) 'mood': mood,
      if (message != null) 'message': message,
    };

    final res = await http.put(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    return res.statusCode == 200;
  }

  /// Get list of pending check-ins.
  Future<List<dynamic>> getPending() async {
    final url = Uri.parse('$_baseUrl/pending/');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);

    // Our backend returns: { success: true, checkins: [...] }
    if (data is Map && data['checkins'] is List) {
      return data['checkins'] as List;
    }

    // fallback: if backend returns a list directly
    if (data is List) return data;

    return [];
  }

  /// Cancel a pending check-in
  Future<bool> cancel(String checkInId) async {
    final url = Uri.parse('$_baseUrl/cancel/$checkInId/');
    final res = await http.delete(url, headers: _headers);
    return res.statusCode == 200;
  }
}