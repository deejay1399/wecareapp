// import 'package:flutter/material.dart';
// import '../../models/job_posting.dart';
// import '../../models/helper.dart';
// import '../../services/saved_job_service.dart';
// import '../cards/job_card_with_rating.dart';

// class SavedJobsWidget extends StatefulWidget {
//   final Helper? currentHelper;
//   final List<JobPosting> jobPostings;
//   final Function(JobPosting) onJobTap;
//   final Set<String> appliedJobIds;
//   final Function(JobPosting, bool) onSaveToggle;

//   const SavedJobsWidget({
//     super.key,
//     required this.currentHelper,
//     required this.jobPostings,
//     required this.onJobTap,
//     required this.appliedJobIds,
//     required this.onSaveToggle,
//   });

//   @override
//   State<SavedJobsWidget> createState() => _SavedJobsWidgetState();
// }

// class _SavedJobsWidgetState extends State<SavedJobsWidget> {
//   List<JobPosting> _savedJobs = [];
//   bool _isLoading = true;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedJobs();
//   }

//   Future<void> _loadSavedJobs() async {
//     if (!mounted) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       if (widget.currentHelper == null) {
//         if (mounted) {
//           setState(() {
//             _savedJobs = [];
//             _isLoading = false;
//           });
//         }
//         return;
//       }

//       final savedJobs = await SavedJobService.getSavedJobsForHelper(
//         widget.currentHelper!.id,
//       );

//       if (mounted) {
//         setState(() {
//           _savedJobs = savedJobs;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Failed to load saved jobs: $e';
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _onUnsaveJob(JobPosting job) async {
//     if (widget.currentHelper == null) return;

//     try {
//       // Optimistically remove from list
//       setState(() {
//         _savedJobs.removeWhere((savedJob) => savedJob.id == job.id);
//       });

//       // Call the parent's save toggle handler
//       widget.onSaveToggle(job, false);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Removed "${job.title}" from saved jobs'),
//             backgroundColor: const Color(0xFF10B981),
//             action: SnackBarAction(
//               label: 'Undo',
//               textColor: Colors.white,
//               onPressed: () async {
//                 // Re-add the job and toggle save
//                 setState(() {
//                   _savedJobs.insert(0, job);
//                 });
//                 widget.onSaveToggle(job, true);
//               },
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       // If error, re-add the job to the list
//       setState(() {
//         _savedJobs.insert(0, job);
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to unsave job: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Widget _buildSavedJobsList() {
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
//                   Icons.bookmark,
//                   size: 16,
//                   color: Color(0xFFFF8A50),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Saved Jobs',
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
//                   color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
//                   ),
//                 ),
//                 child: Text(
//                   '${_savedJobs.length} saved',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFFFF8A50),
//                   ),
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
//               color: const Color(0xFFFFF7ED),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
//               ),
//             ),
//             child: const Row(
//               children: [
//                 Icon(
//                   Icons.lightbulb_outline,
//                   size: 16,
//                   color: Color(0xFFFF8A50),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Jobs you\'ve bookmarked for later. Tap to apply or swipe to remove.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFFFF8A50),
//                     ),
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
//           itemCount: _savedJobs.length,
//           itemBuilder: (context, index) {
//             final job = _savedJobs[index];
//             return Dismissible(
//               key: Key('saved_job_${job.id}'),
//               direction: DismissDirection.endToStart,
//               background: Container(
//                 alignment: Alignment.centerRight,
//                 padding: const EdgeInsets.only(right: 20),
//                 margin: const EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.bookmark_remove,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Remove',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               confirmDismiss: (direction) async {
//                 return await showDialog<bool>(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: const Text('Remove Saved Job'),
//                         content: Text(
//                           'Are you sure you want to remove "${job.title}" from your saved jobs?',
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.of(context).pop(false),
//                             child: const Text('Cancel'),
//                           ),
//                           ElevatedButton(
//                             onPressed: () => Navigator.of(context).pop(true),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red,
//                               foregroundColor: Colors.white,
//                             ),
//                             child: const Text('Remove'),
//                           ),
//                         ],
//                       ),
//                     ) ??
//                     false;
//               },
//               onDismissed: (direction) {
//                 _onUnsaveJob(job);
//               },
//               child: JobCardWithRating(
//                 job: job,
//                 hasApplied: widget.appliedJobIds.contains(job.id),
//                 onTap: () => widget.onJobTap(job),
//               ),
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
//             constraints: BoxConstraints(
//               minHeight: constraints.maxHeight,
//             ),
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
//                         Icons.bookmark_outline,
//                         size: 60,
//                         color: Color(0xFFFF8A50),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     const Text(
//                       'No Saved Jobs',
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
//                         'Jobs you bookmark will appear here. Start exploring jobs and save the ones you\'re interested in!',
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
//                         _buildTipItem(Icons.search, 'Browse recent jobs'),
//                         const SizedBox(height: 12),
//                         _buildTipItem(Icons.star, 'Check best matches'),
//                         const SizedBox(height: 12),
//                         _buildTipItem(Icons.bookmark_add, 'Save jobs you like'),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: _loadSavedJobs,
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
//         Icon(
//           icon,
//           size: 20,
//           color: const Color(0xFFFF8A50),
//         ),
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
//               'Error Loading Saved Jobs',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _errorMessage!,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF6B7280),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _loadSavedJobs,
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

//   Widget _buildNotLoggedInState() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: constraints.maxHeight,
//             ),
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
//                         color: const Color(0xFF6B7280).withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(24),
//                         border: Border.all(
//                           color: const Color(0xFF6B7280).withValues(alpha: 0.2),
//                           width: 2,
//                         ),
//                       ),
//                       child: const Icon(
//                         Icons.person_outline,
//                         size: 60,
//                         color: Color(0xFF6B7280),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     const Text(
//                       'Login Required',
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
//                         'Please log in to save and view your bookmarked jobs.',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Color(0xFF6B7280),
//                           height: 1.5,
//                         ),
//                         textAlign: TextAlign.center,
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

//   @override
//   Widget build(BuildContext context) {
//     if (widget.currentHelper == null) {
//       return _buildNotLoggedInState();
//     }

//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(
//           color: Color(0xFFFF8A50),
//         ),
//       );
//     }

//     if (_errorMessage != null) {
//       return _buildErrorState();
//     }

//     if (_savedJobs.isEmpty) {
//       return _buildEmptyState();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadSavedJobs,
//       color: const Color(0xFFFF8A50),
//       child: ListView(
//         children: [
//           _buildSavedJobsList(),
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

class SavedJobsWidget extends StatelessWidget {
  final Helper? currentHelper;
  final List<JobPosting> jobPostings;
  final Function(JobPosting) onJobTap;
  final Set<String> appliedJobIds;
  final Function(JobPosting, bool) onSaveToggle;

  const SavedJobsWidget({
    super.key,
    required this.currentHelper,
    required this.jobPostings,
    required this.onJobTap,
    required this.appliedJobIds,
    required this.onSaveToggle,
  });

  Widget _buildSavedJobsList(List<JobPosting> jobs) {
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
                  Icons.bookmark,
                  size: 16,
                  color: Color(0xFFFF8A50),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Saved Jobs',
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
                  color: const Color(0xFFFF8A50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF8A50).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${jobs.length} saved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8A50),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF8A50).withOpacity(0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Color(0xFFFF8A50),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jobs you\'ve bookmarked for later. Tap to apply or swipe to remove.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF8A50)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Dismissible(
              key: Key('saved_job_${job.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_remove, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Saved Job'),
                        content: Text(
                          'Are you sure you want to remove "${job.title}" from your saved jobs?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              },
              onDismissed: (direction) {
                onSaveToggle(job, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${job.title}" from saved jobs'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: JobCardWithRating(
                job: job,
                hasApplied: appliedJobIds.contains(job.id),
                onTap: () => onJobTap(job),
              ),
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
                        Icons.bookmark_outline,
                        size: 60,
                        color: Color(0xFFFF8A50),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No Saved Jobs',
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
                        'Jobs you bookmark will appear here. Start exploring jobs and save the ones you\'re interested in!',
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
                        _buildTipItem(Icons.search, 'Browse recent jobs'),
                        const SizedBox(height: 12),
                        _buildTipItem(Icons.star, 'Check best matches'),
                        const SizedBox(height: 12),
                        _buildTipItem(Icons.bookmark_add, 'Save jobs you like'),
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

  Widget _buildNotLoggedInState() {
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
                        color: const Color(0xFF6B7280).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF6B7280).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 60,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Login Required',
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
                        'Please log in to save and view your bookmarked jobs.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (currentHelper == null) {
      return _buildNotLoggedInState();
    }

    if (jobPostings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {}, // Parent handles refresh
      color: const Color(0xFFFF8A50),
      child: ListView(
        children: [
          _buildSavedJobsList(jobPostings),
          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }
}
