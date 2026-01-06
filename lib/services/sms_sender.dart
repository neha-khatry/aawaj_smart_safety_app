import 'package:url_launcher/url_launcher.dart';

class SmsSender {
  static Future<void> openSmsComposer({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
    await launchUrl(uri);
  }
}