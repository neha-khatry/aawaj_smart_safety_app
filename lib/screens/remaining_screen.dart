import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';
import '../widgets/glass_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// ==================== LOCATION SCREEN ====================
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
  }

  Future<void> _fetchLiveLocation() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateLocation(
        provider.latitude ?? 0,
        provider.longitude ?? 0,
        'Fetching location...'
    );
    await provider.fetchLiveLocation();
  }

  void _shareLocation() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final lat = provider.latitude;
    final lng = provider.longitude;

    if (lat != null && lng != null) {
      final locationUrl = 'https://maps.google.com/?q=$lat,$lng';
      for (var contact in provider.contacts) {
        // Placeholder: open SMS link via URL launcher (works for Android/iOS)
        launchUrl(Uri.parse('sms:${contact.phone}?body=Emergency! My location: $locationUrl'));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location shared with ${provider.contacts.length} contact(s)'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available yet'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Location',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Map Placeholder
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900.withOpacity(0.5),
                          Colors.purple.shade900.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            child: Icon(Icons.location_on,
                                size: 40, color: Colors.blue[400]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.locationStatus,
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                          if (provider.latitude != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${provider.latitude?.toStringAsFixed(4)}, ${provider.longitude?.toStringAsFixed(4)}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Share Location Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.share),
                    label: const Text('Share with All Contacts'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF3b82f6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tracking Options
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tracking Options',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildToggleRow(
                        'Live tracking',
                        provider.liveTracking,
                            (_) => provider.toggleLiveTracking(),
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        'Offline SMS fallback',
                        provider.smsAlerts,
                            (_) => provider.toggleSmsAlerts(),
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
      String label, bool value, Function(bool) onChanged, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[300])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }
}

// ==================== CHAT SCREEN ====================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      id: '1',
      message:
      "Hello! I'm here to support you. You're not alone, and your feelings are valid. How are you feeling today? 💜",
      isUser: false,
    ));
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: text,
        isUser: true,
      ));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: ChatBotResponses.getResponse(text),
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                        ),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                          ),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aawaj Support',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green[400],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Always here for you',
                                style: TextStyle(
                                    color: Colors.green[400], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Quick Responses
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildQuickResponse('I need someone to talk to'),
                    _buildQuickResponse("I'm feeling anxious"),
                    _buildQuickResponse('I want to feel safe'),
                  ],
                ),
              ),

              // Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(_controller.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                ),
              ),
              child:
              const Icon(Icons.favorite, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                    colors: [Color(0xFFec4899), Color(0xFF8b5cf6)])
                    : null,
                color: message.isUser ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
            ),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 600 + (index * 200)),
                builder: (context, value, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickResponse(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _sendMessage(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}

// ==================== CONTACTS SCREEN ====================
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  void _addContact() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in name and phone number'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.addContact(EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phone: _phoneController.text,
      relation: _relationController.text,
    ));

    _nameController.clear();
    _phoneController.clear();
    _relationController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact added successfully'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trusted Contacts',
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Add Contact Form
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Emergency Contact',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Contact Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _relationController,
                        decoration: const InputDecoration(
                          hintText: 'Relationship (e.g., Sister, Friend)',
                          prefixIcon: Icon(Icons.people),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addContact,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contacts List
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Emergency Contacts',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      if (provider.contacts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No contacts added yet',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        )
                      else
                        ...provider.contacts.map((contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFec4899),
                                        Color(0xFF8b5cf6)
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      contact.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        contact.phone,
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12),
                                      ),
                                      if (contact.relation.isNotEmpty)
                                        Text(
                                          contact.relation,
                                          style: TextStyle(
                                              color: Colors.pink[400],
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      provider.removeContact(contact.id),
                                  icon: Icon(Icons.delete,
                                      color: Colors.red[400]),
                                ),
                              ],
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final nameController = TextEditingController(text: provider.userName);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text('Settings',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                // Profile
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration:
                        const InputDecoration(hintText: 'Your Name'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            provider.setUserName(nameController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Name updated'),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.withOpacity(0.3),
                          ),
                          child:
                          Text('Save', style: TextStyle(color: Colors.pink[400])),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Triggers
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency Triggers',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildSettingToggle(
                        'Voice Activation',
                        'Say "Help me Aawaj"',
                        provider.voiceActivation,
                            (_) => provider.toggleVoiceActivation(),
                      ),
                      _buildSettingToggle(
                        'Shake Detection',
                        'Shake phone 3 times',
                        provider.shakeDetection,
                            (_) => provider.toggleShakeDetection(),
                      ),
                      _buildSettingToggle(
                        'Power Button',
                        'Press 5 times quickly',
                        provider.powerButton,
                            (_) => provider.togglePowerButton(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Disguise Mode
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disguise Mode',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildSettingToggle(
                        'Enable Disguise',
                        'App appears as calculator',
                        provider.disguiseMode,
                            (_) => provider.toggleDisguiseMode(),
                      ),
                      Text(
                        'Secret exit code: Press "=" 5 times',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Offline Safety
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Offline Safety',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildSettingToggle(
                        'SMS Alerts',
                        'Send SMS when offline',
                        provider.smsAlerts,
                            (_) => provider.toggleSmsAlerts(),
                        activeColor: Colors.green,
                      ),
                      _buildSettingToggle(
                        'Offline Recording',
                        'Save locally when offline',
                        provider.offlineRecording,
                            (_) => provider.toggleOfflineRecording(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingToggle(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged, {
        Color activeColor = const Color(0xFFec4899),
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}

// ==================== RECORD SCREEN ====================
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _isRecording = false;
  String _recordingType = '';
  int _seconds = 0;
  Timer? _timer;

  void _startRecording(String type) {
    setState(() {
      _isRecording = true;
      _recordingType = type;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type recording started'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recording saved'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _formattedTime {
    final hours = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text('Silent Recording',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                // Recording Status
                GlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? Colors.red.withOpacity(0.2)
                              : Colors.red.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.videocam,
                          size: 40,
                          color:
                          _isRecording ? Colors.red : Colors.red.shade300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording
                            ? 'Recording $_recordingType...'
                            : 'Ready to Record',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formattedTime,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recording Buttons
                if (!_isRecording)
                  Row(
                    children: [
                      Expanded(
                        child: _buildRecordButton(
                          Icons.mic,
                          'Audio Only',
                          'Silent capture',
                          Colors.purple,
                              () => _startRecording('Audio'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRecordButton(
                          Icons.videocam,
                          'Video + Audio',
                          'Evidence capture',
                          Colors.red,
                              () => _startRecording('Video'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==================== DISGUISE SCREEN (Calculator) ====================
class DisguiseScreen extends StatefulWidget {
  const DisguiseScreen({super.key});

  @override
  State<DisguiseScreen> createState() => _DisguiseScreenState();
}

class _DisguiseScreenState extends State<DisguiseScreen> {
  String _display = '0';
  int _equalsCount = 0;
  DateTime? _lastEqualsTime;

  void _onButtonPressed(String value) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (value == '=') {
      final now = DateTime.now();
      if (_lastEqualsTime != null &&
          now.difference(_lastEqualsTime!).inMilliseconds < 500) {
        _equalsCount++;
        if (_equalsCount >= 5) {
          provider.toggleDisguiseMode();
          _equalsCount = 0;
          return;
        }
      } else {
        _equalsCount = 1;
      }
      _lastEqualsTime = now;

      // Calculate result
      try {
        // Simple calculation logic
        setState(() {
          _display = _evaluateExpression(_display);
        });
      } catch (e) {
        setState(() {
          _display = 'Error';
        });
      }
    } else if (value == 'C') {
      setState(() {
        _display = '0';
      });
    } else if (value == '±') {
      setState(() {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      });
    } else if (value == '%') {
      setState(() {
        _display = (double.tryParse(_display) ?? 0 / 100).toString();
      });
    } else {
      setState(() {
        if (_display == '0' && value != '.') {
          _display = value;
        } else {
          _display += value;
        }
      });
    }
  }

  String _evaluateExpression(String expr) {
    // Simple evaluation - in real app use a proper expression parser
    try {
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
      // This is a simplified version - would need proper parsing in production
      return expr;
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              ..._buildButtonRows(),
              const SizedBox(height: 16),
              Text(
                'Tap "=" 5 times quickly to exit',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtonRows() {
    final buttons = [
      ['C', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '0', '.', '='],
    ];

    return buttons.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: row.asMap().entries.map((entry) {
            final index = entry.key;
            final btn = entry.value;
            final isOperator = ['÷', '×', '−', '+', '='].contains(btn);
            final isZero = btn == '0' && index == 0 && row[1] == '0';

            return Expanded(
              flex: isZero ? 2 : 1,
              child: Padding(
                padding: EdgeInsets.only(right: index < row.length - 1 ? 12 : 0),
                child: isZero && index == 1
                    ? const SizedBox()
                    : _buildButton(btn, isOperator),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildButton(String text, bool isOperator) {
    return GestureDetector(
      onTap: () => _onButtonPressed(text),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isOperator ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
