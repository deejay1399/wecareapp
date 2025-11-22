import '../models/job_posting.dart';
import '../services/supabase_service.dart';

class JobPostingService {
  static const String _tableName = 'job_postings';

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

  static Future<JobPosting> assignHelperToJob({
    required String jobId,
    required String helperId,
    required String helperName,
  }) async {
    try {
      print(
        'DEBUG JobPostingService: Fetching job posting before update - jobId: $jobId',
      );

      // First, get the current job posting to verify it exists and has valid data
      final currentJob = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', jobId)
          .single();

      print(
        'DEBUG JobPostingService: Current job posting status: ${currentJob['status']}',
      );
      print('DEBUG JobPostingService: Current job posting data: $currentJob');

      print(
        'DEBUG JobPostingService: Updating job posting status to "in_progress"',
      );

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

      print('DEBUG JobPostingService: Successfully assigned helper to job');
      return JobPosting.fromMap(response);
    } catch (e) {
      print('ERROR JobPostingService: Failed to assign helper to job: $e');
      throw Exception('Failed to assign helper to job: $e');
    }
  }

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

  static Future<List<JobPosting>> getInProgressJobsForHelper(
    String helperId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('assigned_helper_id', helperId)
          .eq('status', 'in progress')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch in-progress jobs for helper: $e');
    }
  }

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

  static Future<List<JobPosting>> getCompletedJobsForUser({
    required String userId,
    required String userType, // 'helper' or 'employer'
  }) async {
    final supabase = SupabaseService.client;

    try {
      dynamic response;

      if (userType == 'helper') {
        // Get jobs where the helper's application is completed.
        // Include assigned_helper_id and the nested assigned_helper relation
        // so JobPosting.fromMap can build the helper object and id.
        response = await supabase
            .from('applications')
            .select('''
            job_postings (
              id,
              employer_id,
              title,
              description,
              municipality,
              barangay,
              salary,
              payment_frequency,
              required_skills,
              status,
              assigned_helper_id,
              assigned_helper_name,
              assigned_helper:helpers(id, first_name, last_name, profile_picture_base64, created_at, updated_at),
              created_at,
              updated_at
            )
          ''')
            .eq('helper_id', userId)
            .eq('status', 'completed')
            .order('applied_at', ascending: false);
      } else {
        response = await supabase
            .from('applications')
            .select('''
            job_postings (
              id,
              employer_id,
              title,
              description,
              municipality,
              barangay,
              salary,
              payment_frequency,
              required_skills,
              status,
              assigned_helper_id,
              assigned_helper_name,
              assigned_helper:helpers(id, first_name, last_name, profile_picture_base64, created_at, updated_at),
              created_at,
              updated_at
            )
          ''')
            .eq('status', 'completed')
            .eq('job_postings.employer_id', userId)
            .order('applied_at', ascending: false);
      }

      if (response == null || response.isEmpty) return [];

      final jobs = (response as List)
          .map((app) => app['job_postings'])
          .where((job) => job != null)
          .map((job) => JobPosting.fromMap(job))
          .toList();

      return jobs;
    } catch (e) {
      throw Exception('Failed to load completed jobs: $e');
    }
  }

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

  static Future<List<JobPosting>> getMatchedJobsForHelper({
    required String helperSkills,
    required String helperBarangay,
    int limit = 2,
  }) async {
    try {
      final skillsList = helperSkills
          .split(',')
          .map((skill) => skill.trim().toLowerCase())
          .where((skill) => skill.isNotEmpty)
          .toList();

      if (skillsList.isEmpty) {
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

      final allJobsResponse = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final allJobs = (allJobsResponse as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();

      final List<MapEntry<JobPosting, int>> scoredJobs = [];

      for (final job in allJobs) {
        int matchScore = 0;

        for (final requiredSkill in job.requiredSkills) {
          final normalizedRequired = requiredSkill.toLowerCase().trim();
          for (final helperSkill in skillsList) {
            if (normalizedRequired.contains(helperSkill) ||
                helperSkill.contains(normalizedRequired)) {
              matchScore += 3;
            }
          }
        }
        if (job.barangay == helperBarangay) {
          matchScore += 2;
        }

        if (matchScore > 0) {
          scoredJobs.add(MapEntry(job, matchScore));
        }
      }

      scoredJobs.sort((a, b) => b.value.compareTo(a.value));

      return scoredJobs.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Failed to fetch matched jobs: $e');
    }
  }

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

  static Future<void> deleteJobPosting(String jobId) async {
    try {
      await SupabaseService.client.from(_tableName).delete().eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to delete job posting: $e');
    }
  }

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
      final skillsList = helperSkills
          .split(',')
          .map((skill) => skill.trim().toLowerCase())
          .where((skill) => skill.isNotEmpty)
          .toList();

      final allJobsResponse = await SupabaseService.client
          .from(_tableName)
          .select(
            '*, employers(id, first_name, last_name, profile_picture_base64)',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false);

      var allJobs = (allJobsResponse as List)
          .map((data) => JobPosting.fromMap(data))
          .toList();

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

      if (skillsList.isEmpty) {
        return allJobs.take(limit).toList();
      }

      final List<MapEntry<JobPosting, int>> scoredJobs = [];

      for (final job in allJobs) {
        int matchScore = 0;

        for (final requiredSkill in job.requiredSkills) {
          final normalizedRequired = requiredSkill.toLowerCase().trim();
          for (final helperSkill in skillsList) {
            if (normalizedRequired.contains(helperSkill) ||
                helperSkill.contains(normalizedRequired)) {
              matchScore += 5;
            }
          }
        }

        if (barangay != null &&
            barangay.isNotEmpty &&
            (job.barangay ?? '').toLowerCase() == barangay.toLowerCase()) {
          matchScore += 3;
        }

        final daysSincePosted = DateTime.now().difference(job.createdAt).inDays;
        if (daysSincePosted <= 1) {
          matchScore += 2;
        } else if (daysSincePosted <= 7) {
          matchScore += 1;
        }

        if (matchScore > 0) {
          scoredJobs.add(MapEntry(job, matchScore));
        }
      }

      scoredJobs.sort((a, b) => b.value.compareTo(a.value));

      return scoredJobs.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Failed to fetch best matches: $e');
    }
  }

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

  static Future<List<JobPosting>> getTrendingJobPostings({
    int limit = 10,
  }) async {
    try {
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
