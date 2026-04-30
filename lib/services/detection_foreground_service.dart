// lib/services/detection_foreground_service.dart

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'background_detection_handler.dart';

class DetectionForegroundService {

  // ── Initialize (call once at app startup) ────────────────────────────
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aawaj_detection_channel',
        channelName: 'Aawaj Safety Detection',
        channelDescription:
        'Aawaj is listening for emergency phrases and screams',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,            // ← keeps CPU alive
        allowWifiLock: true,
      ),
    );
  }

  // ── Request permissions ───────────────────────────────────────────────
  static Future<bool> requestPermissions() async {
    final NotificationPermission notifPerm =
    await FlutterForegroundTask.checkNotificationPermission();
    if (notifPerm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    return true;
  }

  // ── Start service ─────────────────────────────────────────────────────
  static Future<ServiceRequestResult> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }
    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Aawaj is protecting you',
      notificationText: 'Listening for emergency phrases and screams',
      callback: startCallback,         // top-level function from handler file
    );
  }
  static Future<void> requestBatteryOptimizationExemption() async {
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
  // ── Stop service ──────────────────────────────────────────────────────
  static Future<ServiceRequestResult> stop() async {
    return FlutterForegroundTask.stopService();
  }

  // ── Update notification text ──────────────────────────────────────────
  static Future<void> updateNotification(String text) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Aawaj is protecting you',
      notificationText: text,
    );
  }

  // ── Check if running ──────────────────────────────────────────────────
  static Future<bool> get isRunning =>
      FlutterForegroundTask.isRunningService;
}