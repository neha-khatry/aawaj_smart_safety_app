class ApiConfig {
  // 🔹 MAIN BASE URL (currently using your PC's IPv4)
  static const String baseUrl = _localNetworkBaseUrl;
  //static const String baseUrl = 'http://10.0.2.2:8000';
  // 🔹 Environment URLs
  //static const String _devBaseUrl = 'http://10.0.2.2:8000'; // Emulator
  static const String _localNetworkBaseUrl = 'http://192.168.1.14:8000'; // Your PC (physical device)
  //static const String _productionBaseUrl = 'https://yourdomain.com';

  // 🔹 API Endpoints
  static const String auth = '/api/v1/auth';
  static const String chatbot = '/api/v1/chatbot';
  static const String login = '$auth/token/';
  static const String register = '$auth/register/';
  static const String api = '/api';
  // 🔹 Audio / SOS metadata
  static const String saveAudio = '/api/save_audio/';

  // 🔹 Emergency endpoints
  static const String emergency = '/api/v1/emergency';
  static const String triggerSOS = '$emergency/sos/';

  // Chatbot endpoints
  static const String chatbotSession = '$chatbot/session/new/';
  static const String chatbotMessage = '$chatbot/message/';
  static const String chatbotHealth = '$chatbot/health/';


// 🔹 Contact endpoints
  static const String saveContact = '$api/save_contact/';
  static const String getContacts = '$api/get_contacts/';
  static const String deleteContact = '$api/contacts/delete/';

  // 🔹 Helper method to build full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}