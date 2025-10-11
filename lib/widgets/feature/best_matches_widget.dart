// import 'package:flutter/material.dart';
// import '../../models/job_posting.dart';
// import '../../models/helper.dart';
// import '../../services/job_posting_service.dart';
// import '../cards/job_card_with_rating.dart';

// class BestMatchesWidget extends StatefulWidget {
//   final Helper? currentHelper;
//   final List<JobPosting> jobPostings;
//   final Function(JobPosting) onJobTap;
//   final Set<String> appliedJobIds;
//   final Set<String> savedJobIds;
//   final Function(JobPosting, bool) onSaveToggle;

//   const BestMatchesWidget({
//     super.key,
//     required this.currentHelper,
//     required this.jobPostings,
//     required this.onJobTap,
//     required this.appliedJobIds,
//     required this.savedJobIds,
//     required this.onSaveToggle,
//   });

//   @override
//   State<BestMatchesWidget> createState() => _BestMatchesWidgetState();
// }

// class _BestMatchesWidgetState extends State<BestMatchesWidget> {
//   List<JobPosting> _bestMatches = [];
//   List<JobPosting> _trendingJobs = [];
//   bool _isLoading = true;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     // _loadBestMatches();
//     print("widget.jobPostings");
//     print(widget.jobPostings.length);
//   }

//   Future<void> _loadBestMatches() async {
//     if (!mounted) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       if (widget.currentHelper == null) {
//         // If no helper data, just show trending jobs
//         final trending = await JobPostingService.getTrendingJobPostings(
//           limit: 15,
//         );

//         if (mounted) {
//           setState(() {
//             _bestMatches = [];
//             _trendingJobs = trending;
//             _isLoading = false;
//           });
//         }
//         return;
//       }

//       // Load both best matches and trending jobs in parallel
//       final results = await Future.wait([
//         JobPostingService.getBestMatchesForHelper(
//           helperSkills: widget.currentHelper!.skill,
//           // helperBarangay: widget.currentHelper!.barangay,
//           limit: 10,
//         ),
//         JobPostingService.getTrendingJobPostings(limit: 10),
//       ]);

//       if (mounted) {
//         setState(() {
//           _bestMatches = results[0];
//           _trendingJobs = results[1];
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Failed to load job matches: $e';
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Widget _buildBestMatchesSection() {
//     // if (_bestMatches.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(6),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.star,
//                   size: 16,
//                   color: Color(0xFFFF8A50),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Best Matches for You',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1F2937),
//                 ),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF10B981).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFF10B981).withValues(alpha: 0.2),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.verified,
//                       size: 12,
//                       color: Color(0xFF10B981),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${_bestMatches.length} matches',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF10B981),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (widget.currentHelper != null) ...[
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFEBF8FF),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFF1565C0).withValues(alpha: 0.2),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.info_outline,
//                     size: 16,
//                     color: Color(0xFF1565C0),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Jobs matched based on your skills (${widget.currentHelper!.skill}) and location (${widget.currentHelper!.barangay})',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Color(0xFF1565C0),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           itemCount: _bestMatches.length,
//           itemBuilder: (context, index) {
//             final job = _bestMatches[index];
//             return JobCardWithRating(
//               job: job,
//               hasApplied: widget.appliedJobIds.contains(job.id),
//               isSaved: widget.savedJobIds.contains(job.id),
//               onTap: () => widget.onJobTap(job),
//               onSaveToggle: (isSaved) => widget.onSaveToggle(job, isSaved),
//             );
//           },
//         ),
//         if (_trendingJobs.isNotEmpty) ...[
//           const SizedBox(height: 24),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24),
//             child: Divider(color: Color(0xFFE5E7EB)),
//           ),
//           const SizedBox(height: 8),
//         ],
//       ],
//     );
//   }

//   Widget _buildTrendingJobsSection() {
//     if (_trendingJobs.isEmpty) return const SizedBox.shrink();

//     // Filter out jobs already shown in best matches
//     final uniqueTrendingJobs = _trendingJobs
//         .where(
//           (job) => !_bestMatches.any((bestMatch) => bestMatch.id == job.id),
//         )
//         .toList();

//     if (uniqueTrendingJobs.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(6),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.trending_up,
//                   size: 16,
//                   color: Color(0xFF8B5CF6),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Trending Jobs',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1F2937),
//                 ),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.whatshot,
//                       size: 12,
//                       color: Color(0xFF8B5CF6),
//                     ),
//                     const SizedBox(width: 4),
//                     const Text(
//                       'Hot',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF8B5CF6),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFAF5FF),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
//               ),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.trending_up, size: 16, color: Color(0xFF8B5CF6)),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Jobs with high application activity in the past week',
//                     style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           itemCount: uniqueTrendingJobs.length,
//           itemBuilder: (context, index) {
//             final job = uniqueTrendingJobs[index];
//             return JobCardWithRating(
//               job: job,
//               hasApplied: widget.appliedJobIds.contains(job.id),
//               isSaved: widget.savedJobIds.contains(job.id),
//               onTap: () => widget.onJobTap(job),
//               onSaveToggle: (isSaved) => widget.onSaveToggle(job, isSaved),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildEmptyState() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(minHeight: constraints.maxHeight),
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 120,
//                       height: 120,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(24),
//                         border: Border.all(
//                           color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
//                           width: 2,
//                         ),
//                       ),
//                       child: const Icon(
//                         Icons.star_outline,
//                         size: 60,
//                         color: Color(0xFFFF8A50),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     const Text(
//                       'No Matches Found',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1F2937),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 24),
//                       child: Text(
//                         'Update your profile with more skills and experience to get better job matches!',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Color(0xFF6B7280),
//                           height: 1.5,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     Column(
//                       children: [
//                         _buildTipItem(Icons.edit, 'Complete your profile'),
//                         const SizedBox(height: 12),
//                         _buildTipItem(Icons.school, 'Add more skills'),
//                         const SizedBox(height: 12),
//                         _buildTipItem(
//                           Icons.location_on,
//                           'Update your location',
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: _loadBestMatches,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Refresh'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFFF8A50),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 24,
//                           vertical: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, size: 20, color: const Color(0xFFFF8A50)),
//         const SizedBox(width: 12),
//         Text(
//           text,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Color(0xFF6B7280),
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Icon(
//                 Icons.error_outline,
//                 size: 40,
//                 color: Colors.red.shade600,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Error Loading Matches',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _errorMessage!,
//               style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _loadBestMatches,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFFF8A50),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(color: Color(0xFFFF8A50)),
//       );
//     }

//     if (_errorMessage != null) {
//       return _buildErrorState();
//     }

//     if (_bestMatches.isEmpty && _trendingJobs.isEmpty) {
//       return _buildEmptyState();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadBestMatches,
//       color: const Color(0xFFFF8A50),
//       child: ListView(
//         children: [
//           _buildBestMatchesSection(),
//           _buildTrendingJobsSection(),
//           const SizedBox(height: 24), // Bottom padding
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/helper.dart';
import '../cards/job_card_with_rating.dart';

class BestMatchesWidget extends StatelessWidget {
  final Helper? currentHelper;
  final List<JobPosting> jobPostings;
  final Function(JobPosting) onJobTap;
  final Set<String> appliedJobIds;
  final Set<String> savedJobIds;
  final Function(JobPosting, bool) onSaveToggle;

  const BestMatchesWidget({
    super.key,
    required this.currentHelper,
    required this.jobPostings,
    required this.onJobTap,
    required this.appliedJobIds,
    required this.savedJobIds,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (jobPostings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {}, // Parent handles refresh
      color: const Color(0xFFFF8A50),
      child: ListView(
        children: [
          _buildBestMatchesSection(jobPostings),
          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildBestMatchesSection(List<JobPosting> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  size: 16,
                  color: Color(0xFFFF8A50),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Best Matches for You',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${matches.length} matches',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (currentHelper != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jobs matched based on your skills (${currentHelper!.skill}) and location (${currentHelper!.barangay})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final job = matches[index];
            print('Job #$index: ${matches[index].toMap()}');
            return JobCardWithRating(
              job: job,
              hasApplied: appliedJobIds.contains(job.id),
              isSaved: savedJobIds.contains(job.id),
              onTap: () => onJobTap(job),
              onSaveToggle: (isSaved) => onSaveToggle(job, isSaved),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF8A50).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.star_outline,
                        size: 60,
                        color: Color(0xFFFF8A50),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No Matches Found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Update your profile with more skills and experience to get better job matches!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        _buildTipItem(Icons.edit, 'Complete your profile'),
                        const SizedBox(height: 12),
                        _buildTipItem(Icons.school, 'Add more skills'),
                        const SizedBox(height: 12),
                        _buildTipItem(
                          Icons.location_on,
                          'Update your location',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF8A50)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
