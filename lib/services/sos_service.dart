import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_service.dart';

class SOSService {
  final String baseUrl;

  SOSService({required this.baseUrl});

  Future<bool> triggerSOS() async {
    try {
      // Get unique device ID
      String deviceId = await DeviceService.getDeviceId();

      final response = await http.post(
        Uri.parse('$baseUrl/trigger_sos/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"device_id": deviceId}),
      );

      if (response.statusCode == 200) {
        print('SOS sent successfully');
        return true;
      } else {
        print('Failed to send SOS: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SOS: $e');
      return false;
    }
  }
}
