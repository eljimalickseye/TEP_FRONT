import 'vehicle.dart';

class VehiclePosition {
  final int id;
  final int vehicleId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime updatedAt;
  final Vehicle? vehicle;

  VehiclePosition({
    required this.id,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.updatedAt,
    this.vehicle,
  });

  factory VehiclePosition.fromJson(Map<String, dynamic> json) {
    return VehiclePosition(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      speed: json['speed'] != null ? double.parse(json['speed'].toString()) : null,
      heading: json['heading'] != null ? double.parse(json['heading'].toString()) : null,
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }
}
