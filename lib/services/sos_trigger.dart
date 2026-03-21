import 'sos_sms_service.dart';
import 'contact_service.dart';
import 'location_service.dart';


class SosTrigger {
  static Future<void> triggerSOS() async {
    print("📌 SOS callback triggered in Flutter");

    // 🔴 STEP 1: Get location
    final position = await LocationService.getCurrentLocation();

    double lat = position.latitude;
    double lon = position.longitude;

    // 🔴 STEP 2: Generate map link
    String mapLink = "https://www.google.com/maps?q=$lat,$lon";

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
        "🚨 SOS ALERT! I am in danger! Please contact me immediately.📍 My Location:https://www.google.com/maps?q=$lat,$lon";

    // 4️⃣ Send SMS
    await SosSmsService.sendAlert(
      contacts: phoneNumbers,
      message: message,
    );

    print("✅ SOS messages sent to ${phoneNumbers.length} contacts");
  }
}
