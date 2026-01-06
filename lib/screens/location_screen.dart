import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import 'dart:async';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.setLocationStatus('Fetching location...');

    // Simulate location fetch - in real app use geolocator package
    await Future.delayed(const Duration(seconds: 2));
    provider.updateLocation(28.6139, 77.2090, 'Location found!');
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
                const Text(
                  'Live Location',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900.withOpacity(0.5),
                          Colors.purple.shade900.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            child: Icon(Icons.location_on,
                                size: 40, color: Colors.blue[400]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.locationStatus,
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                          if (provider.latitude != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${provider.latitude?.toStringAsFixed(4)}, ${provider.longitude?.toStringAsFixed(4)}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Location shared with ${provider.contacts.length} contact(s)'),
                          backgroundColor: Colors.green[700],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share with All Contacts'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF3b82f6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tracking Options',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildToggleRow(
                        'Live tracking',
                        provider.liveTracking,
                            (_) => provider.toggleLiveTracking(),
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        'Offline SMS fallback',
                        provider.smsAlerts,
                            (_) => provider.toggleSmsAlerts(),
                        Colors.green,
                      ),
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

  Widget _buildToggleRow(
      String label, bool value, Function(bool) onChanged, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[300])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }
}
