enum UserRole { patient, doctor }

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime? birthDate;
  final UserRole role;
  final String? crm; // Apenas para médicos
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.birthDate,
    required this.role,
    this.crm,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      role: json['crm'] != null ? UserRole.doctor : UserRole.patient,
      crm: json['crm'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, role: $role, email: $email)';
  }
}
