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
import '../../localization_manager.dart';

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
  DateTime? _selectedExpiryDate; // New field for expiry date

  // Form validation errors
  String? _titleError;
  String? _descriptionError;
  String? _salaryError;
  String? _paymentFrequencyError;
  String? _barangayError;
  String? _skillsError;
  String? _expiryDateError; // New validation error
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
      _expiryDateError = null;

      // Validate title
      if (_titleController.text.trim().isEmpty) {
        _titleError = LocalizationManager.translate('job_title_is_required');
        isValid = false;
      }

      // Validate description
      if (_descriptionController.text.trim().isEmpty) {
        _descriptionError = LocalizationManager.translate(
          'job_description_is_required',
        );
        isValid = false;
      }

      // Validate salary
      if (_salaryController.text.trim().isEmpty) {
        _salaryError = LocalizationManager.translate('salary_is_required');
        isValid = false;
      } else {
        final salary = double.tryParse(_salaryController.text.trim());
        if (salary == null || salary <= 0) {
          _salaryError = LocalizationManager.translate(
            'please_enter_a_valid_salary_amount',
          );
          isValid = false;
        }
      }

      // Validate payment frequency
      if (_selectedPaymentFrequency == null) {
        _paymentFrequencyError = LocalizationManager.translate(
          'payment_frequency_is_required',
        );
        isValid = false;
      }

      // Validate barangay
      if (_selectedBarangay == null) {
        _barangayError = LocalizationManager.translate(
          'barangay_selection_is_required',
        );
        isValid = false;
      }

      // Validate skills
      if (_requiredSkills.isEmpty) {
        _skillsError = LocalizationManager.translate(
          'at_least_one_skill_is_required',
        );
        isValid = false;
      }

      // Validate expiry date
      if (_selectedExpiryDate != null &&
          _selectedExpiryDate!.isBefore(DateTime.now())) {
        _expiryDateError = LocalizationManager.translate(
          'expiry_date_must_be_in_the_future',
        );
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
        expiresAt: _selectedExpiryDate,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('job_posted_successfully'),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_post_job')}: $e',
            ),
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

  Future<void> _selectExpiryDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDate ?? DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedExpiryDate ?? DateTime.now().add(Duration(days: 30)),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Create DateTime in local Philippine time (do NOT convert to UTC)
        // Store as local time so comparisons work correctly when phone time changes
        final localDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedExpiryDate = localDateTime;
          _expiryDateError = null;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        title: Text(
          LocalizationManager.translate('post_a_job'),
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
                Text(
                  LocalizationManager.translate('job_details'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationManager.translate(
                    'fill_in_the_information_below_to_post_your_job',
                  ),
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 32),

                // Job Title
                CustomTextField(
                  controller: _titleController,
                  label: LocalizationManager.translate('job_title'),
                  hint: LocalizationManager.translate(
                    'e.g., House Cleaner, Babysitter, Cook',
                  ),
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
                    Text(
                      LocalizationManager.translate('job_description'),
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
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          hintText: LocalizationManager.translate(
                            'describe_the_job_responsibilities_requirements_and_any_specific_details',
                          ),
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
                    Text(
                      LocalizationManager.translate('salary'),
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
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                          hintText: LocalizationManager.translate(
                            'enter_amount',
                          ),
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

                // Municipality
                BarangayDropdown(
                  selectedBarangay: _selectedMunicipality,
                  barangayList: LocationConstants.getSortedMunicipalities(),
                  label: LocalizationManager.translate('select_municipality'),
                  hint: LocalizationManager.translate(
                    'select_your_municipality',
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedMunicipality = value;
                      _barangayList =
                          LocationConstants.municipalityBarangays[value] ?? [];
                      _selectedBarangay = null;
                    });
                  },
                ),

                // Barangay
                BarangayDropdown(
                  selectedBarangay: _selectedBarangay,
                  barangayList: _barangayList,
                  label: LocalizationManager.translate('select_barangay'),
                  hint: LocalizationManager.translate('select_your_barangay'),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedBarangay = value;
                      _barangayError = null;
                    });
                  },
                ),
                if (_barangayError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    LocalizationManager.translate(_barangayError!),
                    style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                  ),
                ],
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
                  errorText: _skillsError != null
                      ? LocalizationManager.translate(_skillsError!)
                      : null,
                ),
                const SizedBox(height: 24),

                // Job Expiry Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationManager.translate('available_until'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _expiryDateError != null
                                ? Colors.red.shade400
                                : const Color(0xFFD1D5DB),
                            width: 1,
                          ),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedExpiryDate == null
                                  ? LocalizationManager.translate(
                                      'select_expiry_date',
                                    )
                                  : _formatDate(_selectedExpiryDate!),
                              style: TextStyle(
                                color: _selectedExpiryDate == null
                                    ? Color(0xFF9CA3AF)
                                    : Color(0xFF374151),
                                fontSize: 16,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              color: const Color(0xFF1565C0),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_expiryDateError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _expiryDateError!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      LocalizationManager.translate(
                        'job_will_not_show_after_expiry_date',
                      ),
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
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
                        : Text(
                            LocalizationManager.translate('post_job_button'),
                            style: const TextStyle(
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
