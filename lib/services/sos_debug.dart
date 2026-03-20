import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';

class SosDebug {
  static const MethodChannel _channel = MethodChannel('sos_volume_channel');

  /// Call this in initState() of your main screen
  static void initialize() {
    print("📢 SosDebug initialized");
    _channel.setMethodCallHandler((call) async {
      print("📩 MethodChannel call received: ${call.method}");
      if (call.method == "SOS_TRIGGERED") {
        print("🚨 SOS_TRIGGERED received from Android");
        await _triggerSOS();
      }
    });
  }

  static Future<void> _triggerSOS() async {
    print("📌 SOS callback triggered in Flutter");

    final contacts = [
      "+977 9840038509",
      "+977 9864616464",
    ];
    final message =
        "🚨 SOS ALERT! I am in danger! Please contact me immediately.";

    // Check SMS permission
    var status = await Permission.sms.status;
    print("SMS permission status: $status");
    if (!status.isGranted) {
      status = await Permission.sms.request();
      print("SMS permission after request: $status");
      if (!status.isGranted) {
        print("❌ SMS permission denied, cannot send SOS");
        return;
      }
    }

    // Try sending SMS
    try {
      String result = await sendSMS(message: message, recipients: contacts);
      print("✅ SOS SMS sent: $result");
    } catch (e) {
      print("❌ Failed to send SOS SMS: $e");

      // Fallback: open SMS app
      try {
        await sendSMS(message: message, recipients: contacts);
        print("⚠️ Fallback SMS opened SMS app for manual send");
      } catch (e2) {
        print("❌ Fallback also failed: $e2");
      }
    }

    print("✅ SOS Triggered (end-to-end)");
  }
}
