import 'line.dart';
import 'vehicle.dart';

class Trip {
  final int id;
  final int lineId;
  final int vehicleId;
  final DateTime departureTime;
  final String status; // scheduled, in_progress, completed, cancelled
  final Line? line;
  final Vehicle? vehicle;
  final int ticketsCount;
  final List<int> bookedSeats;

  Trip({
    required this.id,
    required this.lineId,
    required this.vehicleId,
    required this.departureTime,
    required this.status,
    this.line,
    this.vehicle,
    this.ticketsCount = 0,
    this.bookedSeats = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    var ticketList = json['tickets'] as List? ?? [];
    List<int> bookedSeats = ticketList
        .where((t) => t['status'] == 'booked')
        .map((t) => int.parse(t['seat_number'].toString()))
        .toList();

    return Trip(
      id: json['id'],
      lineId: json['line_id'],
      vehicleId: json['vehicle_id'],
      departureTime: DateTime.parse(json['departure_time']),
      status: json['status'],
      line: json['line'] != null ? Line.fromJson(json['line']) : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      ticketsCount: json['tickets_count'] ?? 0,
      bookedSeats: bookedSeats,
    );
  }
}
