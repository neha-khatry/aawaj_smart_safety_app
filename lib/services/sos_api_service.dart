import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_service.dart';
import 'package:flutter/foundation.dart';
class SosApiService {
  static Future<void> saveAudioMetadata(String localPath) async {
    final String deviceId = await DeviceService.getDeviceId(); // ✅ HERE

    final response = await http.post(
      Uri.parse('http://192.168.121.109:8000/api/save_audio/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'local_path': localPath,
        ///'created_at': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      debugPrint("✅ Audio metadata saved");
    } else {
      debugPrint("❌ Failed to save audio metadata");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.body}");
    }
  }
}
