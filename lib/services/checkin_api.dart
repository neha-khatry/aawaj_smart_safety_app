import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Base URL of your backend

///const String _baseUrl = 'http://192.168.1.71:8000/api/v1/checkin';

class CheckInApi {
  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  CheckInApi();

  /// Schedule a check-in
  Future<bool> schedule(DateTime scheduledAt) async {
    final url = Uri.parse('${Constants.baseUrl}/v1/checkin/schedule/');
    final body = {'scheduled_at': scheduledAt.toUtc().toIso8601String()};
    final res = await http.post(url, headers: _headers, body: jsonEncode(body));
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// Confirm a check-in as safe/not safe
  Future<bool> confirm(String checkInId, {required bool isSafe, required String scheduledAt,}) async {
    final url = Uri.parse('${Constants.baseUrl}/v1/checkin/confirm/$checkInId/');
    final body = {'scheduled_at': scheduledAt,'is_safe': isSafe};
    final res = await http.put(url, headers: _headers, body: jsonEncode(body));
    return res.statusCode == 200;
  }

  /// Get pending check-ins
  Future<List<Map<String, dynamic>>> getPending() async {
    final url = Uri.parse('${Constants.baseUrl}/v1/checkin/pending/');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is Map && data['checkins'] is List) {
      return List<Map<String, dynamic>>.from(data['checkins']);
    } else if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Cancel a check-in
  Future<bool> cancel(String checkInId) async {
    final url = Uri.parse('${Constants.baseUrl}/v1/checkin/cancel/$checkInId/');
    final res = await http.delete(url, headers: _headers);
    return res.statusCode == 200;
  }
}