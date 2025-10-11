class Helper {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int age;
  final String skill;
  final String experience;
  final String municipality;
  final String barangay;
  final String? barangayClearanceBase64;
  final String? profilePictureBase64;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Helper({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.age,
    required this.skill,
    required this.experience,
    required this.municipality,
    required this.barangay,
    this.barangayClearanceBase64,
    this.profilePictureBase64,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Helper.fromMap(Map<String, dynamic> map) {
    return Helper(
      id: map['id'] as String? ?? '',
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      skill: map['skill'] as String? ?? '',
      experience: map['experience'] as String? ?? '',
      municipality: map['municipality'] as String? ?? '',
      barangay: map['barangay'] as String? ?? '',
      barangayClearanceBase64: map['barangay_clearance_base64'] as String?,
      profilePictureBase64: map['profile_picture_base64'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'age': age,
      'skill': skill,
      'experience': experience,
      'municipality': municipality,
      'barangay': barangay,
      'barangay_clearance_base64': barangayClearanceBase64,
      'profile_picture_base64': profilePictureBase64,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
}
