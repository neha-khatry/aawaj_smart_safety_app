import 'package:flutter/services.dart';

class SosVolumeListener {
  static const MethodChannel _channel = MethodChannel('sos_volume_channel');

  /// Initialize the listener
  /// [onTrigger] will be called when volume button SOS pattern is detected
  static void initialize(Function onTrigger) {
    print("📢 SosVolumeListener initialized");

    _channel.setMethodCallHandler((call) async {
      print("📩 MethodChannel call received: ${call.method}");
      if (call.method == "SOS_TRIGGERED") {
        print("🚨 SOS_TRIGGERED received from Android");
        try {
          await onTrigger();
          print("✅ onTrigger executed successfully");
        } catch (e) {
          print("❌ Error executing onTrigger: $e");
        }
      }
    });
  }
}
