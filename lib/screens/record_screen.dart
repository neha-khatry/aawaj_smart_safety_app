import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/glass_card.dart';

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
                    const Text(
                      'Silent Recording',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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
                          _recordingType == 'Audio' ? Icons.mic : Icons.videocam,
                          size: 40,
                          color: _isRecording ? Colors.red : Colors.red.shade300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording ? 'Recording $_recordingType...' : 'Ready to Record',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(_formattedTime, style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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

  Widget _buildRecordButton(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
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
            Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
