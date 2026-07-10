import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../login_screen.dart';
import 'ticket_selection_screen.dart';
import 'my_tickets_screen.dart';
import 'live_tracking_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BookingProvider>(context, listen: false).fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TepTep Transport',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3C72),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await booking.fetchTrips();
        },
        child: Column(
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3C72),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${auth.user?.name ?? "Voyageur"} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Où souhaitez-vous voyager aujourd\'hui ?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyTicketsScreen(),
                              ),
                            );
                          },
                           icon: SvgPicture.asset(
                            'assets/icons/ticket.svg',
                            colorFilter: const ColorFilter.mode(Color(0xFF1E3C72), BlendMode.srcIn),
                            width: 20,
                            height: 20,
                          ),
                          label: const Text('Mes Billets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3C72),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LiveTrackingScreen(),
                              ),
                            );
                          },
                           icon: SvgPicture.asset(
                            'assets/icons/map.svg',
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            width: 20,
                            height: 20,
                          ),
                          label: const Text('Carte Live'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Départs Disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/bus.svg',
                    colorFilter: const ColorFilter.mode(Color(0xFF1E3C72), BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
            ),

            // List of trips
            Expanded(
              child: booking.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : booking.trips.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 64),
                            Center(
                              child: Text(
                                'Aucun voyage disponible pour le moment.\nGlissez vers le bas pour rafraîchir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: booking.trips.length,
                          itemBuilder: (context, index) {
                            final trip = booking.trips[index];
                            final line = trip.line;
                            if (line == null) return const SizedBox();

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                trip.status == 'in_progress' ? 'EN ROUTE' : 'PROGRAMMÉ',
                                                style: TextStyle(
                                                  color: trip.status == 'in_progress' ? Colors.green : Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            if (line.gie != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  line.gie!.code,
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '${line.basePrice.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Column(
                                          children: [
                                            Icon(Icons.radio_button_checked, color: Colors.blue, size: 18),
                                            SizedBox(
                                              height: 24,
                                              child: VerticalDivider(thickness: 2, color: Colors.grey),
                                            ),
                                            Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                line.startPoint,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                line.endPoint,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Départ',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            Text(
                                              '${trip.departureTime.day}/${trip.departureTime.month} à ${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Véhicule',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            Text(
                                              trip.vehicle?.name ?? 'Minibus Standard',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => TicketSelectionScreen(trip: trip),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E3C72),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Réserver un Billet'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
