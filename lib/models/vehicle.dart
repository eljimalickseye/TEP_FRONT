import 'user.dart';
import 'trip.dart';
import 'gie.dart';

class Vehicle {
  final int id;
  final String name;
  final String licensePlate;
  final int capacity;
  final String status;
  final User? driver;
  final List<Trip>? trips;
  final int? gieId;
  final Gie? gie;

  Vehicle({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.capacity,
    required this.status,
    this.driver,
    this.trips,
    this.gieId,
    this.gie,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    var tripList = json['trips'] as List?;
    List<Trip>? trips = tripList?.map((t) => Trip.fromJson(t)).toList();

    return Vehicle(
      id: json['id'],
      name: json['name'],
      licensePlate: json['license_plate'],
      capacity: json['capacity'],
      status: json['status'],
      driver: json['driver'] != null ? User.fromJson(json['driver']) : null,
      trips: trips,
      gieId: json['gie_id'],
      gie: json['gie'] != null ? Gie.fromJson(json['gie']) : null,
    );
  }
}
