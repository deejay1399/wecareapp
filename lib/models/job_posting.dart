import 'employer.dart';

class JobPosting {
  final String id;
  final String employerId;
  Employer? employer;
  final String title;
  final String description;
  final String municipality;
  final String barangay;
  final double salary;
  final String paymentFrequency;
  final List<String> requiredSkills;
  final String
  status; // 'active', 'paused', 'filled', 'in_progress', 'completed', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int applicationsCount;
  final String? assignedHelperId; // Helper who got the job
  final String? assignedHelperName; // Helper's name for easy reference

  JobPosting({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.municipality,
    required this.barangay,
    required this.salary,
    required this.paymentFrequency,
    required this.requiredSkills,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.applicationsCount = 0,
    this.employer,
    this.assignedHelperId,
    this.assignedHelperName,
  });

  // Status check helpers
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isFilled => status == 'filled';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isClosed => status == 'closed';

  // Helper to check if job is available for applications
  bool get isAvailableForApplications => status == 'active';

  // Helper to check if job is actively being worked on
  bool get isActivelyWorked => status == 'in_progress';

  // Helper to check if job can be marked as complete
  bool get canBeCompleted => status == 'in_progress';

  String get statusDisplayText {
    switch (status) {
      case 'active':
        return 'Open for Applications';
      case 'paused':
        return 'Paused';
      case 'filled':
        return 'Position Filled';
      case 'in_progress':
        return 'Work in Progress';
      case 'completed':
        return 'Completed';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown Status';
    }
  }

  factory JobPosting.fromMap(Map<String, dynamic> map) {
    return JobPosting(
      id: map['id'] as String? ?? '',
      employerId: map['employer_id'] as String? ?? '',
      employer: map['employers'] != null
          ? Employer.fromMap(map['employers'] as Map<String, dynamic>)
          : null,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      municipality: map['municipality'] as String? ?? '',
      barangay: map['barangay'] as String? ?? '',
      salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
      paymentFrequency: map['payment_frequency'] as String? ?? '',
      requiredSkills:
          (map['required_skills'] as List?)?.map((e) => e as String).toList() ??
          [],
      status: map['status'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      applicationsCount: map['applications_count'] as int? ?? 0,
      assignedHelperId: map['assigned_helper_id'] as String?,
      assignedHelperName: map['assigned_helper_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employer_id': employerId,
      'title': title,
      'description': description,
      'municipality': municipality,
      'barangay': barangay,
      'salary': salary,
      'payment_frequency': paymentFrequency,
      'required_skills': requiredSkills,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'assigned_helper_id': assignedHelperId,
      'assigned_helper_name': assignedHelperName,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'employer_id': employerId,
      'title': title,
      'description': description,
      'municipality': municipality,
      'barangay': barangay,
      'salary': salary,
      'payment_frequency': paymentFrequency,
      'required_skills': requiredSkills,
      'status': status,
      'assigned_helper_id': assignedHelperId,
      'assigned_helper_name': assignedHelperName,
    };
  }

  JobPosting copyWith({
    String? id,
    String? employerId,
    Employer? employer,
    String? title,
    String? description,
    String? municipality,
    String? barangay,
    double? salary,
    String? paymentFrequency,
    List<String>? requiredSkills,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? applicationsCount,
    String? assignedHelperId,
    String? assignedHelperName,
  }) {
    return JobPosting(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      employer: employer ?? this.employer,
      title: title ?? this.title,
      description: description ?? this.description,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      salary: salary ?? this.salary,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      assignedHelperId: assignedHelperId ?? this.assignedHelperId,
      assignedHelperName: assignedHelperName ?? this.assignedHelperName,
    );
  }

  // Legacy property getters for backward compatibility
  String get location => barangay;
  String get salaryPeriod => paymentFrequency;
  DateTime get postedDate => createdAt;
}
