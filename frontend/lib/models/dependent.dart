import 'dart:convert';

class Dependent {
  final String id;
  final String caregiverUserId;
  final String fullName;
  final DateTime? dateOfBirth;
  final String relationship;
  final String? profileImageUrl;
  final List<String> medicalConditions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dependent({
    required this.id,
    required this.caregiverUserId,
    required this.fullName,
    this.dateOfBirth,
    required this.relationship,
    this.profileImageUrl,
    this.medicalConditions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dependent.fromMap(Map<String, dynamic> map) {
    return Dependent(
      id: map['id'].toString(),
      caregiverUserId: (map['caregiver_user_id'] ?? '').toString(),
      fullName: (map['full_name'] ?? map['user_full_name'] ?? '').toString(),
      dateOfBirth: map['date_of_birth'] != null ? DateTime.tryParse(map['date_of_birth'].toString()) : null,
      relationship: (map['relationship'] ?? '').toString(),
      profileImageUrl: map['profile_image_url']?.toString(),
      medicalConditions: map['medical_conditions'] != null ? List<String>.from(map['medical_conditions']) : [],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caregiver_user_id': caregiverUserId,
      'full_name': fullName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'relationship': relationship,
      'profile_image_url': profileImageUrl,
      'medical_conditions': medicalConditions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory Dependent.fromJson(String source) => Dependent.fromMap(json.decode(source));
}
