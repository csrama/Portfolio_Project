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
      caregiverUserId: map['caregiver_user_id'].toString(),
      fullName: map['full_name'] ?? '',
      dateOfBirth: map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth']) : null,
      relationship: map['relationship'] ?? '',
      profileImageUrl: map['profile_image_url'],
      medicalConditions: List<String>.from(map['medical_conditions'] ?? []),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
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

