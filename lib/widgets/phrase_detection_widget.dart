// lib/widgets/phrase_detection_widget.dart
// ==========================================
// Aawaj Phrase Detection UI Widget
//
// A compact toggle widget that shows:
//   - ON/OFF toggle for phrase detection
//   - Live microphone status indicator
//   - Live speech transcript
//   - Last detected phrases
//   - Emergency trigger visual feedback
//
// Can be embedded in HomeScreen or used standalone.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/phrase_detection_service.dart';

class _AppColors {
  static const bg       = Color(0xFF0D0D1A);
  static const surface  = Color(0xFF1A1A2E);
  static const primary  = Color(0xFFE94560);
  static const accent   = Color(0xFF7B2FBE);
  static const green    = Color(0xFF4CAF50);
  static const muted    = Color(0xFF9E9EC8);
  static const white    = Color(0xFFEEEEEE);
  static const crisis   = Color(0xFFFF6B35);
}

class PhraseDetectionWidget extends StatefulWidget {
  final PhraseDetectionService service;
  final VoidCallback? onEmergencyTriggered;

  const PhraseDetectionWidget({
    Key? key,
    required this.service,
    this.onEmergencyTriggered,
  }) : super(key: key);

  @override
  State<PhraseDetectionWidget> createState() => _PhraseDetectionWidgetState();
}

class _PhraseDetectionWidgetState extends State<PhraseDetectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _showEmergencyFlash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Wire emergency callback
    widget.service.onEmergencyDetected = (result) {
      setState(() => _showEmergencyFlash = true);
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showEmergencyFlash = false);
      });
      widget.onEmergencyTriggered?.call();
    };

    widget.service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _flashTimer?.cancel();
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  // ── Toggle ─────────────────────────────────────────────────────────
  Future<void> _toggle() async {
    if (widget.service.isActive) {
      await widget.service.stopListening();
    } else {
      await widget.service.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _showEmergencyFlash
            ? _AppColors.crisis.withValues(alpha: 0.15)
            : _AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _showEmergencyFlash
              ? _AppColors.crisis
              : svc.isActive
                  ? _AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFF2A2A4A),
          width: _showEmergencyFlash ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────
            Row(
              children: [
                // Mic icon with pulse
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final opacity = svc.isListening
                        ? 0.4 + 0.6 * _pulseCtrl.value
                        : 1.0;
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: svc.isActive
                              ? (svc.isListening ? _AppColors.primary : _AppColors.accent)
                              : _AppColors.surface,
                          border: Border.all(
                            color: svc.isActive ? _AppColors.primary : const Color(0xFF2A2A4A),
                          ),
                        ),
                        child: Icon(
                          svc.isListening ? Icons.mic : Icons.mic_off,
                          size: 16,
                          color: svc.isActive ? _AppColors.white : _AppColors.muted,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 10),

                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phrase Detection',
                        style: TextStyle(
                          color: _AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        svc.statusMessage,
                        style: TextStyle(
                          color: _showEmergencyFlash
                              ? _AppColors.crisis
                              : svc.isListening
                                  ? _AppColors.green
                                  : _AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggle switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value:          svc.isActive,
                    onChanged:      (_) => _toggle(),
                    activeColor:    _AppColors.primary,
                    inactiveThumbColor: _AppColors.muted,
                  ),
                ),
              ],
            ),

            // ── Live transcript ──────────────────────────────────────
            if (svc.isActive && svc.currentText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A4A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, size: 13, color: _AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '"${svc.currentText}"',
                        style: const TextStyle(
                          color: _AppColors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Emergency flash ──────────────────────────────────────
            if (_showEmergencyFlash && svc.lastResult != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AppColors.crisis.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _AppColors.crisis.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: _AppColors.crisis, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🆘 Emergency phrase detected!',
                            style: TextStyle(
                              color: _AppColors.crisis,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '"${svc.lastResult!.text}" '
                            '(${(svc.lastResult!.confidence * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              color: _AppColors.crisis,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Info chip when active ────────────────────────────────
            if (svc.isActive && !_showEmergencyFlash) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  _chip('EN: Help me, Call police', _AppColors.accent),
                  _chip('NP: Bachau, Madad gara', _AppColors.primary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }
}
