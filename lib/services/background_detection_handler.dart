// lib/services/background_detection_handler.dart
// This runs in a separate isolate when app is in background

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// This function MUST be a top-level function (not inside a class)
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundDetectionHandler());
}

class BackgroundDetectionHandler extends TaskHandler {

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[Background] Detection service started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called every interval — send keepalive ping to main isolate
    FlutterForegroundTask.sendDataToMain({
      'type': 'restart listening',
      'timestamp': timestamp.toIso8601String(),
    });
  }


  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('[Background] Detection service stopped');
  }

  @override
  void onReceiveData(Object data) {
    // Receive messages from main isolate if needed
    print('[Background] Received: $data');
  }
}
