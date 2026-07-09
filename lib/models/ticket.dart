import 'trip.dart';

class Ticket {
  final int id;
  final int tripId;
  final int userId;
  final int seatNumber;
  final double price;
  final String ticketCode;
  final String status; // booked, used, cancelled
  final Trip? trip;

  Ticket({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.seatNumber,
    required this.price,
    required this.ticketCode,
    required this.status,
    this.trip,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      tripId: json['trip_id'],
      userId: json['user_id'],
      seatNumber: json['seat_number'],
      price: double.parse(json['price'].toString()),
      ticketCode: json['ticket_code'],
      status: json['status'],
      trip: json['trip'] != null ? Trip.fromJson(json['trip']) : null,
    );
  }
}
