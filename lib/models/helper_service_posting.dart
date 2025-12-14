import 'package:flutter/material.dart';
import '../../localization_manager.dart';

class HelperServicePosting {
  final String id;
  final String helperId;
  final String helperName;
  final String title;
  final String description;
  final List<String> skills;
  final String experienceLevel;
  final double hourlyRate;
  final String availability; // 'full-time', 'part-time', 'weekends', 'flexible'
  final List<String> serviceAreas; // locations where helper can work
  final DateTime createdDate;
  final DateTime? expiresAt; // When the service posting expires
  final String status; // 'active', 'paused', 'inactive'
  final int viewsCount;
  final int contactsCount;

  HelperServicePosting({
    required this.id,
    required this.helperId,
    required this.helperName,
    required this.title,
    required this.description,
    required this.skills,
    required this.experienceLevel,
    required this.hourlyRate,
    required this.availability,
    required this.serviceAreas,
    required this.createdDate,
    required this.status,
    this.expiresAt,
    this.viewsCount = 0,
    this.contactsCount = 0,
  });

  String formatRate() {
    return '₱${hourlyRate.toStringAsFixed(0)}/hour';
  }

  String formatCreatedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdDate).inDays;

    if (difference == 0) return 'Created today';
    if (difference == 1) return 'Created yesterday';
    if (difference < 7) return 'Created $difference days ago';
    return '${LocalizationManager.translate('created')} ${(difference / 7).floor()} ${LocalizationManager.translate('week_ago')}';
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'inactive':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get statusDisplayText {
    switch (status) {
      case 'active':
        return LocalizationManager.translate('active');
      case 'paused':
        return LocalizationManager.translate('paused');
      case 'inactive':
        return LocalizationManager.translate('status_inactive');
      default:
        return status;
    }
  }

  String get primaryExpertise => skills.isNotEmpty ? skills.first : '';

  String get expertiseText {
    if (skills.isEmpty) return '';
    if (skills.length == 1) return skills.first;
    if (skills.length == 2) return '${skills.first} & ${skills.last}';
    return '${skills.first} +${skills.length - 1} more';
  }

  // Keep the old getters for backward compatibility
  String get primarySkill => primaryExpertise;
  String get skillsText => expertiseText;

  String get serviceAreasText {
    if (serviceAreas.isEmpty) return '';
    if (serviceAreas.length == 1) return serviceAreas.first;
    if (serviceAreas.length == 2) {
      return '${serviceAreas.first} & ${serviceAreas.last}';
    }
    return '${serviceAreas.first} +${serviceAreas.length - 1} ${LocalizationManager.translate('more')}';
  }
}
