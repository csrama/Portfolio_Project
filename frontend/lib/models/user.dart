class User {
  final String id;
  final String email;
  final String fullName;
  final String userType; // 'user' or 'caregiver'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? dependentIds; 
  
  // Constructor
  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    this.createdAt,
    this.updatedAt,
    this.dependentIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      dependentIds: json['dependent_ids'] != null
          ? List<String>.from(json['dependent_ids'])
          : null,
    );
  }

  // ============ Object → JSON ============
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'user_type': userType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'dependent_ids': dependentIds,
    };
  }

  bool get isCaregiver => userType == 'caregiver';
  bool get isPatient => userType == 'user';
  
  // نسخ الكائن مع تغيير بعض الخصائص
  User copyWith({
    String? email,
    String? fullName,
    List<String>? dependentIds,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      userType: userType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dependentIds: dependentIds ?? this.dependentIds,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName)';
}
