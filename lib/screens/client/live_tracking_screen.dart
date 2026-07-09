import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/booking_provider.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BookingProvider>(context, listen: false).fetchLines();
      Provider.of<TrackingProvider>(context, listen: false).startPolling();
    });
  }

  @override
  void dispose() {
    // Stop polling when leaving the screen
    Future.microtask(() {
      if (mounted) {
        Provider.of<TrackingProvider>(context, listen: false).stopPolling();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = Provider.of<TrackingProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    // Build markers list
    List<Marker> markers = [];

    // Add Stop markers for all lines
    for (var line in booking.lines) {
      for (var stop in line.stops) {
        markers.add(
          Marker(
            point: LatLng(stop.latitude, stop.longitude),
            width: 40,
            height: 40,
            child: Tooltip(
              message: '${line.name} - ${stop.name}',
              child: const Icon(
                Icons.location_on,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
          ),
        );
      }
    }

    // Add Vehicle markers (buses live positions)
    for (var pos in tracking.positions) {
      final trip = pos.vehicle?.trips?.isNotEmpty == true ? pos.vehicle!.trips!.first : null;
      final lineName = trip?.line?.name ?? "Hors Service";

      markers.add(
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 60,
          height: 60,
          child: Column(
            children: [
              // Vehicle label popup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3C72),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Text(
                  pos.vehicle?.licensePlate ?? 'BUS',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pos.vehicle?.name ?? 'Véhicule',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Plaque : ${pos.vehicle?.licensePlate}'),
                          Text('Chauffeur : ${pos.vehicle?.driver?.name ?? "Inconnu"}'),
                          Text('Trajet Actif : $lineName'),
                          if (pos.speed != null)
                            Text('Vitesse : ${pos.speed!.toStringAsFixed(1)} km/h'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
                              },
                              child: const Text('Centrer sur le bus'),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  radius: 16,
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi en Temps Réel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              tracking.fetchPositions();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Widget
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(14.7167, -17.25), // Centered near Dakar / Rufisque / Mbour
              initialZoom: 9.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.teptep.app',
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),

          // Bottom card showing status
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 6,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tracking.positions.length} bus en circulation',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Text(
                      'Mise à jour : 5s',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
