import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class SosTestListener {
  static const MethodChannel _channel =
  MethodChannel('sos_volume_channel');

  static void init(BuildContext context) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'SOS_TRIGGERED') {
        debugPrint("🚨 SOS TRIGGERED (VOLUME BUTTON)");

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("SOS Triggered"),
            content: const Text(
              "Volume button pattern detected successfully!",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    });
  }
}
