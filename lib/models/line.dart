import 'stop.dart';
import 'gie.dart';

class Line {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final double distance;
  final double basePrice;
  final List<Stop> stops;
  final int? gieId;
  final Gie? gie;

  Line({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.basePrice,
    required this.stops,
    this.gieId,
    this.gie,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    var stopList = json['stops'] as List? ?? [];
    List<Stop> stops = stopList.map((s) => Stop.fromJson(s)).toList();

    return Line(
      id: json['id'],
      name: json['name'],
      startPoint: json['start_point'],
      endPoint: json['end_point'],
      distance: double.parse(json['distance'].toString()),
      basePrice: double.parse(json['base_price'].toString()),
      stops: stops,
      gieId: json['gie_id'],
      gie: json['gie'] != null ? Gie.fromJson(json['gie']) : null,
    );
  }
}
