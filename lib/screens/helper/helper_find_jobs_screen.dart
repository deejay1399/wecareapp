// import 'package:flutter/material.dart';
// import '../../models/job_posting.dart';
// import '../../models/helper.dart';
// import '../../services/job_posting_service.dart';
// import '../../services/application_service.dart';
// import '../../services/session_service.dart';
// import '../../services/saved_job_service.dart';
// import '../../widgets/ui/job_tabs_widget.dart';
// import '../../widgets/feature/recent_jobs_widget.dart';
// import '../../widgets/feature/best_matches_widget.dart';
// import '../../widgets/feature/saved_jobs_widget.dart';
// import 'apply_job_screen.dart';

// class HelperFindJobsScreen extends StatefulWidget {
//   const HelperFindJobsScreen({super.key});

//   @override
//   State<HelperFindJobsScreen> createState() => _HelperFindJobsScreenState();
// }

// class _HelperFindJobsScreenState extends State<HelperFindJobsScreen> {
//   int _selectedTab = 0;
//   Helper? _currentHelper;
//   Set<String> _appliedJobIds = {};
//   Set<String> _savedJobIds = {};
//   bool _isLoadingHelper = true;

//   // Tab counts for display
//   int _recentCount = 0;
//   int _bestMatchesCount = 0;
//   int _savedCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentHelper();
//     _loadTabCounts();
//   }

//   Future<void> _loadCurrentHelper() async {
//     try {
//       final helper = await SessionService.getCurrentHelper();
//       if (helper != null && mounted) {
//         setState(() {
//           _currentHelper = helper;
//         });

//         // Load helper's applied jobs and saved jobs in parallel
//         await Future.wait([
//           _loadAppliedJobs(),
//           _loadSavedJobs(),
//         ]);
//       }
//     } catch (e) {
//       // Handle error silently
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingHelper = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadAppliedJobs() async {
//     if (_currentHelper == null) return;

//     try {
//       final applications = await ApplicationService.getApplicationsByHelper(_currentHelper!.id);

//       if (mounted) {
//         setState(() {
//           _appliedJobIds = applications.map((app) => app.jobId).toSet();
//         });
//       }
//     } catch (e) {
//       // Handle error silently
//     }
//   }

//   Future<void> _loadSavedJobs() async {
//     if (_currentHelper == null) return;

//     try {
//       final savedJobIds = await SavedJobService.getSavedJobIds(_currentHelper!.id);

//       if (mounted) {
//         setState(() {
//           _savedJobIds = savedJobIds;
//           _savedCount = savedJobIds.length;
//         });
//       }
//     } catch (e) {
//       // Handle error silently
//     }
//   }

//   Future<void> _loadTabCounts() async {
//     try {
//       // Load counts for tab indicators
//       final results = await Future.wait([
//         JobPostingService.getRecentJobPostings(limit: 50).then((jobs) => jobs.length),
//         _currentHelper != null
//             ? JobPostingService.getBestMatchesForHelper(
//                 helperSkills: _currentHelper!.skill,
//                 helperBarangay: _currentHelper!.barangay,
//                 limit: 50,
//               ).then((jobs) => jobs.length)
//             : Future.value(0),
//       ]);

//       if (mounted) {
//         setState(() {
//           _recentCount = results[0];
//           _bestMatchesCount = results[1];
//         });
//       }
//     } catch (e) {
//       // Handle error silently
//     }
//   }

//   void _onTabChanged(int index) {
//     setState(() {
//       _selectedTab = index;
//     });
//   }

//   Future<void> _onJobTap(JobPosting job) async {
//     if (_currentHelper == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please log in to apply for jobs'),
//           backgroundColor: Color(0xFFFF9800),
//         ),
//       );
//       return;
//     }

//     // Check if already applied
//     try {
//       final hasApplied = await ApplicationService.hasApplied(job.id, _currentHelper!.id);

//       if (hasApplied && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('You have already applied to this job'),
//             backgroundColor: Color(0xFFFF9800),
//           ),
//         );
//         return;
//       }

//       // Navigate to apply screen
//       if (!mounted) return;
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ApplyJobScreen(jobPosting: job),
//         ),
//       );

//       if (result == true && mounted) {
//         // Application submitted successfully - add to applied jobs set
//         setState(() {
//           _appliedJobIds.add(job.id);
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Application submitted successfully!'),
//             backgroundColor: Color(0xFF10B981),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _onSaveToggle(JobPosting job, bool shouldSave) async {
//     if (_currentHelper == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please log in to save jobs'),
//           backgroundColor: Color(0xFFFF9800),
//         ),
//       );
//       return;
//     }

//     try {
//       if (shouldSave) {
//         await SavedJobService.saveJob(
//           helperId: _currentHelper!.id,
//           jobPostingId: job.id,
//         );

//         setState(() {
//           _savedJobIds.add(job.id);
//           _savedCount = _savedJobIds.length;
//         });

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Saved "${job.title}" to your bookmarks'),
//               backgroundColor: const Color(0xFF10B981),
//             ),
//           );
//         }
//       } else {
//         await SavedJobService.unsaveJob(
//           helperId: _currentHelper!.id,
//           jobPostingId: job.id,
//         );

//         setState(() {
//           _savedJobIds.remove(job.id);
//           _savedCount = _savedJobIds.length;
//         });

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Removed "${job.title}" from bookmarks'),
//               backgroundColor: const Color(0xFF6B7280),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error saving job: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Widget _buildCurrentTab() {
//     switch (_selectedTab) {
//       case 0:
//         return RecentJobsWidget(
//           currentHelper: _currentHelper,
//           onJobTap: _onJobTap,
//           appliedJobIds: _appliedJobIds,
//           savedJobIds: _savedJobIds,
//           onSaveToggle: _onSaveToggle,
//         );
//       case 1:
//         return BestMatchesWidget(
//           currentHelper: _currentHelper,
//           onJobTap: _onJobTap,
//           appliedJobIds: _appliedJobIds,
//           savedJobIds: _savedJobIds,
//           onSaveToggle: _onSaveToggle,
//         );
//       case 2:
//         return SavedJobsWidget(
//           currentHelper: _currentHelper,
//           onJobTap: _onJobTap,
//           appliedJobIds: _appliedJobIds,
//           onSaveToggle: _onSaveToggle,
//         );
//       default:
//         return const SizedBox.shrink();
//     }
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Expanded(
//                 child: Text(
//                   'Find Jobs',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFFFF8A50),
//                   ),
//                 ),
//               ),
//               if (_currentHelper != null)
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF10B981).withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: const Color(0xFF10B981).withValues(alpha: 0.2),
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.person,
//                         size: 14,
//                         color: Color(0xFF10B981),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${_currentHelper!.firstName} ${_currentHelper!.lastName}',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF10B981),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//           if (_currentHelper != null) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF7ED),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.location_on,
//                     size: 16,
//                     color: Color(0xFFFF8A50),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Location: ${_currentHelper!.barangay}',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFFFF8A50),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   const Icon(
//                     Icons.work,
//                     size: 16,
//                     color: Color(0xFFFF8A50),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Skills: ${_currentHelper!.skill}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFFFF8A50),
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header with title and user info
//             _buildHeader(),

//             // Tab navigation
//             JobTabsWidget(
//               selectedTab: _selectedTab,
//               onTabChanged: _onTabChanged,
//               recentCount: _recentCount,
//               bestMatchesCount: _bestMatchesCount,
//               savedCount: _savedCount,
//             ),

//             const SizedBox(height: 16),

//             // Tab content
//             Expanded(
//               child: _isLoadingHelper
//                   ? const Center(
//                       child: CircularProgressIndicator(
//                         color: Color(0xFFFF8A50),
//                       ),
//                     )
//                   : _buildCurrentTab(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../models/job_posting.dart';
import '../../models/helper.dart';
import '../../services/job_posting_service.dart';
import '../../services/application_service.dart';
import '../../services/session_service.dart';
import '../../services/saved_job_service.dart';
import '../../widgets/ui/job_tabs_widget.dart';
import '../../widgets/feature/recent_jobs_widget.dart';
import '../../widgets/feature/best_matches_widget.dart';
import '../../widgets/feature/saved_jobs_widget.dart';
import 'apply_job_screen.dart';
import '../../utils/constants/barangay_constants.dart';

class HelperFindJobsScreen extends StatefulWidget {
  const HelperFindJobsScreen({super.key});

  @override
  State<HelperFindJobsScreen> createState() => _HelperFindJobsScreenState();
}

class _HelperFindJobsScreenState extends State<HelperFindJobsScreen> {
  int _selectedTab = 0;
  Helper? _currentHelper;
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _isLoadingHelper = true;

  // LOCATION DROPDOWN STATE
  String? _selectedMunicipality;
  String? _selectedBarangay;
  List<String> _barangayList = [];

  // Tab counts for display
  int _recentCount = 0;
  int _bestMatchesCount = 0;
  int _savedCount = 0;

  // Filtered jobs
  List<JobPosting> _filteredRecentJobs = [];
  List<JobPosting> _filteredBestMatches = [];
  List<JobPosting> _filteredSavedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentHelper();
    _loadTabCounts();
    _loadFilteredJobs(); // Initial load
  }

  Future<void> _loadCurrentHelper() async {
    try {
      final helper = await SessionService.getCurrentHelper();
      if (helper != null && mounted) {
        setState(() {
          _currentHelper = helper;
          print("_currentHelper");
          print(_currentHelper?.age);
        });
        await Future.wait([_loadAppliedJobs(), _loadSavedJobs()]);
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHelper = false;
        });
      }
    }
  }

  Future<void> _loadAppliedJobs() async {
    if (_currentHelper == null) return;
    try {
      final applications = await ApplicationService.getApplicationsByHelper(
        _currentHelper!.id,
      );
      if (mounted) {
        setState(() {
          _appliedJobIds = applications.map((app) => app.jobId).toSet();
        });
      }
    } catch (e) {}
  }

  Future<void> _loadSavedJobs() async {
    if (_currentHelper == null) return;
    try {
      final savedJobIds = await SavedJobService.getSavedJobIds(
        _currentHelper!.id,
      );
      if (mounted) {
        setState(() {
          _savedJobIds = savedJobIds;
          _savedCount = savedJobIds.length;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadTabCounts() async {
    try {
      final results = await Future.wait([
        JobPostingService.getRecentJobPostings(
          limit: 50,
        ).then((jobs) => jobs.length),
        _currentHelper != null
            ? JobPostingService.getBestMatchesForHelper(
                helperSkills: _currentHelper!.skill,
                // helperBarangay: _currentHelper!.barangay,
                limit: 50,
              ).then((jobs) => jobs.length)
            : Future.value(0),
      ]);
      if (mounted) {
        setState(() {
          print("results");
          print(results.length);
          _recentCount = results[0];
          _bestMatchesCount = results[1];
        });
      }
    } catch (e) {}
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Future<void> _onJobTap(JobPosting job) async {
    if (_currentHelper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to apply for jobs'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
      return;
    }
    try {
      final hasApplied = await ApplicationService.hasApplied(
        job.id,
        _currentHelper!.id,
      );
      if (hasApplied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied to this job'),
            backgroundColor: Color(0xFFFF9800),
          ),
        );
        return;
      }
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApplyJobScreen(jobPosting: job),
        ),
      );
      if (result == true && mounted) {
        setState(() {
          _appliedJobIds.add(job.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onSaveToggle(JobPosting job, bool shouldSave) async {
    if (_currentHelper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save jobs'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
      return;
    }
    try {
      if (shouldSave) {
        await SavedJobService.saveJob(
          helperId: _currentHelper!.id,
          jobPostingId: job.id,
        );
        setState(() {
          _savedJobIds.add(job.id);
          _savedCount = _savedJobIds.length;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved "${job.title}" to your bookmarks'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        await SavedJobService.unsaveJob(
          helperId: _currentHelper!.id,
          jobPostingId: job.id,
        );
        setState(() {
          _savedJobIds.remove(job.id);
          _savedCount = _savedJobIds.length;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${job.title}" from bookmarks'),
              backgroundColor: const Color(0xFF6B7280),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFilteredJobs() async {
    // Fetch recent jobs
    List<JobPosting> recentJobs = await JobPostingService.getRecentJobPostings(
      limit: 100,
    );

    // Fetch best matches
    List<JobPosting> bestMatches = _currentHelper == null
        ? []
        : await JobPostingService.getBestMatchesForHelper(
            helperSkills: _currentHelper!.skill,
            limit: 50,
          );

    // Fetch latest saved job ids for the current helper
    Set<String> savedJobIds = {};
    if (_currentHelper != null) {
      savedJobIds = await SavedJobService.getSavedJobIds(_currentHelper!.id);
      // Optionally update the global _savedJobIds if needed elsewhere
      _savedJobIds = savedJobIds;
    }

    // Filter by municipality and barangay if selected
    List<JobPosting> filteredRecentJobs = recentJobs.where((job) {
      if (_selectedMunicipality != null &&
          job.municipality != _selectedMunicipality) {
        return false;
      }
      if (_selectedBarangay != null && job.barangay != _selectedBarangay) {
        return false;
      }
      return true;
    }).toList();

    List<JobPosting> filteredBestMatches = bestMatches.where((job) {
      if (_selectedMunicipality != null &&
          job.municipality != _selectedMunicipality) {
        return false;
      }
      if (_selectedBarangay != null && job.barangay != _selectedBarangay) {
        return false;
      }
      return true;
    }).toList();

    // For saved jobs, filter filteredRecentJobs by saved ids
    List<JobPosting> filteredSavedJobs = filteredRecentJobs
        .where((job) => savedJobIds.contains(job.id))
        .toList();

    setState(() {
      _filteredRecentJobs = filteredRecentJobs;
      _filteredBestMatches = filteredBestMatches;
      _filteredSavedJobs = filteredSavedJobs;

      _recentCount = _filteredRecentJobs.length;
      _bestMatchesCount = _filteredBestMatches.length;
      _savedCount = _filteredSavedJobs.length;
      _savedJobIds = savedJobIds; // Update if you need this elsewhere
    });
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return RecentJobsWidget(
          currentHelper: _currentHelper,
          jobPostings: _filteredRecentJobs, // Pass filtered jobs
          onJobTap: _onJobTap,
          appliedJobIds: _appliedJobIds,
          savedJobIds: _savedJobIds,
          onSaveToggle: _onSaveToggle,
        );
      case 1:
        return BestMatchesWidget(
          currentHelper: _currentHelper,
          jobPostings: _filteredBestMatches,
          onJobTap: _onJobTap,
          appliedJobIds: _appliedJobIds,
          savedJobIds: _savedJobIds,
          onSaveToggle: _onSaveToggle,
        );
      case 2:
        return SavedJobsWidget(
          currentHelper: _currentHelper,
          jobPostings: _filteredSavedJobs,
          onJobTap: _onJobTap,
          appliedJobIds: _appliedJobIds,
          onSaveToggle: _onSaveToggle,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Find Jobs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8A50),
                  ),
                ),
              ),
              if (_currentHelper != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentHelper!.firstName} ${_currentHelper!.lastName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_currentHelper != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8A50).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFFFF8A50),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location: ${_currentHelper!.barangay}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF8A50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.work, size: 16, color: Color(0xFFFF8A50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Skills: ${_currentHelper!.skill}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8A50),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationDropdowns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMunicipality,
                  decoration: InputDecoration(
                    labelText: 'Municipality',
                    hintText: 'Select municipality',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: LocationConstants.getSortedMunicipalities()
                      .map(
                        (mun) => DropdownMenuItem(value: mun, child: Text(mun)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMunicipality = value;
                      _barangayList =
                          LocationConstants.getBarangaysForMunicipality(value!);
                      _selectedBarangay = null;
                    });
                    _loadFilteredJobs();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Clear location filters',
                icon: const Icon(Icons.clear, color: Color(0xFFFF8A50)),
                onPressed: () {
                  setState(() {
                    _selectedMunicipality = null;
                    _selectedBarangay = null;
                    _barangayList = [];
                  });
                  _loadFilteredJobs();
                },
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            decoration: InputDecoration(
              labelText: 'Barangay',
              hintText: 'Select barangay',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _barangayList
                .map((brgy) => DropdownMenuItem(value: brgy, child: Text(brgy)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedBarangay = value;
              });
              _loadFilteredJobs();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLocationDropdowns(),
            JobTabsWidget(
              selectedTab: _selectedTab,
              onTabChanged: _onTabChanged,
              recentCount: _recentCount,
              bestMatchesCount: _bestMatchesCount,
              savedCount: _savedCount,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingHelper
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF8A50),
                      ),
                    )
                  : _buildCurrentTab(),
            ),
          ],
        ),
      ),
    );
  }
}
