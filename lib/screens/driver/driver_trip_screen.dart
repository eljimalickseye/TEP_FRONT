import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/tracking_provider.dart';
import '../login_screen.dart';
import 'ticket_scanner_screen.dart';
import '../../models/stop.dart';

class DriverTripScreen extends StatefulWidget {
  const DriverTripScreen({super.key});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  bool _isTripActive = false;
  double _tripProgress = 0.0; // 0.0 to 1.0
  Timer? _simulationTimer;
  bool _isAutoSimulating = false;

  bool _useRealGps = false;
  StreamSubscription<Position>? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BookingProvider>(context, listen: false).fetchTrips();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  LatLng _interpolatePosition(List<Stop> stops, double progress) {
    if (stops.isEmpty) return const LatLng(14.7167, -17.4677);
    if (stops.length == 1) return LatLng(stops.first.latitude, stops.first.longitude);
    
    if (progress <= 0.0) return LatLng(stops.first.latitude, stops.first.longitude);
    if (progress >= 1.0) return LatLng(stops.last.latitude, stops.last.longitude);

    double sectionWeight = 1.0 / (stops.length - 1);
    int sectionIndex = (progress / sectionWeight).floor();
    
    if (sectionIndex >= stops.length - 1) {
      return LatLng(stops.last.latitude, stops.last.longitude);
    }

    double sectionProgress = (progress - (sectionIndex * sectionWeight)) / sectionWeight;

    Stop start = stops[sectionIndex];
    Stop end = stops[sectionIndex + 1];

    double lat = start.latitude + (end.latitude - start.latitude) * sectionProgress;
    double lng = start.longitude + (end.longitude - start.longitude) * sectionProgress;

    return LatLng(lat, lng);
  }

  void _updateLocation(LatLng pos, {double speed = 50.0}) async {
    final tracking = Provider.of<TrackingProvider>(context, listen: false);
    await tracking.updateDriverLocation(
      pos.latitude,
      pos.longitude,
      speed: _isTripActive ? speed : 0.0,
      heading: 90.0,
    );
  }

  void _startTrip(List<Stop> stops) {
    setState(() {
      _isTripActive = true;
      _tripProgress = 0.0;
    });

    if (_useRealGps) {
      _startRealGpsTracking();
    } else {
      final startPos = _interpolatePosition(stops, 0.0);
      _updateLocation(startPos, speed: 0.0);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voyage démarré. Transmission GPS active.')),
    );
  }

  void _toggleAutoSimulation(List<Stop> stops) {
    if (_isAutoSimulating) {
      _simulationTimer?.cancel();
      setState(() {
        _isAutoSimulating = false;
      });
    } else {
      setState(() {
        _isAutoSimulating = true;
      });

      _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_tripProgress >= 1.0) {
          _simulationTimer?.cancel();
          setState(() {
            _isAutoSimulating = false;
            _isTripActive = false;
            _tripProgress = 1.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voyage terminé avec succès !'), backgroundColor: Colors.green),
          );
          return;
        }

        setState(() {
          _tripProgress += 0.05; 
          if (_tripProgress > 1.0) _tripProgress = 1.0;
        });

        final nextPos = _interpolatePosition(stops, _tripProgress);
        _updateLocation(nextPos, speed: 60.0);
      });
    }
  }

  Future<void> _toggleGpsMode(bool val, List<Stop> stops) async {
    if (val) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        setState(() {
          _useRealGps = true;
          if (_isAutoSimulating) {
            _toggleAutoSimulation(stops);
          }
        });
        if (_isTripActive) {
          _startRealGpsTracking();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission GPS refusée. Mode simulation forcé.')),
        );
      }
    } else {
      _gpsSubscription?.cancel();
      setState(() {
        _useRealGps = false;
      });
      if (_isTripActive) {
        final pos = _interpolatePosition(stops, _tripProgress);
        _updateLocation(pos);
      }
    }
  }

  void _startRealGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_isTripActive) {
        _updateLocation(
          LatLng(position.latitude, position.longitude),
          speed: position.speed * 3.6, 
        );
      }
    });
  }

  void _stopTrip() {
    _simulationTimer?.cancel();
    _gpsSubscription?.cancel();
    setState(() {
      _isTripActive = false;
      _isAutoSimulating = false;
      _tripProgress = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voyage terminé.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    final driverTripList = booking.trips.where((t) => t.vehicle?.driver?.id == auth.user?.id).toList();
    final trip = driverTripList.isNotEmpty ? driverTripList.first : null;
    final line = trip?.line;
    final stops = line?.stops ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Chauffeur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/logout.svg',
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: trip == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aucun voyage en cours d\'assignation pour vous aujourd\'hui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                line?.name ?? 'Trajet',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                              ),
                              SvgPicture.asset(
                                'assets/icons/bus.svg',
                                colorFilter: const ColorFilter.mode(Color(0xFF1E3C72), BlendMode.srcIn),
                                width: 22,
                                height: 22,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('Véhicule : ${trip.vehicle?.name} (${trip.vehicle?.licensePlate})'),
                          const SizedBox(height: 6),
                          Text('Départ prévu : ${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}'),
                          const SizedBox(height: 6),
                          Text('Nombre d\'arrêts : ${stops.length}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Scanner Option
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TicketScannerScreen(),
                          ),
                        );
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/scanner.svg',
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        width: 20,
                        height: 20,
                      ),
                      label: const Text('Scanner / Valider un Ticket Client'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // GPS / Simulation Switch
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: const Text('Utiliser le GPS réel de l\'appareil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Désactivez pour simuler le trajet sur l\'écran', style: TextStyle(fontSize: 11)),
                      value: _useRealGps,
                      activeColor: const Color(0xFF1E3C72),
                      onChanged: (val) => _toggleGpsMode(val, stops),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Simulator Panel
                  if (_isTripActive && !_useRealGps) ...[
                    Card(
                      elevation: 6,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Simulation GPS en Cours',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: _tripProgress,
                              min: 0.0,
                              max: 1.0,
                              activeColor: const Color(0xFF1E3C72),
                              inactiveColor: Colors.grey.shade300,
                              onChanged: _isAutoSimulating
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _tripProgress = val;
                                      });
                                      final pos = _interpolatePosition(stops, val);
                                      _updateLocation(pos);
                                    },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(line?.startPoint ?? 'Départ', style: const TextStyle(fontSize: 12)),
                                Text('${(_tripProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(line?.endPoint ?? 'Arrivée', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _toggleAutoSimulation(stops),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isAutoSimulating ? Colors.orange : Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(_isAutoSimulating ? 'Pause Simulation' : 'Simulation Auto'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isTripActive && _useRealGps) ...[
                    Card(
                      elevation: 6,
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/map.svg',
                              colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Transmission de vos coordonnées GPS réelles active...',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons (Start/End trip)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isTripActive ? _stopTrip : () => _startTrip(stops),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTripActive ? Colors.redAccent : const Color(0xFF1E3C72),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isTripActive ? 'Terminer le Voyage' : 'Commencer le Voyage',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
