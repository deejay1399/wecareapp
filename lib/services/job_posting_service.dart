import '../models/job_posting.dart';
import '../services/supabase_service.dart';

class JobPostingService {
  static const String _tableName = 'job_postings';

  /// Create a new job posting
  static Future<JobPosting> createJobPosting({
    required String employerId,
    required String title,
    required String description,
    required double salary,
    required String paymentFrequency,
    required String municipality,
    required String barangay,
    required List<String> requiredSkills,
  }) async {
    try {
      final jobPosting = JobPosting(
        id: '',
        employerId: employerId,
        title: title,
        description: description,
        municipality: municipality,
        barangay: barangay,
        salary: salary,
        paymentFrequency: paymentFrequency,
        requiredSkills: requiredSkills,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final response = await SupabaseService.client
          .from(_tableName)
          .insert(jobPosting.toInsertMap())
          .select()
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create job posting: $e');
    }
  }

  /// Assign helper to job (when application is accepted)
  static Future<JobPosting> assignHelperToJob({
    required String jobId,
    required String helperId,
    required String helperName,
  }) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({
            'status': 'in_progress',
            'assigned_helper_id': helperId,
            'assigned_helper_name': helperName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .select()
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('Failed to assign helper to job: $e');
    }
  }

  /// Mark job as completed
  static Future<JobPosting> markJobAsCompleted(String jobId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .select()
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('Failed to mark job as completed: $e');
    }
  }

  /// Get jobs that are in progress for a specific helper
  static Future<List<JobPosting>> getInProgressJobsForHelper(
    String helperId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('assigned_helper_id', helperId)
          .eq('status', 'in_progress')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch in-progress jobs for helper: $e');
    }
  }

  /// Get jobs that are in progress for a specific employer
  static Future<List<JobPosting>> getInProgressJobsForEmployer(
    String employerId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('employer_id', employerId)
          .eq('status', 'in_progress')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch in-progress jobs for employer: $e');
    }
  }

  /// Get completed jobs for rating purposes
  static Future<List<JobPosting>> getCompletedJobsForUser({
    required String userId,
    required String userType, // 'employer' or 'helper'
  }) async {
    try {
      String filterField = userType == 'employer'
          ? 'employer_id'
          : 'assigned_helper_id';

      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq(filterField, userId)
          .eq('status', 'completed')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed jobs: $e');
    }
  }

  /// Get all job postings for a specific employer
  static Future<List<JobPosting>> getJobPostingsByEmployer(
    String employerId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select(
            '*, employers(id, age, first_name, last_name, profile_picture_base64)',
          )
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        // Map employer full name from nested employers object
        if (data['employers'] != null) {
          final employerData = data['employers'];
          data['employer'] = {
            'id': employerData['id'],
            'first_name': employerData['first_name'],
            'age': employerData['age'],
            'last_name': employerData['last_name'],
            'profile_picture_base64': employerData['profile_picture_base64'],
            'fullName':
                '${employerData['first_name']} ${employerData['last_name']}'
                    .trim(),
          };
        }
        return JobPosting.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch job postings: $e');
    }
  }

  /// Get all active job postings
  static Future<List<JobPosting>> getActiveJobPostings() async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active job postings: $e');
    }
  }

  /// Get job postings that match helper's skills and location
  static Future<List<JobPosting>> getMatchedJobsForHelper({
    required String helperSkills,
    required String helperBarangay,
    int limit = 2,
  }) async {
    try {
      // Convert helper skills string to list
      final skillsList = helperSkills
          .split(',')
          .map((skill) => skill.trim().toLowerCase())
          .where((skill) => skill.isNotEmpty)
          .toList();

      if (skillsList.isEmpty) {
        // If no skills, just return recent jobs in same barangay
        final response = await SupabaseService.client
            .from(_tableName)
            .select()
            .eq('status', 'active')
            .eq('barangay', helperBarangay)
            .order('created_at', ascending: false)
            .limit(limit);

        return (response as List)
            .map((data) => JobPosting.fromMap(data))
            .toList();
      }

      // Get all active jobs
      final allJobsResponse = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final allJobs = (allJobsResponse as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();

      // Filter and score jobs based on skill matching
      final List<MapEntry<JobPosting, int>> scoredJobs = [];

      for (final job in allJobs) {
        int matchScore = 0;

        // Check skill matches
        for (final requiredSkill in job.requiredSkills) {
          final normalizedRequired = requiredSkill.toLowerCase().trim();
          for (final helperSkill in skillsList) {
            if (normalizedRequired.contains(helperSkill) ||
                helperSkill.contains(normalizedRequired)) {
              matchScore += 3; // High score for skill match
            }
          }
        }

        // Bonus points for same barangay
        if (job.barangay == helperBarangay) {
          matchScore += 2;
        }

        // Only include jobs with some match
        if (matchScore > 0) {
          scoredJobs.add(MapEntry(job, matchScore));
        }
      }

      // Sort by score and take top matches
      scoredJobs.sort((a, b) => b.value.compareTo(a.value));

      return scoredJobs.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Failed to fetch matched jobs: $e');
    }
  }

  /// Get job postings by barangay
  static Future<List<JobPosting>> getJobPostingsByBarangay(
    String barangay,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('barangay', barangay)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch job postings by barangay: $e');
    }
  }

  /// Update job posting
  static Future<JobPosting> updateJobPosting(JobPosting jobPosting) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update(jobPosting.toMap())
          .eq('id', jobPosting.id)
          .select()
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update job posting: $e');
    }
  }

  /// Update job posting status
  static Future<JobPosting> updateJobPostingStatus(
    String jobId,
    String status,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update({'status': status})
          .eq('id', jobId)
          .select()
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update job posting status: $e');
    }
  }

  /// Delete job posting
  static Future<void> deleteJobPosting(String jobId) async {
    try {
      await SupabaseService.client.from(_tableName).delete().eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to delete job posting: $e');
    }
  }

  /// Get job posting by ID
  static Future<JobPosting> getJobPostingById(String jobId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', jobId)
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch job posting: $e');
    }
  }

  /// Get recent job postings (latest 20 jobs)
  static Future<List<JobPosting>> getRecentJobPostings({
    int limit = 100,
  }) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select(
            '*, employers(id, age, first_name, last_name, profile_picture_base64)',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(limit);
      print("response.length");
      print(response);
      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent job postings: $e');
    }
  }

  // In your JobPostingService
  static Future<List<JobPosting>> getJobPostingsByLocation({
    String? municipality,
    String? barangay,
    int limit = 50,
  }) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);

      var jobs = (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();

      // Filter client-side if Supabase Dart doesn't support .eq()
      // if (municipality != null && municipality.isNotEmpty) {
      //   jobs = jobs
      //       .where(
      //         (job) =>
      //             job.municipality.toLowerCase() == municipality.toLowerCase(),
      //       )
      //       .toList();
      // }
      // if (barangay != null && barangay.isNotEmpty) {
      //   jobs = jobs
      //       .where(
      //         (job) => job.barangay.toLowerCase() == barangay.toLowerCase(),
      //       )
      //       .toList();
      // }

      if (municipality != null && municipality.isNotEmpty) {
        jobs = jobs
            .where(
              (job) =>
                  (job.municipality ?? '').toLowerCase() ==
                  municipality.toLowerCase(),
            )
            .toList();
      }

      if (barangay != null && barangay.isNotEmpty) {
        jobs = jobs
            .where(
              (job) =>
                  (job.barangay ?? '').toLowerCase() == barangay.toLowerCase(),
            )
            .toList();
      }

      return jobs;
    } catch (e) {
      throw Exception('Failed to fetch job postings by location: $e');
    }
  }

  static Future<List<JobPosting>> getBestMatchesForHelper({
    required String helperSkills,
    String? municipality,
    String? barangay,
    int limit = 10,
  }) async {
    try {
      // Convert helper skills string to list
      final skillsList = helperSkills
          .split(',')
          .map((skill) => skill.trim().toLowerCase())
          .where((skill) => skill.isNotEmpty)
          .toList();

      // Get all active jobs
      final allJobsResponse = await SupabaseService.client
          .from(_tableName)
          // .select()
          .select(
            '*, employers(id, first_name, last_name, profile_picture_base64)',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false);

      var allJobs = (allJobsResponse as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();

      // Apply location filter if provided
      if (municipality != null && municipality.isNotEmpty) {
        allJobs = allJobs
            .where(
              (job) =>
                  (job.municipality ?? '').toLowerCase() ==
                  municipality.toLowerCase(),
            )
            .toList();
      }
      if (barangay != null && barangay.isNotEmpty) {
        allJobs = allJobs
            .where(
              (job) =>
                  (job.barangay ?? '').toLowerCase() == barangay.toLowerCase(),
            )
            .toList();
      }

      // If no skills, return recent jobs in filtered location
      if (skillsList.isEmpty) {
        return allJobs.take(limit).toList();
      }

      // Filter and score jobs based on skill matching and location
      final List<MapEntry<JobPosting, int>> scoredJobs = [];

      for (final job in allJobs) {
        int matchScore = 0;

        // Check skill matches (high priority)
        for (final requiredSkill in job.requiredSkills) {
          final normalizedRequired = requiredSkill.toLowerCase().trim();
          for (final helperSkill in skillsList) {
            if (normalizedRequired.contains(helperSkill) ||
                helperSkill.contains(normalizedRequired)) {
              matchScore += 5; // High score for skill match
            }
          }
        }

        // Location matching (medium priority)
        if (barangay != null &&
            barangay.isNotEmpty &&
            (job.barangay ?? '').toLowerCase() == barangay.toLowerCase()) {
          matchScore += 3; // Bonus for same barangay
        }

        // Recent jobs get slight boost (low priority)
        final daysSincePosted = DateTime.now().difference(job.createdAt).inDays;
        if (daysSincePosted <= 1) {
          matchScore += 2; // Bonus for jobs posted today/yesterday
        } else if (daysSincePosted <= 7) {
          matchScore += 1; // Small bonus for jobs posted this week
        }

        // Only include jobs with some match
        if (matchScore > 0) {
          scoredJobs.add(MapEntry(job, matchScore));
        }
      }

      // Sort by score and take top matches
      scoredJobs.sort((a, b) => b.value.compareTo(a.value));

      return scoredJobs.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Failed to fetch best matches: $e');
    }
  }

  /// Get best matching jobs for a helper based on skills and location
  // static Future<List<JobPosting>> getBestMatchesForHelper({
  //   required String helperSkills,
  //   required String helperBarangay,
  //   int limit = 10,
  // }) async {
  //   try {
  //     // Convert helper skills string to list
  //     final skillsList = helperSkills
  //         .split(',')
  //         .map((skill) => skill.trim().toLowerCase())
  //         .where((skill) => skill.isNotEmpty)
  //         .toList();

  //     if (skillsList.isEmpty) {
  //       // If no skills, return recent jobs in same barangay
  //       final response = await SupabaseService.client
  //           .from(_tableName)
  //           .select()
  //           .eq('status', 'active')
  //           .eq('barangay', helperBarangay)
  //           .order('created_at', ascending: false)
  //           .limit(limit);

  //       return (response as List)
  //           .map((data) => JobPosting.fromMap(data))
  //           .toList();
  //     }

  //     // Get all active jobs
  //     final allJobsResponse = await SupabaseService.client
  //         .from(_tableName)
  //         .select()
  //         .eq('status', 'active')
  //         .order('created_at', ascending: false);

  //     final allJobs = (allJobsResponse as List)
  //         .map((data) => JobPosting.fromMap(data))
  //         .toList();

  //     // Filter and score jobs based on skill matching and location
  //     final List<MapEntry<JobPosting, int>> scoredJobs = [];

  //     for (final job in allJobs) {
  //       int matchScore = 0;

  //       // Check skill matches (high priority)
  //       for (final requiredSkill in job.requiredSkills) {
  //         final normalizedRequired = requiredSkill.toLowerCase().trim();
  //         for (final helperSkill in skillsList) {
  //           if (normalizedRequired.contains(helperSkill) ||
  //               helperSkill.contains(normalizedRequired)) {
  //             matchScore += 5; // High score for skill match
  //           }
  //         }
  //       }

  //       // Location matching (medium priority)
  //       if (job.barangay == helperBarangay) {
  //         matchScore += 3; // Bonus for same barangay
  //       }

  //       // Recent jobs get slight boost (low priority)
  //       final daysSincePosted = DateTime.now().difference(job.createdAt).inDays;
  //       if (daysSincePosted <= 1) {
  //         matchScore += 2; // Bonus for jobs posted today/yesterday
  //       } else if (daysSincePosted <= 7) {
  //         matchScore += 1; // Small bonus for jobs posted this week
  //       }

  //       // Only include jobs with some match
  //       if (matchScore > 0) {
  //         scoredJobs.add(MapEntry(job, matchScore));
  //       }
  //     }

  //     // Sort by score and take top matches
  //     scoredJobs.sort((a, b) => b.value.compareTo(a.value));

  //     return scoredJobs.take(limit).map((entry) => entry.key).toList();
  //   } catch (e) {
  //     throw Exception('Failed to fetch best matches: $e');
  //   }
  // }

  /// Get jobs posted today for "Recent" section emphasis
  static Future<List<JobPosting>> getTodaysJobPostings() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('status', 'active')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch today\'s job postings: $e');
    }
  }

  /// Get trending jobs (jobs with most applications in last 7 days)
  static Future<List<JobPosting>> getTrendingJobPostings({
    int limit = 10,
  }) async {
    try {
      // Get jobs from last 7 days with application counts
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await SupabaseService.client
          .from(_tableName)
          .select('''
            *,
            applications (
              id
            )
          ''')
          .eq('status', 'active')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      final jobsWithCounts = (response as List).map((data) {
        final applicationCount = (data['applications'] as List).length;
        final job = JobPosting.fromMap(data);
        return MapEntry(job, applicationCount);
      }).toList();

      // Sort by application count (trending), then by creation date
      jobsWithCounts.sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) return countComparison;
        return b.key.createdAt.compareTo(a.key.createdAt);
      });

      return jobsWithCounts.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Failed to fetch trending job postings: $e');
    }
  }

  static Future<List<JobPosting>> getJobPostingsWithEmployer({
    int limit = 50,
  }) async {
    final response = await SupabaseService.client
        .from('job_postings')
        .select('*, employers(*)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((data) => JobPosting.fromMap(data)).toList();
  }
}
