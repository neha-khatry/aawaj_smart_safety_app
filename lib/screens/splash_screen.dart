import 'package:flutter/material.dart';
import 'dart:async';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  String _loadingText = 'Initializing safety protocols...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _loadingMessages = [
    'Initializing safety protocols...',
    'Setting up emergency triggers...',
    'Connecting to GPS services...',
    'Loading AI support system...',
    'Ready to protect you!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLoading();
  }

  void _startLoading() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 100) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        });
        return;
      }

      setState(() {
        _progress += 2;
        if (_progress >= 20 && _progress < 40) {
          _loadingText = _loadingMessages[1];
        } else if (_progress >= 40 && _progress < 60) {
          _loadingText = _loadingMessages[2];
        } else if (_progress >= 60 && _progress < 90) {
          _loadingText = _loadingMessages[3];
        } else if (_progress >= 90) {
          _loadingText = _loadingMessages[4];
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with pulse animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple effect
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFec4899).withOpacity(0.2),
                        ),
                      ),
                      // Main logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x80ec4899),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // App name
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFf472b6), Color(0xFFa78bfa)],
                  ).createShader(bounds),
                  child: const Text(
                    'Aawaj',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Voice Against Violence',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 48),

                // Progress bar
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Loading text
                Text(
                  _loadingText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
