import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../providers/app_provider.dart';
import '../services/emergency_api.dart';
import '../services/sms_sender.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with SingleTickerProviderStateMixin {
  int _countdown = 10;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _locationShared = false;
  bool _recordingStarted = false;
  bool _smsAlertsSending = true;

  bool _executed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(seconds: 1), vsync: this)
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdown <= 0) {
        timer.cancel();
        if (!_executed) {
          _executed = true;
          await _executeSOS();
        }
        return;
      }

      setState(() {
        _countdown--;

        // UI progress simulation
        if (_countdown == 8) _locationShared = true;
        if (_countdown == 6) _recordingStarted = true;
      });
    });
  }

  Future<Position?> _getLocationSafely() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _executeSOS() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (!provider.isLoggedIn) {
      setState(() => _smsAlertsSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login required to trigger backend SOS. Please login first.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1) Get location
    final pos = await _getLocationSafely();
    final lat = pos?.latitude ?? 0.0;
    final lng = pos?.longitude ?? 0.0;

    // 2) Call backend to build message + phones
    final api = EmergencyApi(provider.accessToken!);
    final response = await api.triggerSOS(latitude: lat, longitude: lng);

    setState(() {
      _smsAlertsSending = false;
    });

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to trigger SOS backend. Check server logs / token.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phones = (response['phones'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final message = response['message']?.toString() ?? 'SOS! I need help.';

    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No emergency contacts found in backend. Add contacts first.'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3) Open SMS composer for each phone (offline-friendly)
    for (final p in phones) {
      await SmsSender.openSmsComposer(phone: p, message: message);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SOS prepared for ${phones.length} contact(s). Please press SEND in SMS app.'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelSOS() {
    _timer?.cancel();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('SOS Cancelled - You are safe'),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900.withOpacity(0.9),
              Colors.red.shade800.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red[500],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.warning_rounded, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'SOS ACTIVATED',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emergency alerts being prepared...',
                    style: TextStyle(fontSize: 16, color: Colors.red[200]),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildStatusItem('Location shared with contacts', _locationShared),
                        const SizedBox(height: 16),
                        _buildStatusItem('Audio recording started', _recordingStarted),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          'Sending SMS alerts...',
                          !_smsAlertsSending,
                          isLoading: _smsAlertsSending,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_countdown > 0)
                    Text(
                      'Cancel in: ${_countdown}s',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red[200],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cancelSOS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[900],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close),
                          SizedBox(width: 8),
                          Text('Cancel SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String text, bool isComplete, {bool isLoading = false}) {
    return Row(
      children: [
        if (isLoading)
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.yellow[400]),
            ),
          )
        else
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green[400] : Colors.grey[400],
            size: 24,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}
