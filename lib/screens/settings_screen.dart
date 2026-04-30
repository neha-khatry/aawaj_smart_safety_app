import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../services/detection_foreground_service.dart';

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
                    const Text(
                      'Settings',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ───────── PROFILE ─────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Your Name',
                          prefixIcon: Icon(Icons.person),
                        ),
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
                          child: Text(
                            'Save',
                            style: TextStyle(color: Colors.pink[400]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ───────── EMERGENCY TRIGGERS ─────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Triggers',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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

                // ───────── DISGUISE MODE ─────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Disguise Mode',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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

                // ───────── OFFLINE SAFETY ─────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offline Safety',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
                const SizedBox(height: 16),

                // ───────── 🔴 SECURITY CONTROL (NEW) ─────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Control',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // 🔴 STOP foreground detection
                            await DetectionForegroundService.stop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Protection turned OFF'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.3),
                          ),
                          child: const Text(
                            'Turn Off Protection',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
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