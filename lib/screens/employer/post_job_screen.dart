import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/employer.dart';
import '../../services/job_posting_service.dart';
import '../../services/session_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/barangay_dropdown.dart';
import '../../widgets/forms/payment_frequency_dropdown.dart';
import '../../widgets/forms/skills_input_field.dart';
import '../../utils/constants/barangay_constants.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();

  String? _selectedPaymentFrequency;
  String? _selectedMunicipality;
  String? _selectedBarangay;
  List<String> _requiredSkills = [];
  bool _isLoading = false;
  Employer? _currentEmployer;

  // Form validation errors
  String? _titleError;
  String? _descriptionError;
  String? _salaryError;
  String? _paymentFrequencyError;
  String? _barangayError;
  String? _skillsError;
  List<String> _barangayList = [];
  @override
  void initState() {
    super.initState();
    _loadCurrentEmployer();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentEmployer() async {
    try {
      final employer = await SessionService.getCurrentEmployer();
      if (employer != null) {
        setState(() {
          _currentEmployer = employer;
          _selectedBarangay = employer.barangay;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      // Reset errors
      _titleError = null;
      _descriptionError = null;
      _salaryError = null;
      _paymentFrequencyError = null;
      _barangayError = null;
      _skillsError = null;

      // Validate title
      if (_titleController.text.trim().isEmpty) {
        _titleError = 'Job title is required';
        isValid = false;
      }

      // Validate description
      if (_descriptionController.text.trim().isEmpty) {
        _descriptionError = 'Job description is required';
        isValid = false;
      }

      // Validate salary
      if (_salaryController.text.trim().isEmpty) {
        _salaryError = 'Salary is required';
        isValid = false;
      } else {
        final salary = double.tryParse(_salaryController.text.trim());
        if (salary == null || salary <= 0) {
          _salaryError = 'Please enter a valid salary amount';
          isValid = false;
        }
      }

      // Validate payment frequency
      if (_selectedPaymentFrequency == null) {
        _paymentFrequencyError = 'Payment frequency is required';
        isValid = false;
      }

      // Validate barangay
      if (_selectedBarangay == null) {
        _barangayError = 'Barangay selection is required';
        isValid = false;
      }

      // Validate skills
      if (_requiredSkills.isEmpty) {
        _skillsError = 'At least one skill is required';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _postJob() async {
    if (!_validateForm()) return;
    if (_currentEmployer == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await JobPostingService.createJobPosting(
        employerId: _currentEmployer!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        salary: double.parse(_salaryController.text.trim()),
        paymentFrequency: _selectedPaymentFrequency!,
        municipality: _selectedMunicipality!,
        barangay: _selectedBarangay!,
        requiredSkills: _requiredSkills,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post job: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
        ),
        title: const Text(
          'Post a Job',
          style: TextStyle(
            color: Color(0xFF1565C0),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Job Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in the information below to post your job.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 32),

                // Job Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Job Title',
                  hint: 'e.g., House Cleaner, Babysitter, Cook',
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _titleError!,
                    style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),

                // Job Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _descriptionError != null
                              ? Colors.red.shade400
                              : const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          hintText:
                              'Describe the job responsibilities, requirements, and any specific details...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_descriptionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _descriptionError!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Salary
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Salary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _salaryError != null
                              ? Colors.red.shade400
                              : const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _salaryController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                          hintText: 'Enter amount (e.g., 500.00)',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                          ),
                          prefixText: '₱ ',
                          prefixStyle: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_salaryError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _salaryError!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Frequency
                PaymentFrequencyDropdown(
                  value: _selectedPaymentFrequency,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentFrequency = value;
                      _paymentFrequencyError = null;
                    });
                  },
                  errorText: _paymentFrequencyError,
                ),
                const SizedBox(height: 24),

                // Barangay
                BarangayDropdown(
                  selectedBarangay: _selectedMunicipality,
                  barangayList: LocationConstants.getSortedMunicipalities(),
                  label: 'Select Municipality',
                  hint: 'Select your Municipality',
                  onChanged: (String? value) {
                    setState(() {
                      _selectedMunicipality = value;
                      // Update barangay list based on selected municipality
                      _barangayList =
                          LocationConstants.municipalityBarangays[value] ?? [];
                      _selectedBarangay = null; // reset barangay selection
                    });
                  },
                ),

                BarangayDropdown(
                  selectedBarangay: _selectedBarangay,
                  barangayList: _barangayList,
                  label: 'Select Barangay',
                  hint: 'Select your barangay',
                  onChanged: (String? value) {
                    setState(() {
                      _selectedBarangay = value;
                    });
                  },
                ),
                // BarangayDropdown(
                //   selectedBarangay: _selectedBarangay,
                //   barangayList: LocationConstants.tagbilaranBarangays,
                //   onChanged: (value) {
                //     setState(() {
                //       _selectedBarangay = value;
                //       _barangayError = null;
                //     });
                //   },
                // ),
                // if (_barangayError != null) ...[
                //   const SizedBox(height: 8),
                //   Text(
                //     _barangayError!,
                //     style: TextStyle(
                //       color: Colors.red.shade600,
                //       fontSize: 14,
                //     ),
                //   ),
                // ],
                const SizedBox(height: 24),

                // Required Skills
                SkillsInputField(
                  skills: _requiredSkills,
                  onSkillsChanged: (skills) {
                    setState(() {
                      _requiredSkills = skills;
                      _skillsError = null;
                    });
                  },
                  errorText: _skillsError,
                ),
                const SizedBox(height: 40),

                // Post Job Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _postJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(
                        0xFF1565C0,
                      ).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Post Job',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
