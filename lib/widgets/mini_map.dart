import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMap extends StatelessWidget {
  final LatLng location;

  const MiniMap({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: location,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.aawaj.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
