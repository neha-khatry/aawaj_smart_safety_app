import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../services/checkin_api.dart';
import '../services/sos_monitor_task.dart'; // Foreground service integration
import 'sos_screen.dart';
import 'settings_screen.dart';
import 'record_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _sosController;
  late Animation<double> _sosAnimation;
  String _currentTime = '';
  bool _isVoiceTriggerActive = false;

  Timer? _pendingTimer;
  String? _lastShownPendingId;

  SOSMonitorTask? _sosMonitorTask;

  @override
  void initState() {
    super.initState();

    _sosController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _sosAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );

    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // Poll backend for pending check-ins
    _pendingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkPending());

    // Initialize SOS monitor task
    _sosMonitorTask = SOSMonitorTask();
    _sosMonitorTask!.init();
    _sosMonitorTask!.onSOSDetected = _triggerSOS;
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _sosController.dispose();
    _sosMonitorTask?.dispose();
    super.dispose();
  }

  void _triggerSOS() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SOSScreen()),
    );
  }

  void _toggleVoiceTrigger() async{
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
              ? 'Voice Trigger Active - Say "Help me Aawaj"'
              : 'Voice Trigger Disabled',
        ),
        backgroundColor: _isVoiceTriggerActive ? const Color(0xFF8b5cf6) : Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // Start or stop foreground service based on conditions
    '''final provider = Provider.of<AppProvider>(context, listen: false);
    if (_isVoiceTriggerActive && !provider.checkInEnabled) {
      await SOSMonitorTask.start(onSOS: _triggerSOS); // start foreground service
    } else {
      SOSMonitorTask.stop(); // stop if conditions not met
    }''';
  }

  void _showMsg(String title, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $msg'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scheduleCheckIn() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (!provider.isLoggedIn) {
      _showMsg('Login required', 'Please login first to use backend check-in.');
      return;
    }

    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
    );

    if (time == null) return;

    final scheduledAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final finalScheduledAt =
    scheduledAt.isBefore(now) ? scheduledAt.add(const Duration(days: 1)) : scheduledAt;

    final api = CheckInApi(provider.accessToken!);

    try {
      final ok = await api.schedule(finalScheduledAt);
      if (ok) {
        _showMsg(
          'Check-in scheduled',
          'Scheduled at ${finalScheduledAt.hour.toString().padLeft(2, '0')}:${finalScheduledAt.minute.toString().padLeft(2, '0')}',
        );
      } else {
        _showMsg('Failed', 'Could not schedule check-in.');
      }
    } catch (e) {
      _showMsg('Error', 'Scheduling failed: $e');
    }
    // Stop foreground service if scheduled check-in is enabled
    //if (provider.checkInEnabled) {
      //SOSMonitorTask.stop();
    //}
  }

  Future<void> _checkPending() async {
    if (!mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.isLoggedIn) return;

    final api = CheckInApi(provider.accessToken!);

    try {
      final pending = await api.getPending();
      if (pending.isEmpty) return;

      final first = pending.first;
      final id = (first['id'] ?? '').toString();
      if (id.isEmpty) return;

      if (_lastShownPendingId == id) return;
      _lastShownPendingId = id;

      if (!mounted) return;
      await _showConfirmDialog(checkInId: id);
    } catch (_) {
      // ignore polling errors
    }
  }

  Future<void> _showConfirmDialog({required String checkInId}) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final api = CheckInApi(provider.accessToken!);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: const Text('Safety Check-in', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you safe? Please confirm.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await api.confirm(checkInId, isSafe: false, mood: 'bad', message: 'Not safe');
                if (mounted) Navigator.pop(context);
                _showMsg('Marked NOT safe', 'You can trigger SOS now.');
              },
              child: const Text('NOT SAFE', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                await api.confirm(checkInId, isSafe: true, mood: 'okay', message: 'I am safe');
                if (mounted) Navigator.pop(context);
                _showMsg('Confirmed', 'Check-in completed.');
              },
              child: const Text('I AM SAFE'),
            ),
          ],
        );
      },
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        Text(
                          provider.userName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                            style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(_currentTime, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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
                          content: const Text('Hold for 3 seconds to trigger SOS'),
                          backgroundColor: Colors.orange[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: ScaleTransition(
                      scale: _sosAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect
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
                          // Main button
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFef4444), Color(0xFFb91c1c)],
                              ),
                              border: Border.all(color: const Color(0xFFf87171), width: 4),
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
                                const Icon(Icons.warning_rounded, size: 40, color: Colors.white),
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
                                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
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
                            MaterialPageRoute(builder: (_) => const RecordScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Scheduled Check-in (Backend)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.pink[400], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Scheduled Check-in',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ],
                          ),
                          Switch(
                            value: provider.checkInEnabled,
                            onChanged: (val) async {
                              provider.toggleCheckIn();
                              if (val) await _scheduleCheckIn();
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
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      if (!provider.isLoggedIn) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Backend check-in requires login/token (JWT).',
                          style: TextStyle(color: Colors.orange[300], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: const Text('Login now'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Logged in ✅ (token saved).',
                          style: TextStyle(color: Colors.green[300], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              await provider.logout();
                              _showMsg('Logged out', 'Token cleared.');
                            },
                            child: const Text('Logout'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Trusted Contacts Preview
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.pink[400], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Trusted Contacts',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('Manage', style: TextStyle(color: Colors.pink[400])),
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

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
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
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
              style: TextStyle(fontSize: 11, color: Colors.grey[300]),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          );
        }),
        if (provider.contacts.length > 4)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[700]),
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