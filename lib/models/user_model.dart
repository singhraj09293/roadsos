class UserModel {
  final String id;
  final String name;
  final String phone;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<EmergencyContact> emergencyContacts;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.emergencyContacts = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      emergencyContacts: (map['emergencyContacts'] as List? ?? [])
          .map((e) => EmergencyContact.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
    };
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }
}
