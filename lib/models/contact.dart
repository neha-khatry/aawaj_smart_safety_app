class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      relation: json['relation'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relation': relation,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
