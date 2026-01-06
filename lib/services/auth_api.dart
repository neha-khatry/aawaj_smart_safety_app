import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1/auth';

  /// Django SimpleJWT: returns {refresh, access}
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/token/');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    return data['access'];
  }
}