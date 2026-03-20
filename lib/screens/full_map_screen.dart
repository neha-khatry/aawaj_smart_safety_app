import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FullMapScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final double? accuracy;

  const FullMapScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.accuracy,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final userPoint = LatLng(widget.lat, widget.lng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
        backgroundColor: const Color(0xFF16213e),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final url =
                  'https://maps.google.com/?q=${widget.lat},${widget.lng}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Location link copied:\n$url')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.warning_rounded),
            color: Colors.red[300],
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Emergency'),
                  content: const Text(
                      'Share your live location with emergency contacts?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text('Emergency location shared!')),
                        );
                      },
                      child: const Text('Share'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: userPoint,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.aawaj.app',
          ),

          /// 🎯 Accuracy Circle
          if (widget.accuracy != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: userPoint,
                  radius: widget.accuracy!,
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.2),
                  borderColor: Colors.blue.withOpacity(0.6),
                  borderStrokeWidth: 2,
                ),
              ],
            ),

          /// 📍 User Marker
          MarkerLayer(
            markers: [
              Marker(
                point: userPoint,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
