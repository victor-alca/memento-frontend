class PatientModel {
  final int id;
  final String userId;
  final String name;
  final String email;
  final DateTime? birthDate;
  final bool isConfirmed;
  final String? confirmationToken;
  final DateTime? tokenExpiresAt;

  PatientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.birthDate,
    this.isConfirmed = false,
    this.confirmationToken,
    this.tokenExpiresAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      isConfirmed: json['confirmed'] as bool? ?? false,
      confirmationToken: json['confirmation_token'] as String?,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'birth_date': birthDate?.toIso8601String(),
      'confirmed': isConfirmed,
      'confirmation_token': confirmationToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PatientModel(id: $id, name: $name, email: $email, isConfirmed: $isConfirmed)';
  }
}
