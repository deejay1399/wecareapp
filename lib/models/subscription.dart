class Subscription {
  final String id;
  final String userId;
  final String userType; // 'Employer' or 'Helper'
  final String planType; // 'starter', 'standard', 'premium'
  final String status; // 'paid', 'failed', 'pending'
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.userType,
    required this.planType,
    required this.status,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userType: map['user_type'] ?? '',
      planType: map['plan_type'] ?? '',
      status: map['status'] ?? 'pending',
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_type': userType,
      'plan_type': planType,
      'status': status,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Check if subscription is active based on status
  bool get isActive {
    return status == 'paid';
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isValidSubscription {
    return isActive && !isExpired;
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? userType,
    String? planType,
    String? status,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
