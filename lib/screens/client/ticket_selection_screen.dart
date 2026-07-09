import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip.dart';
import '../../providers/booking_provider.dart';
import 'my_tickets_screen.dart';

class TicketSelectionScreen extends StatefulWidget {
  final Trip trip;
  const TicketSelectionScreen({super.key, required this.trip});

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _LoginCustomSpinner extends StatelessWidget {
  const _LoginCustomSpinner();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E3C72)),
          SizedBox(height: 16),
          Text("Traitement du paiement sécurisé..."),
        ],
      ),
    );
  }
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  bool _isProcessing = false;
  int _selectedSeatNumber = -1;

  void _book() async {
    if (_selectedSeatNumber == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un siège avant de continuer.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing for 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final booking = Provider.of<BookingProvider>(context, listen: false);
    final ticket = await booking.bookTicket(widget.trip.id, seatNumber: _selectedSeatNumber);

    setState(() {
      _isProcessing = false;
    });

    if (ticket != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Succès !'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre billet a été réservé avec succès.'),
              const SizedBox(height: 12),
              Text('Code : ${ticket.ticketCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Siège : N°${ticket.seatNumber}'),
              Text('Prix : ${ticket.price.toStringAsFixed(0)} FCFA'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                );
              },
              child: const Text('Voir mes billets'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(booking.errorMessage ?? 'Erreur lors de la réservation'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSeatGrid(int capacity) {
    final bookedSeats = widget.trip.bookedSeats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez votre Siège',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.white, 'Disponible'),
            const SizedBox(width: 12),
            _buildLegendItem(Colors.orangeAccent, 'Sélectionné'),
            const SizedBox(width: 12),
            _buildLegendItem(Colors.redAccent.shade100, 'Occupé'),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('VOLANT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ),
                  const Icon(Icons.person, color: Colors.blueGrey, size: 20), 
                ],
              ),
              const Divider(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: capacity,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, 
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final seatNum = index + 1;
                  final isBooked = bookedSeats.contains(seatNum);
                  final isSelected = _selectedSeatNumber == seatNum;
                  
                  return GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                            setState(() {
                              _selectedSeatNumber = isSelected ? -1 : seatNum;
                            });
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.redAccent.shade100
                            : isSelected
                                ? Colors.orangeAccent
                                : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orange
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_seat,
                              size: 14,
                              color: isBooked
                                  ? Colors.white
                                  : isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$seatNum',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: (isBooked || isSelected)
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.trip.line;
    if (line == null) return const Scaffold();
    final capacity = widget.trip.vehicle?.capacity ?? 14;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const _LoginCustomSpinner()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Details
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Date & Heure :', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(
                                '${widget.trip.departureTime.day}/${widget.trip.departureTime.month} à ${widget.trip.departureTime.hour.toString().padLeft(2, '0')}:${widget.trip.departureTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Véhicule :', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(widget.trip.vehicle?.name ?? 'Standard', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Chauffeur :', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(widget.trip.vehicle?.driver?.name ?? 'Non assigné', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Opérateur (GIE) :', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(line.gie?.name ?? 'Standard', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seats grid selection
                  _buildSeatGrid(capacity),
                  const SizedBox(height: 16),

                  if (_selectedSeatNumber != -1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Siège Sélectionné :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            'Siège N°$_selectedSeatNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bottom Total & Action
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tarif du billet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${line.basePrice.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _book,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3C72),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Confirmer & Payer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
