import 'package:flutter/material.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isTracking = false;
  bool _isSharing = false;
  final List<Map<String, dynamic>> _contacts = [
    {'name': 'Mom', 'phone': '+91 98765 43210', 'sharing': true},
    {'name': 'Dad', 'phone': '+91 98765 43211', 'sharing': true},
    {'name': 'Best Friend', 'phone': '+91 98765 43212', 'sharing': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showLocationHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
              child: Stack(
                children: [
                  // Simulated Map
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 100,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map View',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _isTracking ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '28.6139° N, 77.2090° E',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current Location Marker
                  if (_isTracking)
                    Positioned(
                      top: 100,
                      left: MediaQuery.of(context).size.width / 2 - 25,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Controls
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tracking Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isTracking
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTracking
                              ? Icons.location_on
                              : Icons.location_off,
                          color: _isTracking ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTracking
                                    ? 'Location Active'
                                    : 'Location Off',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _isTracking
                                    ? 'Tracking your location'
                                    : 'Enable to track location',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isTracking,
                          onChanged: (value) {
                            setState(() => _isTracking = value);
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Share with Contacts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isSharing
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_location,
                          color: _isSharing ? Colors.blue : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Share Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _isSharing
                                    ? 'Sharing with 2 contacts'
                                    : 'Share with trusted contacts',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isSharing,
                          onChanged: (value) {
                            setState(() => _isSharing = value);
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trusted Contacts List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              contact['name'][0],
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(contact['name']),
                          subtitle: Text(contact['phone']),
                          trailing: Icon(
                            contact['sharing']
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: contact['sharing']
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onTap: () {
                            setState(() {
                              _contacts[index]['sharing'] =
                              !_contacts[index]['sharing'];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _historyItem('Today, 2:30 PM', 'Connaught Place, New Delhi'),
            _historyItem('Today, 11:00 AM', 'India Gate, New Delhi'),
            _historyItem('Yesterday, 6:00 PM', 'Hauz Khas, New Delhi'),
            _historyItem('Yesterday, 10:00 AM', 'Saket Mall, New Delhi'),
          ],
        ),
      ),
    );
  }

  Widget _historyItem(String time, String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
