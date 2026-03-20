import 'sos_sms_service.dart';
import 'contact_service.dart';
/**
class SosTrigger {
  static Future<void> triggerSOS() async {
    print("📌 SOS callback triggered in Flutter");

    final contacts = [
      "9840038509",
      ///"9864616464",
    ];

    final message =
        "🚨 SOS ALERT! I am in danger! Please contact me immediately.";

    await SosSmsService.sendAlert(contacts: contacts, message: message);
  }
}
**/
class SosTrigger {
  static Future<void> triggerSOS() async {
    print("📌 SOS callback triggered in Flutter");

    // 1️⃣ Fetch contacts from backend
    final contactsData = await ContactService.getContacts();

    if (contactsData.isEmpty) {
      print("❌ No emergency contacts found");
      return;
    }

    // 2️⃣ Extract phone numbers
    final List<String> phoneNumbers = contactsData
        .map<String>((c) => c['phone_number'].toString())
        .toList();

    // 3️⃣ SOS message
    final message =
        "🚨 SOS ALERT! I am in danger! Please contact me immediately.";

    // 4️⃣ Send SMS
    await SosSmsService.sendAlert(
      contacts: phoneNumbers,
      message: message,
    );

    print("✅ SOS messages sent to ${phoneNumbers.length} contacts");
  }
}
