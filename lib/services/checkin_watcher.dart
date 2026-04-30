import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkin_api.dart';
import '../providers/app_provider.dart';
import '../screens/sos_screen.dart';

class CheckinWatcher {
  final BuildContext context;
  Timer? _timer;
  final CheckInApi _api = CheckInApi();
  final Set<String> _handledCheckIns = {}; // Only handle each check-in once

  CheckinWatcher(this.context);

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPending());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _checkPending() async {

    // ✅ skip if disabled
    final pending = await _api.getPending();
    if (pending.isEmpty) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.checkInEnabled) return;
    for (var checkin in pending) {
      final id = checkin['id'].toString();
      if (_handledCheckIns.contains(id)) continue; // Already shown dialog

      final scheduledStr = checkin['scheduled_at'];
      final scheduledAt = DateTime.tryParse(scheduledStr ?? '');
      if (scheduledAt == null) continue;

      if (DateTime.now().isAfter(scheduledAt)) {
        _handledCheckIns.add(id);

        // Show Safe / Not Safe dialog
        _showCheckInDialog(id, scheduledStr!,provider);
      }
    }
  }

  void _showCheckInDialog(String checkInId, String scheduledAt, AppProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Check-in'),
          content: const Text('Are you safe?'),
          actions: [
            TextButton(
              onPressed: () async {
                // Mark Safe
                await _api.confirm(checkInId, isSafe: true, scheduledAt: scheduledAt);
                provider.setCheckInEnabled(false);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marked Safe ✅'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Safe',
                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                // Not Safe → trigger SOS
                await _api.confirm(checkInId, isSafe: false, scheduledAt: scheduledAt);
                provider.setCheckInEnabled(false);
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SOSScreen()),
                );
              },
              child: const Text('Not Safe',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }
}