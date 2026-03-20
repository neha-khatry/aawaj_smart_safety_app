import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

class SosSmsService {
  static final Telephony telephony = Telephony.instance;

  /// Request SMS permission
  static Future<bool> _requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }
    print("SMS permission: $status");
    return status.isGranted;
  }

  /// Send SOS SMS to multiple contacts
  static Future<void> sendAlert({
    required List<String> contacts,
    required String message,
  }) async {
    bool granted = await _requestSmsPermission();
    if (!granted) {
      print("❌ SMS permission denied");
      return;
    }

    for (String number in contacts) {
      try {
        await telephony.sendSms(to: number, message: message);
        print("✅ SMS sent to $number");
      } catch (e) {
        print("❌ Failed to send SMS to $number: $e");
      }
    }

    print("📌 SOS SMS sending finished");
  }
}
