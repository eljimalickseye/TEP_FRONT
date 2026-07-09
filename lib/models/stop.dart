class Stop {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequence;

  Stop({required this.id, required this.name, required this.latitude, required this.longitude, required this.sequence});

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      name: json['name'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      sequence: json['sequence'],
    );
  }
}
