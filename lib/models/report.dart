class Report {
  final String id;
  final String reportedBy;
  final String reportedUser;
  final String reason;
  final String type; // 'job_posting', 'service_posting', 'job_application'
  final String
  referenceId; // ID of the job posting, service posting, or application
  final String description;
  final String status; // 'pending', 'under_review', 'resolved', 'dismissed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNotes; // Notes from admin
  final String? reporterName; // Name of the person who reported
  final String? reportedUserName; // Name of the reported user

  Report({
    required this.id,
    required this.reportedBy,
    required this.reportedUser,
    required this.reason,
    required this.type,
    required this.referenceId,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.adminNotes,
    this.reporterName,
    this.reportedUserName,
  });

  // Factory constructor to create Report from JSON
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reportedBy: json['reported_by'] as String,
      reportedUser: json['reported_user'] as String,
      reason: json['reason'] as String,
      type: json['type'] as String,
      referenceId: json['reference_id'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      adminNotes: json['admin_notes'] as String?,
      reporterName: json['reporter_name'] as String?,
      reportedUserName: json['reported_user_name'] as String?,
    );
  }

  // Convert Report to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reported_by': reportedBy,
      'reported_user': reportedUser,
      'reason': reason,
      'type': type,
      'reference_id': referenceId,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'reporter_name': reporterName,
      'reported_user_name': reportedUserName,
    };
  }
}
