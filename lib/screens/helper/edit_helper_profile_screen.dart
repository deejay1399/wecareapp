import 'package:flutter/material.dart';
import '../../models/helper.dart';
import '../../services/session_service.dart';
import '../../services/helper_auth_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/skills_dropdown.dart';
import '../../widgets/forms/experience_dropdown.dart';
import '../../widgets/forms/barangay_dropdown.dart';
import '../../widgets/forms/file_upload_field.dart';
import '../../widgets/forms/profile_picture_upload_field.dart';
import '../../services/file_picker_service.dart';
import '../../utils/constants/helper_constants.dart';
import '../../utils/constants/barangay_constants.dart';
import '../../utils/validators/form_validators.dart';

class EditHelperProfileScreen extends StatefulWidget {
  final Helper helper;

  const EditHelperProfileScreen({super.key, required this.helper});

  @override
  State<EditHelperProfileScreen> createState() =>
      _EditHelperProfileScreenState();
}

class _EditHelperProfileScreenState extends State<EditHelperProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _selectedMunicipality;
  String? _selectedSkill;
  String? _selectedExperience;
  String? _selectedBarangay;
  String? _barangayClearanceFileName;
  String? _barangayClearanceBase64;
  String? _profilePictureBase64;
  bool _isLoading = false;
  bool _hasChanges = false;
  List<String> _barangayList = [];
  final muniList = LocationConstants.getSortedMunicipalities();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _firstNameController.text = widget.helper.firstName;
    _lastNameController.text = widget.helper.lastName;
    _selectedSkill = widget.helper.skill;
    _selectedExperience = widget.helper.experience;
    _selectedMunicipality = widget.helper.municipality;
    _selectedBarangay = widget.helper.barangay;
    _barangayClearanceBase64 = widget.helper.barangayClearanceBase64;
    _profilePictureBase64 = widget.helper.profilePictureBase64;

    // *** FIX: set barangayList based on initial municipality ***
    _barangayList =
        LocationConstants.municipalityBarangays[_selectedMunicipality] ?? [];

    // Add listeners to detect changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();

    print(widget.helper.barangay);
  }

  Future<void> _pickBarangayClearance() async {
    try {
      final result = await FilePickerService.pickImageWithBase64();

      if (result != null && mounted) {
        setState(() {
          _barangayClearanceFileName = result.fileName;
          _barangayClearanceBase64 = result.base64Data;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await HelperAuthService.updateHelperProfile(
        id: widget.helper.id,
        firstName: _firstNameController.text.trim() != widget.helper.firstName
            ? _firstNameController.text.trim()
            : null,
        lastName: _lastNameController.text.trim() != widget.helper.lastName
            ? _lastNameController.text.trim()
            : null,
        skill: _selectedSkill != widget.helper.skill ? _selectedSkill : null,
        experience: _selectedExperience != widget.helper.experience
            ? _selectedExperience
            : null,
        municipality: _selectedMunicipality != widget.helper.municipality
            ? _selectedMunicipality
            : null,
        barangay: _selectedBarangay != widget.helper.barangay
            ? _selectedBarangay
            : null,
        barangayClearanceBase64:
            _barangayClearanceBase64 != widget.helper.barangayClearanceBase64
            ? _barangayClearanceBase64
            : null,
        profilePictureBase64:
            _profilePictureBase64 != widget.helper.profilePictureBase64
            ? _profilePictureBase64
            : null,
      );

      if (!mounted) return;

      if (result['success']) {
        // Update session with new data
        await SessionService.updateCurrentUser(result['helper'].toMap());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(
          context,
          true,
        ); // Return true to indicate changes were saved
      } else {
        _showErrorMessage(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Update failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(top: 8, left: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back, color: Color(0xFFFF8A50)),
              ),
            ),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFFFF8A50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFFFF8A50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A50),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.handyman,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.helper.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8A50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Helper Profile',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Profile Picture Section
              _buildSectionHeader('Profile Picture'),
              const SizedBox(height: 16),

              ProfilePictureUploadField(
                currentProfilePictureBase64: _profilePictureBase64,
                fullName: widget.helper.fullName,
                onProfilePictureChanged: (String? newProfilePicture) {
                  setState(() {
                    _profilePictureBase64 = newProfilePicture;
                    _hasChanges = true;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Enter your first name',
                validator: (value) =>
                    FormValidators.validateRequired(value, 'first name'),
              ),

              CustomTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Enter your last name',
                validator: (value) =>
                    FormValidators.validateRequired(value, 'last name'),
              ),

              const SizedBox(height: 24),

              // Skills & Experience Section
              _buildSectionHeader('Skills & Experience'),
              const SizedBox(height: 16),

              SkillsDropdown(
                selectedSkill: _selectedSkill,
                skillsList: HelperConstants.skills,
                onChanged: (String? value) {
                  setState(() {
                    _selectedSkill = value;
                    _hasChanges = true;
                  });
                },
              ),

              ExperienceDropdown(
                selectedExperience: _selectedExperience,
                experienceList: HelperConstants.experienceLevels,
                onChanged: (String? value) {
                  setState(() {
                    _selectedExperience = value;
                    _hasChanges = true;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 16),

              _buildReadOnlyField('Email', widget.helper.email),
              _buildReadOnlyField('Phone', widget.helper.phone),

              const SizedBox(height: 24),

              // Location Section
              _buildSectionHeader('Location'),
              const SizedBox(height: 16),

              BarangayDropdown(
                selectedBarangay:
                    (_selectedMunicipality != null &&
                        muniList.contains(_selectedMunicipality))
                    ? _selectedMunicipality
                    : null,
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
                selectedBarangay:
                    _selectedBarangay != null &&
                        _barangayList.contains(_selectedBarangay)
                    ? _selectedBarangay
                    : null,
                barangayList: _barangayList,
                label: 'Select Barangay',
                hint: 'Select your barangay',
                onChanged: (String? value) {
                  setState(() {
                    // Only allow values that exist in _barangayList
                    if (value == null || _barangayList.contains(value)) {
                      _selectedBarangay = value;
                    }
                  });
                },
              ),

              // BarangayDropdown(
              //   selectedBarangay: _selectedBarangay,
              //   barangayList: LocationConstants.getSortedMunicipalities(),
              //   label: 'Location in Bohol',
              //   hint: 'Select your location in Bohol',
              //   onChanged: (String? value) {
              //     setState(() {
              //       _selectedBarangay = value;
              //       _hasChanges = true;
              //     });
              //   },
              // ),
              const SizedBox(height: 24),

              // Documents Section
              _buildSectionHeader('Documents'),
              const SizedBox(height: 16),

              FileUploadField(
                label: 'Barangay Clearance Image',
                fileName:
                    _barangayClearanceFileName ??
                    (widget.helper.barangayClearanceBase64 != null
                        ? 'Current document'
                        : null),
                onTap: _pickBarangayClearance,
                placeholder: 'Upload Barangay Clearance Image (JPG, PNG)',
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A50),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _hasChanges ? 'Save Changes' : 'No Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF8A50),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF8A50),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
