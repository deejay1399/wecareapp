import 'package:flutter/material.dart';
import '../../models/helper_service_posting.dart';
import '../../services/helper_service_posting_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../utils/validators/form_validators.dart';
import '../../utils/constants/helper_constants.dart';
import '../../utils/constants/barangay_constants.dart';
import '../../localization_manager.dart';

class EditServiceScreen extends StatefulWidget {
  final HelperServicePosting servicePosting;

  const EditServiceScreen({super.key, required this.servicePosting});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  List<String> _selectedSkills = [];
  String _selectedExperience = '';
  String _selectedAvailability = '';
  List<String> _selectedAreas = [];
  String _currentStatus = '';
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isUpdatingStatus = false;

  final List<String> _availabilityOptions = [
    LocalizationManager.translate('full_time'),
    LocalizationManager.translate('part_time'),
    LocalizationManager.translate('weekends'),
    LocalizationManager.translate('flexible'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.servicePosting.title;
    _descriptionController.text = widget.servicePosting.description;
    _hourlyRateController.text = widget.servicePosting.hourlyRate.toString();
    _selectedSkills = List.from(widget.servicePosting.skills);
    _selectedExperience = widget.servicePosting.experienceLevel;
    _selectedAvailability = widget.servicePosting.availability;
    _selectedAreas = List.from(widget.servicePosting.serviceAreas);
    _currentStatus = widget.servicePosting.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('please_select_one_skill'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAreas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('please_select_one_service_area'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await HelperServicePostingService.updateServicePosting(
        id: widget.servicePosting.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _selectedSkills,
        experienceLevel: _selectedExperience,
        hourlyRate: double.parse(_hourlyRateController.text.trim()),
        availability: _selectedAvailability,
        serviceAreas: _selectedAreas,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('service_updated_successfully'),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LocalizationManager.translate('failed_to_update_service')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteService() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationManager.translate('delete_service')),
        content: Text(
          LocalizationManager.translate('confirm_delete_service_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationManager.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(LocalizationManager.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await HelperServicePostingService.deleteServicePosting(
        widget.servicePosting.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationManager.translate('service_deleted_successfully'),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LocalizationManager.translate('failed_to_delete_service')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _toggleServiceStatus() async {
    final newStatus = _currentStatus == 'active' ? 'paused' : 'active';

    setState(() => _isUpdatingStatus = true);

    try {
      await HelperServicePostingService.updateServicePostingStatus(
        widget.servicePosting.id,
        newStatus,
      );

      if (!mounted) return;

      setState(() {
        _currentStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'active'
                ? LocalizationManager.translate('service_now_active')
                : LocalizationManager.translate('service_now_paused'),
          ),
          backgroundColor: newStatus == 'active'
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LocalizationManager.translate('failed_to_update_service_status')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Color get _statusColor {
    switch (_currentStatus) {
      case 'active':
        return const Color(0xFF10B981);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'inactive':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _statusDisplayText {
    switch (_currentStatus) {
      case 'active':
        return LocalizationManager.translate('status_active');
      case 'paused':
        return LocalizationManager.translate('status_paused');
      case 'inactive':
        return LocalizationManager.translate('status_inactive');
      default:
        return _currentStatus;
    }
  }

  Widget _buildStatusControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentStatus == 'active'
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: _statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocalizationManager.translate('service_visibility'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _statusColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${LocalizationManager.translate('status')}: $_statusDisplayText',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStatus == 'active'
                      ? LocalizationManager.translate(
                          'service_visible_description',
                        )
                      : LocalizationManager.translate(
                          'service_hidden_description',
                        ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                if (_currentStatus != 'inactive') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdatingStatus
                          ? null
                          : _toggleServiceStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStatus == 'active'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isUpdatingStatus
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
                          : Icon(
                              _currentStatus == 'active'
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 20,
                            ),
                      label: Text(
                        _currentStatus == 'active'
                            ? LocalizationManager.translate('pause_service')
                            : LocalizationManager.translate('activate_service'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationManager.translate('edit_your_service'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationManager.translate('update_service_details'),
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Title
            CustomTextField(
              controller: _titleController,
              label: LocalizationManager.translate('service_title'),
              hint: LocalizationManager.translate('service_title_hint'),
              validator: (value) => FormValidators.validateRequired(
                value,
                LocalizationManager.translate('service_title'),
              ),
            ),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: LocalizationManager.translate('service_description'),
              hint: LocalizationManager.translate('service_description_hint'),
              validator: (value) => FormValidators.validateRequired(
                value,
                LocalizationManager.translate('service_description'),
              ),
            ),

            _buildSkillsSelector(),
            const SizedBox(height: 20),
            _buildExperienceDropdown(),
            const SizedBox(height: 20),

            // Hourly Rate
            CustomTextField(
              controller: _hourlyRateController,
              label: LocalizationManager.translate('hourly_rate'),
              hint: LocalizationManager.translate('hourly_rate_hint'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocalizationManager.translate('enter_hourly_rate');
                }
                final rate = double.tryParse(value);
                if (rate == null || rate <= 0) {
                  return LocalizationManager.translate('invalid_hourly_rate');
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Availability
            DropdownButtonFormField<String>(
              initialValue: _selectedAvailability.isEmpty
                  ? null
                  : _selectedAvailability,
              decoration: InputDecoration(
                labelText: LocalizationManager.translate('availability'),
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
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
              ),
              items: _availabilityOptions
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAvailability = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocalizationManager.translate('select_availability');
                }
                return null;
              },
            ),

            const SizedBox(height: 20),
            _buildServiceAreasSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationManager.translate('skills_and_expertise'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HelperConstants.skills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
                selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF1565C0),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExperienceDropdown() {
    final experienceLevels = [
      LocalizationManager.translate('entry_level'),
      LocalizationManager.translate('intermediate'),
      LocalizationManager.translate('experienced'),
      LocalizationManager.translate('expert'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationManager.translate('experience_level'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedExperience.isEmpty ? null : _selectedExperience,
              hint: Text(
                LocalizationManager.translate('select_experience_level'),
                style: const TextStyle(color: Color(0xFF9E9E9E)),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF1565C0),
              ),
              isExpanded: true,
              items: experienceLevels.map((String experience) {
                return DropdownMenuItem<String>(
                  value: experience,
                  child: Text(experience),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedExperience = value ?? '';
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildServiceAreasSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationManager.translate('service_areas'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LocationConstants.boholMunicipalities.map((municipality) {
              final isSelected = _selectedAreas.contains(municipality);
              return FilterChip(
                label: Text(municipality),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAreas.add(municipality);
                    } else {
                      _selectedAreas.remove(municipality);
                    }
                  });
                },
                selectedColor: const Color(0xFFFF8A50).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFFFF8A50),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          // Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving || _isDeleting ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          LocalizationManager.translate('saving_changes'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      LocalizationManager.translate('save_changes'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Delete Service Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isSaving || _isDeleting ? null : _deleteService,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeleting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          LocalizationManager.translate('deleting_service'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      LocalizationManager.translate('delete_service'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationManager.translate('edit_service'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8A50),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8A50)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatusControls(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 24),
              _buildActions(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
