import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/booking_provider.dart';

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen> {
  final _codeController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _validateTicket(String code) async {
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    final booking = Provider.of<BookingProvider>(context, listen: false);
    final result = await booking.scanTicket(code.trim().toUpperCase());

    setState(() {
      _isValidating = false;
    });

    if (result != null && mounted) {
      final success = result['success'] as bool;
      final message = result['message'] as String;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.redAccent,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Valide !' : 'Invalide'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (success && result['ticket'] != null) ...[
                const SizedBox(height: 12),
                Text('Code : ${result['ticket'].ticketCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Client : ${result['ticket'].user?.name ?? "Inconnu"}'),
                Text('Siège : N°${result['ticket'].seatNumber}'),
                Text('Trajet : ${result['ticket'].trip?.line?.name ?? "Inconnu"}'),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (success) {
                  _codeController.clear();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Tickets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Scanner Animation Overlay Mockup
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E3C72), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/scanner.svg',
                    colorFilter: const ColorFilter.mode(Color(0xFF1E3C72), BlendMode.srcIn),
                    width: 130,
                    height: 130,
                  ),
                  // Animated scan line simulation
                  Positioned(
                    top: 40,
                    child: Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 2)
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 20,
                    child: Text(
                      'Simulation Caméra Active',
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Saisir le Code du Ticket manuellement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
            ),
            const SizedBox(height: 12),

            // Text input for ticket code validation
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Ex: TEP-AB12CD34',
                prefixIcon: const Icon(Icons.confirmation_num),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _validateTicket(_codeController.text),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: _validateTicket,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isValidating ? null : () => _validateTicket(_codeController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isValidating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Valider le Billet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
