class Gie {
  final int id;
  final String name;
  final String code;
  final String status;

  Gie({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  factory Gie.fromJson(Map<String, dynamic> json) {
    return Gie(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status,
    };
  }
}
