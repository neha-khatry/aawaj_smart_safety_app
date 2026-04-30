import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../utils/constants.dart';
class ScreamListenerService {
  late FlutterSoundRecorder _recorder;
  bool _isListening = false;

  /// Callback that triggers whenever a scream is detected
  void Function()? onScreamDetected;

  ScreamListenerService() {
    _recorder = FlutterSoundRecorder();
  }

  Future<void> init() async {
    await _recorder.openRecorder();
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;
    _listenLoop();
  }

  void stopListening() {
    _isListening = false;
  }

  Future<void> _listenLoop() async {
    while (_isListening) {
      final file = File('${Directory.systemTemp.path}/temp_scream.wav');

      try {
        await _recorder.startRecorder(
          toFile: file.path,
          codec: Codec.pcm16WAV,
        );

        // Record for 3 seconds (adjust as needed)
        await Future.delayed(const Duration(seconds: 3));

        await _recorder.stopRecorder();

        // Send to backend
        final isScream = await _sendToBackend(file);
        if (isScream) {
          // Trigger callback
          if (onScreamDetected != null) {
            onScreamDetected!();
          }
        }
      } catch (e) {
        print('Recorder error: $e');
      }
    }
  }

  Future<bool> _sendToBackend(File audioFile) async {
    final uri = Uri.parse('${Constants.baseUrl}/detect_scream/');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio_file', // must match Django field
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    try {
      final response = await request.send();
      final result = await response.stream.bytesToString();
      print('Backend response: $result');
      final Map<String, dynamic> resultJson = jsonDecode(result);

      // ✅ Fully trust backend prediction
      return resultJson['prediction'] == 'SCREAM';
    } catch (e) {
      print('Error sending audio: $e');
      return false;
    }
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}