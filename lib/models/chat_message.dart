class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatBotResponses {
  static const Map<String, String> responses = {
    'anxious': "I understand you're feeling anxious right now. That's completely valid. Would you like to try a quick breathing exercise? Breathe in for 4 seconds, hold for 4, and exhale for 4. You're stronger than you know. 💜",
    'scared': "I'm so sorry you're feeling scared. Your safety is the most important thing. If you're in immediate danger, please use the SOS button. If you need to talk, I'm here. You're brave for reaching out. 💜",
    'talk': "I'm here to listen. You can share anything with me - your feelings, your worries, or just vent. This is a safe space, and everything stays between us. What's on your mind? 💜",
    'safe': "Feeling safe is so important. Let's make sure you have everything set up - emergency contacts, location sharing, and voice triggers. Remember, you have the power to protect yourself. You are not alone. 💜",
    'help': "I'm here to help you. You can tell me how you're feeling, ask about safety features, or just chat. If you're in danger, please use the SOS button immediately. What do you need right now? 💜",
    'sad': "I'm sorry you're feeling sad. It's okay to feel this way, and your emotions are valid. Remember that tough times don't last forever. Would you like to talk about what's bothering you? I'm here for you. 💜",
    'angry': "It's completely understandable to feel angry. Your feelings are valid. Take a deep breath and know that you're in a safe space here. Would you like to talk about what's making you feel this way? 💜",
    'lonely': "Feeling lonely can be really hard. I want you to know that you're not alone - I'm here with you right now. Your feelings matter, and reaching out takes courage. How can I support you today? 💜",
    'stressed': "Stress can feel overwhelming, but you're taking a good step by talking about it. Let's try to break things down together. What's the biggest thing on your mind right now? 💜",
    'panic': "If you're having a panic attack, try to focus on your breathing. Breathe in slowly for 4 counts, hold for 4, and exhale for 4. You are safe. This feeling will pass. I'm right here with you. 💜",
  };

  static const String defaultResponse =
      "Thank you for sharing that with me. Your feelings are valid, and I'm here for you. Remember, you're not alone in this journey. Is there something specific you'd like to talk about or any way I can support you? 💜";

  static String getResponse(String message) {
    final lowerMessage = message.toLowerCase();
    for (final entry in responses.entries) {
      if (lowerMessage.contains(entry.key)) {
        return entry.value;
      }
    }
    return defaultResponse;
  }
}
