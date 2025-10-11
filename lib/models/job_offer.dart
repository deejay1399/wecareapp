class JobOffer {
  final String id;
  final String conversationId;
  final String employerId;
  final String helperId;
  final String servicePostingId; // Reference to the helper's service posting
  final String title;
  final String description;
  final double salary;
  final String paymentFrequency;
  final String municipality;
  final String location;
  final List<String> requiredSkills;
  final JobOfferStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? rejectionReason;

  JobOffer({
    required this.id,
    required this.conversationId,
    required this.employerId,
    required this.helperId,
    required this.servicePostingId,
    required this.title,
    required this.description,
    required this.salary,
    required this.paymentFrequency,
    required this.municipality,
    required this.location,
    required this.requiredSkills,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.rejectionReason,
  });

  factory JobOffer.fromMap(Map<String, dynamic> map) {
    return JobOffer(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      employerId: map['employer_id'] as String,
      helperId: map['helper_id'] as String,
      servicePostingId: map['service_posting_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      salary: (map['salary'] as num).toDouble(),
      paymentFrequency: map['payment_frequency'] as String,
      municipality: map['municipality'] as String,
      location: map['location'] as String,
      requiredSkills: List<String>.from(map['required_skills'] as List),
      status: JobOfferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JobOfferStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'employer_id': employerId,
      'helper_id': helperId,
      'service_posting_id': servicePostingId,
      'title': title,
      'description': description,
      'salary': salary,
      'payment_frequency': paymentFrequency,
      'municipality': municipality,
      'location': location,
      'required_skills': requiredSkills,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'conversation_id': conversationId,
      'employer_id': employerId,
      'helper_id': helperId,
      'service_posting_id': servicePostingId,
      'title': title,
      'description': description,
      'salary': salary,
      'payment_frequency': paymentFrequency,
      'municipality': municipality,
      'location': location,
      'required_skills': requiredSkills,
      'status': status.name,
      'rejection_reason': rejectionReason,
    };
  }

  JobOffer copyWith({
    String? id,
    String? conversationId,
    String? employerId,
    String? helperId,
    String? servicePostingId,
    String? title,
    String? description,
    double? salary,
    String? paymentFrequency,
    String? municipality,
    String? location,
    List<String>? requiredSkills,
    JobOfferStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? rejectionReason,
  }) {
    return JobOffer(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      employerId: employerId ?? this.employerId,
      helperId: helperId ?? this.helperId,
      servicePostingId: servicePostingId ?? this.servicePostingId,
      title: title ?? this.title,
      description: description ?? this.description,
      salary: salary ?? this.salary,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      municipality: municipality ?? this.municipality,
      location: location ?? this.location,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // Status helpers
  bool get isPending => status == JobOfferStatus.pending;
  bool get isAccepted => status == JobOfferStatus.accepted;
  bool get isRejected => status == JobOfferStatus.rejected;
  bool get isExpired => status == JobOfferStatus.expired;

  String get statusDisplayText {
    switch (status) {
      case JobOfferStatus.pending:
        return 'Pending Response';
      case JobOfferStatus.accepted:
        return 'Accepted';
      case JobOfferStatus.rejected:
        return 'Rejected';
      case JobOfferStatus.expired:
        return 'Expired';
    }
  }

  String get formattedSalary => '₱${salary.toStringAsFixed(2)}';
}

enum JobOfferStatus { pending, accepted, rejected, expired }
