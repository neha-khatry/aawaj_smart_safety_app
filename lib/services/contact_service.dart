import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_service.dart';

class ContactService {
  static const String baseUrl = 'http://192.168.121.109:8000/api';

  /// SAVE CONTACT
  static Future<bool> saveContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    final deviceId = await DeviceService.getDeviceId();

    final response = await http.post(
      Uri.parse('$baseUrl/save_contact/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'name': name,
        'phone_number': phone,
        'relation': relation,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  /// GET CONTACTS
  static Future<List<dynamic>> getContacts() async {
    final deviceId = await DeviceService.getDeviceId();

    final response = await http.post(
      Uri.parse('$baseUrl/get_contacts/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  static Future<bool> deleteContact({
    required String contactId,
  }) async {
    final deviceId = await DeviceService.getDeviceId();

    final url = Uri.parse(
      '$baseUrl/contacts/delete/$contactId/?device_id=$deviceId',
    );

    final response = await http.delete(url);

    return response.statusCode == 200;
  }
}
