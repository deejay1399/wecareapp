import 'package:flutter/material.dart';
import '../../localization_manager.dart';

class Application {
  final String id;
  final String jobId;
  final String jobTitle;
  final String helperId;
  final String helperName;
  final String helperProfileImage;
  final String helperLocation;
  final String coverLetter;
  final DateTime appliedDate;
  final String
  status; // 'pending', 'accepted', 'rejected', 'withdrawn', 'completed'
  final String? helperPhone;
  final String? helperEmail;
  final List<String> helperSkills;
  final String helperExperience;
  final DateTime? startTime;
  final DateTime? endTime;

  Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.helperId,
    required this.helperName,
    this.helperProfileImage = '',
    required this.helperLocation,
    required this.coverLetter,
    required this.appliedDate,
    required this.status,
    this.helperPhone,
    this.helperEmail,
    required this.helperSkills,
    required this.helperExperience,
    this.startTime,
    this.endTime,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';
  bool get isCompleted => status == 'completed';

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return LocalizationManager.translate('pending_review');
      case 'accepted':
        return LocalizationManager.translate('accepted');
      case 'rejected':
        return LocalizationManager.translate('rejected');
      case 'withdrawn':
        return LocalizationManager.translate('withdrawn');
      case 'completed':
        return LocalizationManager.translate('completed');
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      case 'withdrawn':
        return const Color(0xFF9E9E9E);
      case 'completed':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String formatAppliedDate() {
    final now = DateTime.now();
    final difference = now.difference(appliedDate).inDays;

    if (difference == 0) {
      return LocalizationManager.translate('today');
    } else if (difference == 1) {
      return LocalizationManager.translate('yesterday');
    } else if (difference < 7) {
      return LocalizationManager.translate(
        'days_ago',
        params: {'count': difference.toString()},
      );
    } else if (difference < 30) {
      return LocalizationManager.translate(
        'weeks_ago',
        params: {'count': (difference / 7).floor().toString()},
      );
    } else {
      return LocalizationManager.translate(
        'months_ago',
        params: {'count': (difference / 30).floor().toString()},
      );
    }
  }
}
