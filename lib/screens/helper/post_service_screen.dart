import 'package:flutter/material.dart';
import '../../models/helper.dart';
import '../../services/helper_service_posting_service.dart';
import '../../services/session_service.dart';
import '../../utils/constants/barangay_constants.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/skills_input_field.dart';
import '../../localization_manager.dart';

class PostServiceScreen extends StatefulWidget {
  const PostServiceScreen({super.key});

  @override
  State<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends State<PostServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  Helper? _currentHelper;
  List<String> _skills = [];
  String _selectedExperience = 'Entry Level';
  String _selectedAvailability = 'Part-time';
  List<String> _selectedServiceAreas = [];
  bool _isLoading = false;
  DateTime? _selectedExpiryDate; // New field for expiry date

  final List<String> _experienceLevels = [
    LocalizationManager.translate('entry_level'),
    LocalizationManager.translate('intermediate'),
    LocalizationManager.translate('experienced'),
    LocalizationManager.translate('expert'),
  ];

  final List<String> _availabilityOptions = [
    LocalizationManager.translate('full_time'),
    LocalizationManager.translate('part_time'),
    LocalizationManager.translate('weekends'),
    LocalizationManager.translate('flexible'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentHelper();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentHelper() async {
    try {
      final helper = await SessionService.getCurrentHelper();
      if (helper != null && mounted) {
        setState(() {
          _currentHelper = helper;
          // Pre-populate with helper's municipality
          _selectedServiceAreas = [helper.barangay];
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _currentHelper == null) return;

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate(
              'please_add_at_least_one_skill_to_showcase_your_expertise',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedServiceAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate(
              'please_select_where_you_can_provide_your_services',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate expiry date
    if (_selectedExpiryDate != null &&
        _selectedExpiryDate!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('expiry_date_must_be_in_the_future'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await HelperServicePostingService.createServicePosting(
        helperId: _currentHelper!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _skills,
        experienceLevel: _selectedExperience,
        hourlyRate: double.parse(_hourlyRateController.text),
        availability: _selectedAvailability,
        serviceAreas: _selectedServiceAreas,
        expiresAt: _selectedExpiryDate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationManager.translate('your_service_is_now_live'),
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationManager.translate('failed_to_post_service')}: $e',
            ),
            backgroundColor: Colors.red,
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

  Widget _buildExperienceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExperience,
          isExpanded: true,
          items: _experienceLevels.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(
                level,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedExperience = value;
              });
            }
          },
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  Widget _buildAvailabilityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAvailability,
          isExpanded: true,
          items: _availabilityOptions.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedAvailability = value;
              });
            }
          },
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  Widget _buildServiceAreasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationManager.translate('where_can_you_provide_services'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          LocalizationManager.translate('select_the_municipalities'),
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LocationConstants.boholMunicipalities.map((
                  municipality,
                ) {
                  final isSelected = _selectedServiceAreas.contains(
                    municipality,
                  );
                  return FilterChip(
                    label: Text(
                      municipality,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServiceAreas.add(municipality);
                        } else {
                          _selectedServiceAreas.remove(municipality);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFF8A50),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFFF8A50)
                          : const Color(0xFFE5E7EB),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF8A50)),
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
              colorScheme: const ColorScheme.light(primary: Color(0xFFFF8A50)),
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
        title: Text(
          LocalizationManager.translate('offer_your_services'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8A50),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF8A50,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Color(0xFFFF8A50),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationManager.translate(
                                    'showcase_your_skills',
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  LocalizationManager.translate(
                                    'let_employers_know_services',
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Service Title
                Text(
                  LocalizationManager.translate('what_service_do_you_offer'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _titleController,
                  label: '',
                  hint: LocalizationManager.translate('service_title_hint'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return LocalizationManager.translate(
                        'please_enter_service',
                      );
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  LocalizationManager.translate('describe_what_you_can_do'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationManager.translate('tell_employers'),
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return LocalizationManager.translate(
                        'please_describe_service',
                      );
                    }
                    if (value.trim().length < 20) {
                      return LocalizationManager.translate(
                        'describe_service_min_20',
                      );
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: LocalizationManager.translate(
                      'service_description_hint',
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF8A50),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Skills
                Text(
                  LocalizationManager.translate('your_skills_expertise'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationManager.translate('add_skills_to_showcase'),
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                SkillsInputField(
                  skills: _skills,
                  onSkillsChanged: (newSkills) {
                    setState(() {
                      _skills = newSkills;
                    });
                  },
                  hintText: LocalizationManager.translate('e.g.'),
                ),

                const SizedBox(height: 24),

                // Experience Level
                Text(
                  LocalizationManager.translate('your_experience_level'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationManager.translate(
                    'help_employers_understand_expertise',
                  ),
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                _buildExperienceDropdown(),

                const SizedBox(height: 24),

                // Hourly Rate
                Text(
                  LocalizationManager.translate('your_service_rate'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationManager.translate('set_competitive_rate_hint'),
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _hourlyRateController,
                  label: '',
                  hint: LocalizationManager.translate('hourly_rate_hint'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return LocalizationManager.translate('hourly_rate_empty');
                    }
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return LocalizationManager.translate(
                        'hourly_rate_invalid',
                      );
                    }
                    if (rate < 50) {
                      return LocalizationManager.translate('hourly_rate_min');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Availability
                Text(
                  LocalizationManager.translate('when_can_you_work'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationManager.translate(
                    'let_employers_know_availability',
                  ),
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                _buildAvailabilityDropdown(),

                const SizedBox(height: 24),

                // Service Areas
                _buildServiceAreasSection(),

                const SizedBox(height: 32),

                // Service Expiry Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationManager.translate('available_until'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
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
                              color: const Color(0xFFFF8A50),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocalizationManager.translate(
                        'service_will_not_show_after_expiry_date',
                      ),
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            LocalizationManager.translate(
                              'start_offering_my_services',
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
