import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../services/checkin_api.dart';
import '../services/sos_monitor_task.dart';
import 'sos_screen.dart';
import 'settings_screen.dart';
import 'record_screen.dart';
import '../services/sos_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sos_volume_listener.dart';
import '../services/sos_trigger.dart';
import 'package:another_telephony/telephony.dart';
import '../services/navigator_service.dart';
import '../services/checkin_watcher.dart';
import '../services/phrase_detection_service.dart';
import '../widgets/phrase_detection_widget.dart';
import 'package:aawaj/services/detection_foreground_service.dart';
import 'package:aawaj/services/background_detection_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sosController;
  late Animation<double> _sosAnimation;

  String _currentTime = '';
  bool _isVoiceTriggerActive = false;

  CheckinWatcher? _checkinWatcher;
  Timer? _pendingTimer;
  Timer? _clockTimer;
  String? _lastShownPendingId;

  SOSMonitorTask? _sosMonitorTask;
  final _phraseService = PhraseDetectionService();

  // ── FIX 1: _onBackgroundMessage moved to class level (was inside _updateTime) ──
  void _onBackgroundMessage(Object data) {
    if (data is Map && data['type'] == 'restart_listening') {
      if (_phraseService.isActive && !_phraseService.isListening) {
        debugPrint('[Background] Restarting speech listener...');
        _phraseService.startListening();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _requestPermissions();

    SosVolumeListener.initialize(() async {
      debugPrint('📌 SOS triggered from volume button');
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SOSScreen()),
            (route) => false,
      );
    });

    _sosController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _sosAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );

    _updateTime();

    // ── FIX 2: clock timer stored so it can be cancelled in dispose ──
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) { if (mounted) _updateTime(); },
    );

    // Start check-in watcher
    _checkinWatcher = CheckinWatcher(context);
    _checkinWatcher!.start();

    // Initialize SOS monitor task (scream detection)
    _sosMonitorTask = SOSMonitorTask();
    _sosMonitorTask!.init();
    _sosMonitorTask!.onSOSDetected = _triggerSOS;

    // ── FIX 3: use addPostFrameCallback so context is fully ready ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPhraseDetection();
    });
  }

  // ── FIX 4: request microphone permission as well (needed for speech_to_text) ──
  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.microphone.request();
  }

  Future<void> _initPhraseDetection() async {
    if (!mounted) return;

    await DetectionForegroundService.requestPermissions();
    await DetectionForegroundService.requestBatteryOptimizationExemption();
    await DetectionForegroundService.start();

    final deviceId =
        Provider.of<AppProvider>(context, listen: false).userName;

    await _phraseService.initialize(deviceId, autoStart: true);

    if (!mounted) return;

    // Register background message callback
    FlutterForegroundTask.addTaskDataCallback(_onBackgroundMessage);

    // Wire SOS callback — FIX 5: mounted check before using context
    _phraseService.onEmergencyDetected = (result) {
      if (!mounted) return;

      DetectionForegroundService.updateNotification(
        '🆘 Emergency phrase: "${result.text}"',
      );

      _triggerSOS();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🆘 Emergency phrase: "${result.text}" '
                '(${(result.confidence * 100).toStringAsFixed(0)}%)',
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    };
  }

  void _updateTime() {
    // ── FIX 6: _onBackgroundMessage removed from here (it was nested here before) ──
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime =
        '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  void dispose() {
    // ── FIX 7: removeTaskDataCallback now works because method is at class level ──
    FlutterForegroundTask.removeTaskDataCallback(_onBackgroundMessage);
    _clockTimer?.cancel();
    _pendingTimer?.cancel();
    _sosController.dispose();
    _sosMonitorTask?.dispose();
    _checkinWatcher?.stop();
    _phraseService.dispose();
    // ✅ Foreground service NOT stopped here — keeps running in background
    super.dispose();
  }

  void _triggerSOS() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SOSScreen()),
    );
  }

  void _toggleVoiceTrigger() {
    setState(() => _isVoiceTriggerActive = !_isVoiceTriggerActive);
    if (_sosMonitorTask != null) {
      if (_isVoiceTriggerActive) {
        _sosMonitorTask!.start();
      } else {
        _sosMonitorTask!.stop();
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isVoiceTriggerActive
              ? 'Voice Trigger Active — Say "Help me Aawaj"'
              : 'Voice Trigger Disabled',
        ),
        backgroundColor: _isVoiceTriggerActive
            ? const Color(0xFF8b5cf6)
            : Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showMsg(String title, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $msg'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _scheduleCheckIn() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime:
      TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
    );

    if (time == null) return false;

    final scheduledAt =
    DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final finalScheduledAt = scheduledAt.isBefore(now)
        ? scheduledAt.add(const Duration(days: 1))
        : scheduledAt;

    final api = CheckInApi();

    try {
      final ok = await api.schedule(finalScheduledAt);
      if (ok) {
        _showMsg(
          'Check-in scheduled',
          'At ${finalScheduledAt.hour.toString().padLeft(2, '0')}:'
              '${finalScheduledAt.minute.toString().padLeft(2, '0')}',
        );
      } else {
        _showMsg('Failed', 'Could not schedule check-in.');
      }
      return ok;
    } catch (e) {
      _showMsg('Error', 'Scheduling failed: $e');
      return false;
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 14)),
                        Text(
                          provider.userName,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderButton(
                          Icons.masks,
                              () => provider.toggleDisguiseMode(),
                          tooltip: 'Disguise Mode',
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderButton(
                          Icons.settings,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status Card
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green[400],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Protection Active',
                            style: TextStyle(
                                color: Colors.green[400],
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(_currentTime,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // SOS Button
                Center(
                  child: GestureDetector(
                    onLongPress: _triggerSOS,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Hold for 3 seconds to trigger SOS'),
                          backgroundColor: Colors.orange[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: ScaleTransition(
                      scale: _sosAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFef4444),
                                  Color(0xFFb91c1c)
                                ],
                              ),
                              border: Border.all(
                                  color: const Color(0xFFf87171), width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.warning_rounded,
                                    size: 40, color: Colors.white),
                                const SizedBox(height: 8),
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Hold 3 sec',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.mic,
                        label: 'Voice Trigger',
                        color: const Color(0xFF8b5cf6),
                        isActive: _isVoiceTriggerActive,
                        onTap: _toggleVoiceTrigger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.location_on,
                        label: 'Share Location',
                        color: const Color(0xFF3b82f6),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.videocam,
                        label: 'Silent Record',
                        color: const Color(0xFFef4444),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RecordScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Phrase Detection Widget
                PhraseDetectionWidget(
                  service: _phraseService,
                  onEmergencyTriggered: _triggerSOS,
                ),
                const SizedBox(height: 16),

                // Scheduled Check-in
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.pink[400], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Scheduled Check-in',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                          Switch(
                            value: provider.checkInEnabled,
                            onChanged: (val) async {
                              if (val) {
                                final scheduled =
                                await _scheduleCheckIn();
                                if (scheduled &&
                                    !provider.checkInEnabled) {
                                  provider.toggleCheckIn();
                                }
                              } else {
                                if (provider.checkInEnabled) {
                                  provider.toggleCheckIn();
                                }
                              }
                            },
                            activeColor: const Color(0xFFec4899),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.checkInEnabled
                            ? 'Enabled: We will ask you to confirm when due.'
                            : 'Disabled',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Trusted Contacts
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield,
                                  color: Colors.pink[400], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Trusted Contacts',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('Manage',
                                style: TextStyle(
                                    color: Colors.pink[400])),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildContactsPreview(provider),
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

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap,
      {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border:
            Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.grey[300], size: 22),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : Colors.white.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style:
              TextStyle(fontSize: 11, color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsPreview(AppProvider provider) {
    if (provider.contacts.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    return Row(
      children: [
        ...provider.contacts.take(4).map((contact) {
          return Container(
            margin: const EdgeInsets.only(right: 4),
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
              ),
            ),
            child: Center(
              child: Text(
                contact.name[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          );
        }),
        if (provider.contacts.length > 4)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.grey[700]),
            child: Center(
              child: Text(
                '+${provider.contacts.length - 4}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}