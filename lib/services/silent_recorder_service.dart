import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
class SilentRecorderService {
  static final SilentRecorderService _instance =
  SilentRecorderService._internal();

  factory SilentRecorderService() => _instance;
  SilentRecorderService._internal();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;

    await Permission.microphone.request();
    await _recorder.openRecorder();
    _initialized = true;
  }

  /// Starts silent recording and returns local file path
  Future<String> start() async {
    await _init();

    final baseDir = await getExternalStorageDirectory();
    final sosDir = Directory('${baseDir!.path}/AawajSOS');
    if (!await sosDir.exists()) {
      await sosDir.create(recursive: true);
    }
    final filePath =
        '${sosDir.path}/sos_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
      bitRate: 128000,
      sampleRate: 44100,
    );

    // 🕒 Auto-stop after 30 seconds
    Timer(const Duration(seconds: 30), () async {
      if (_recorder.isRecording) {
        try {
          await _recorder.stopRecorder();
        } catch (_) {}
      }
    });
    return filePath;
  }

  Future<void> stop() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
  }
}
