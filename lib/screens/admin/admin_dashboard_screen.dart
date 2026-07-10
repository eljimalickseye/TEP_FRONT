import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/tracking_provider.dart';
import '../login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../client/live_tracking_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _distanceController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BookingProvider>(context, listen: false).fetchLines();
      Provider.of<TrackingProvider>(context, listen: false).fetchPositions();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _distanceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showCreateLineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Créer une nouvelle Ligne'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom de la ligne (Ex: Dakar - Thiès)'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _startController,
                  decoration: const InputDecoration(labelText: 'Point de départ'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _endController,
                  decoration: const InputDecoration(labelText: 'Point d\'arrivée'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Distance invalide' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tarif de base (FCFA)'),
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Tarif invalide' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              
              final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
              
              final lineData = {
                'name': _nameController.text.trim(),
                'start_point': _startController.text.trim(),
                'end_point': _endController.text.trim(),
                'distance': double.parse(_distanceController.text.trim()),
                'base_price': double.parse(_priceController.text.trim()),
                'stops': [
                  {
                    'name': '${_startController.text} (Départ)',
                    'latitude': 14.6937,
                    'longitude': -17.4300,
                    'sequence': 1
                  },
                  {
                    'name': '${_endController.text} (Terminus)',
                    'latitude': 14.7910,
                    'longitude': -16.9298,
                    'sequence': 2
                  }
                ]
              };

              final success = await bookingProvider.createLine(lineData);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _nameController.clear();
                  _startController.clear();
                  _endController.clear();
                  _distanceController.clear();
                  _priceController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ligne de transport créée avec succès !'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(bookingProvider.errorMessage ?? 'Erreur lors de la création'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);
    final tracking = Provider.of<TrackingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await booking.fetchLines();
          await tracking.fetchPositions();
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supervision TepTep',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
              ),
              const SizedBox(height: 4),
              const Text('Visualisez l\'état du réseau de transport en temps réel.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '${booking.lines.length}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                            ),
                            const Text('Lignes Actives', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '${tracking.positions.length}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            const Text('Bus en Route', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
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
                  label: const Text('Ouvrir la Carte de Supervision Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Liste des Lignes de Transport',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                  ),
                  TextButton.icon(
                    onPressed: _showCreateLineDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer'),
                  ),
                ],
              ),

              Expanded(
                child: booking.lines.isEmpty
                    ? const Center(child: Text('Aucune ligne disponible.'))
                    : ListView.builder(
                        itemCount: booking.lines.length,
                        itemBuilder: (context, index) {
                          final line = booking.lines[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1E3C72),
                                foregroundColor: Colors.white,
                                child: SvgPicture.asset(
                                  'assets/icons/bus.svg',
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              title: Text(line.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${line.stops.length} arrêts • ${line.distance} km • ${line.basePrice.toStringAsFixed(0)} FCFA'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
