import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static Future<String> createSession() async {
    final res = await http.post(
      Uri.parse("${Constants.baseUrl}/create/"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['token'];
    } else {
      throw Exception("Failed to create session");
    }
  }

  static Future<void> sendLocation(
      String token, double lat, double lon) async {
    await http.post(
      Uri.parse("${Constants.baseUrl}/update/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token,
        "latitude": lat,
        "longitude": lon,
      }),
    );
  }
}