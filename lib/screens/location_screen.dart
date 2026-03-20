import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/mini_map.dart';
import 'full_map_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchLiveLocation();
    });
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

                /// 🗺️ MINI MAP
                GestureDetector(
                  onTap: provider.latitude == null
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullMapScreen(
                          lat: provider.latitude!,
                          lng: provider.longitude!,
                          accuracy: provider.accuracy,
                        ),
                      ),
                    );
                  },
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 250,
                      child: provider.latitude == null
                          ? _loadingState(provider.locationStatus)
                          : Stack(
                        children: [
                          MiniMap(
                            location: LatLng(
                              provider.latitude!,
                              provider.longitude!,
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Tap to expand',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔗 SHARE BUTTON
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

                /// ⚙️ TRACKING OPTIONS
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tracking Options',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
      String label,
      bool value,
      Function(bool) onChanged,
      Color activeColor,
      ) {
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

  Widget _loadingState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 12),
          Text(status, style: TextStyle(color: Colors.grey[300])),
        ],
      ),
    );
  }
}
