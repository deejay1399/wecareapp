import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../services/job_posting_service.dart';
import '../../services/session_service.dart';
import '../../widgets/cards/completed_job_card.dart';

class CompletedJobsScreen extends StatefulWidget {
  const CompletedJobsScreen({super.key});

  @override
  State<CompletedJobsScreen> createState() => _CompletedJobsScreenState();
}

class _CompletedJobsScreenState extends State<CompletedJobsScreen> {
  List<JobPosting> _completedJobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _userType = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndCompletedJobs();
  }

  Future<void> _loadUserAndCompletedJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final helper = await SessionService.getCurrentHelper();
      final employer = await SessionService.getCurrentEmployer();

      if (helper != null) {
        _userType = 'helper';
        _userId = helper.id;
      } else if (employer != null) {
        _userType = 'employer';
        _userId = employer.id;
      } else {
        throw Exception('No active user session found');
      }

      await _loadCompletedJobs();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load completed jobs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCompletedJobs() async {
    try {
      final completedJobs = await JobPostingService.getCompletedJobsForUser(
        userId: _userId,
        userType: _userType,
      );

      if (mounted) {
        setState(() {
          _completedJobs = completedJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load completed jobs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshJobs() async {
    await _loadCompletedJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Jobs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8A50)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_completedJobs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshJobs,
      color: const Color(0xFFFF8A50),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedJobs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CompletedJobCard(
              job: _completedJobs[index],
              userType: _userType,
              userId: _userId,
              onRatingSubmitted: _refreshJobs,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshJobs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No completed jobs yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userType == 'helper'
                  ? 'Complete your first job to see it here and rate your experience.'
                  : 'Mark your first job as completed to see it here and rate the helper.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
