import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
class EmergencyApi {
  ///static const String _baseUrl = "http://192.168.121.109:8000/api/v1/emergency";

  final String accessToken;
  EmergencyApi(this.accessToken);

  Future<Map<String, dynamic>?> triggerSOS({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse("${Constants.baseUrl}/v1/emergency/sos/");
    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}