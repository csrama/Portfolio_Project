class Dependent {
  final String id;
  final String fullName;
  final String relationship;
  final String? caregiverId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Dependent({
    required this.id,
    required this.fullName,
    required this.relationship,
    this.caregiverId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Dependent.fromJson(Map<String, dynamic> json) {
    return Dependent(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      caregiverId: json['caregiver_id']?.toString(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'relationship': relationship,
      'caregiver_id': caregiverId,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Dependent(id: $id, name: $fullName)';
}
