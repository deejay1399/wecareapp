import 'employer.dart';
import 'helper.dart';

class JobPosting {
  final String id;
  final String employerId;
  Employer? employer;
  Helper? assignedHelper;
  final String title;
  final String description;
  final String municipality;
  final String barangay;
  final double salary;
  final String paymentFrequency;
  final List<String> requiredSkills;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt; // New field for expiration date
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
    this.expiresAt,
    this.applicationsCount = 0,
    this.employer,
    this.assignedHelper,
    this.assignedHelperId,
    this.assignedHelperName,
  });

  // ---------- STATUS HELPERS ----------
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isFilled => status == 'filled';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isClosed => status == 'closed';
  bool get isAvailableForApplications => status == 'active';
  bool get isActivelyWorked => status == 'in_progress';
  bool get canBeCompleted => status == 'in_progress';
  bool get isExpired {
    if (expiresAt == null) return false;
    // expiresAt is stored in local time, compare with local time
    final now = DateTime.now();
    final isExpired = now.isAfter(expiresAt!);
    if (expiresAt != null) {
      print(
        'DEBUG isExpired: now=$now, expiresAt=$expiresAt, isExpired=$isExpired',
      );
    }
    return isExpired;
  }

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

  // ---------- SUPABASE MAP CONVERSION ----------
  factory JobPosting.fromMap(Map<String, dynamic> map) {
    final employersData = map['employers'] ?? map['employer'];
    final helpersData = map['helpers'] ?? map['assigned_helper'];

    // Build Employer + Helper if nested data is included
    final employer = employersData is Map<String, dynamic>
        ? Employer.fromMap(employersData)
        : null;

    final helper = helpersData is Map<String, dynamic>
        ? Helper.fromMap(helpersData)
        : null;

    return JobPosting(
      id: map['id']?.toString() ?? '',
      employerId: map['employer_id']?.toString() ?? '',
      employer: employer,
      assignedHelper: helper,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      municipality: map['municipality'] ?? '',
      barangay: map['barangay'] ?? '',
      salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
      paymentFrequency: map['payment_frequency'] ?? '',
      requiredSkills: (map['required_skills'] is List)
          ? (map['required_skills'] as List).map((e) => e.toString()).toList()
          : [],
      status: map['status'] ?? '',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      expiresAt: _parseDateNullable(map['expires_at']),
      applicationsCount: map['applications_count'] ?? 0,
      assignedHelperId: map['assigned_helper_id']?.toString() ?? helper?.id,
      assignedHelperName: map['assigned_helper_name'] ?? helper?.fullName,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ---------- JSON CONVERSIONS ----------
  factory JobPosting.fromJson(Map<String, dynamic> json) =>
      JobPosting.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  // ---------- MAP OUTPUT ----------
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
      'expires_at': expiresAt?.toIso8601String(),
      'applications_count': applicationsCount,
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
      'expires_at': expiresAt?.toIso8601String(),
      'assigned_helper_id': assignedHelperId,
      'assigned_helper_name': assignedHelperName,
    };
  }

  // ---------- COPY ----------
  JobPosting copyWith({
    String? id,
    String? employerId,
    Employer? employer,
    Helper? assignedHelper,
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
    DateTime? expiresAt,
    int? applicationsCount,
    String? assignedHelperId,
    String? assignedHelperName,
  }) {
    return JobPosting(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      employer: employer ?? this.employer,
      assignedHelper: assignedHelper ?? this.assignedHelper,
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
      expiresAt: expiresAt ?? this.expiresAt,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      assignedHelperId: assignedHelperId ?? this.assignedHelperId,
      assignedHelperName: assignedHelperName ?? this.assignedHelperName,
    );
  }

  // ---------- LEGACY ----------
  String get location => barangay;
  String get salaryPeriod => paymentFrequency;
  DateTime get postedDate => createdAt;

  // ---------- UTILITY ----------
  @override
  String toString() =>
      'JobPosting(id: $id, title: $title, employerId: $employerId, helper: $assignedHelperName, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is JobPosting && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
