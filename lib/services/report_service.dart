import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportService {
  static const String _tableName = 'reports';

  /// Submit a new report
  static Future<Report> submitReport({
    required String reportedBy,
    required String reportedUser,
    required String reason,
    required String type, // 'job_posting', 'service_posting', 'job_application'
    required String referenceId,
    required String description,
    String? reporterName,
    String? reportedUserName,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final id = const Uuid().v4();
      final now = DateTime.now();

      // If reported_user_name is empty or not provided, fetch it from the database
      String finalReportedUserName = reportedUserName ?? '';
      if (finalReportedUserName.isEmpty) {
        // Try to fetch from employers table first
        final employerResponse = await supabase
            .from('employers')
            .select('first_name, last_name')
            .eq('id', reportedUser)
            .maybeSingle();

        if (employerResponse != null) {
          final firstName = employerResponse['first_name'] ?? '';
          final lastName = employerResponse['last_name'] ?? '';
          finalReportedUserName = '$firstName $lastName'.trim();
        } else {
          // If not found in employers, try helpers table
          final helperResponse = await supabase
              .from('helpers')
              .select('first_name, last_name')
              .eq('id', reportedUser)
              .maybeSingle();

          if (helperResponse != null) {
            final firstName = helperResponse['first_name'] ?? '';
            final lastName = helperResponse['last_name'] ?? '';
            finalReportedUserName = '$firstName $lastName'.trim();
          }
        }
      }

      final reportData = {
        'id': id,
        'reported_by': reportedBy,
        'reported_user': reportedUser,
        'reason': reason,
        'type': type,
        'reference_id': referenceId,
        'description': description,
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'reporter_name': reporterName,
        'reported_user_name': finalReportedUserName,
      };

      print('DEBUG: Submitting report with data: $reportData');

      final response = await supabase.from(_tableName).insert(reportData);

      print('DEBUG: Report submitted successfully. Response: $response');

      return Report(
        id: id,
        reportedBy: reportedBy,
        reportedUser: reportedUser,
        reason: reason,
        type: type,
        referenceId: referenceId,
        description: description,
        status: 'pending',
        createdAt: now,
        reporterName: reporterName,
        reportedUserName: finalReportedUserName,
      );
    } catch (e) {
      print('DEBUG: Error submitting report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports (for admin)
  static Future<List<Report>> getAllReports({
    String?
    status, // Filter by status: 'pending', 'under_review', 'resolved', 'dismissed'
  }) async {
    try {
      final supabase = Supabase.instance.client;

      var query = supabase.from(_tableName).select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      print(
        'DEBUG: Retrieved ${(response as List).length} reports from database',
      );

      return (response as List)
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching reports: $e');
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get reports for a specific reported user
  static Future<List<Report>> getReportsForUser(String reportedUserId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(_tableName)
          .select()
          .eq('reported_user', reportedUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get reports submitted by a user
  static Future<List<Report>> getReportsSubmittedByUser(
    String reportedByUserId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(_tableName)
          .select()
          .eq('reported_by', reportedByUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get report by ID
  static Future<Report?> getReportById(String reportId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(_tableName)
          .select()
          .eq('id', reportId);

      if (response.isEmpty) {
        return null;
      }

      return Report.fromJson(response[0]);
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Update report status (admin only)
  static Future<void> updateReportStatus(
    String reportId,
    String newStatus,
    String? adminNotes,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from(_tableName)
          .update({
            'status': newStatus,
            'admin_notes': adminNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Get reports by type and reference ID
  static Future<List<Report>> getReportsByReference({
    required String type,
    required String referenceId,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(_tableName)
          .select()
          .eq('type', type)
          .eq('reference_id', referenceId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Check if user has already reported this reference
  static Future<bool> hasAlreadyReported({
    required String reportedBy,
    required String type,
    required String referenceId,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(_tableName)
          .select()
          .eq('reported_by', reportedBy)
          .eq('type', type)
          .eq('reference_id', referenceId);

      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check report status: $e');
    }
  }

  /// Get statistics for admin dashboard
  static Future<Map<String, dynamic>> getReportStatistics() async {
    try {
      final supabase = Supabase.instance.client;

      final totalReports = await supabase.from(_tableName).select('id');

      final pendingReports = await supabase
          .from(_tableName)
          .select('id')
          .eq('status', 'pending');

      final resolvedReports = await supabase
          .from(_tableName)
          .select('id')
          .eq('status', 'resolved');

      return {
        'total': (totalReports as List).length,
        'pending': (pendingReports as List).length,
        'resolved': (resolvedReports as List).length,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
}
