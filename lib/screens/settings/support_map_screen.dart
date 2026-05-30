import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SupportMapScreen extends StatelessWidget {
  const SupportMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const location =
        LatLng(10.8061539, 106.6286656);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liên hệ hỗ trợ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Vị trí hỗ trợ',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: location,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.coin_nest',
                    ),

                    MarkerLayer(
                      markers: [
                        Marker(
                          point: location,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              '10.8061539, 106.6286656',
            ),
          ],
        ),
      ),
    );
  }
}