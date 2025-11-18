import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../widgets/forms/custom_text_field.dart';
import '../widgets/forms/birthday_picker_field.dart';
import '../widgets/forms/phone_text_field.dart';
import '../widgets/forms/experience_dropdown.dart';
import '../widgets/forms/barangay_dropdown.dart';
import '../widgets/forms/file_upload_field.dart';
import '../widgets/forms/profile_picture_upload_field.dart';
import '../widgets/forms/terms_agreement_checkbox.dart';
import '../widgets/common/section_header.dart';
import '../utils/constants/helper_constants.dart';
import '../utils/constants/barangay_constants.dart';
import '../utils/validators/form_validators.dart';
import '../services/file_picker_service.dart';
import '../services/helper_auth_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class HelperRegisterScreen extends StatefulWidget {
  const HelperRegisterScreen({super.key});

  @override
  State<HelperRegisterScreen> createState() => _HelperRegisterScreenState();
}

class _HelperRegisterScreenState extends State<HelperRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedMunicipality;
  List<String> _selectedSkills = [];
  String? _selectedExperience;
  String? _selectedBarangay;
  String? _barangayClearanceFileName;
  String? _barangayClearanceBase64;
  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isPickingFile = false;
  DateTime? _selectedBirthday;
  bool _aiVerifying = false;
  bool _aiVerified = false;
  double _aiConfidence = 0.0;
  List<String> _barangayList = [];
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _computeConfidence({
    required String ocrText,
    required bool hasKeywords,
    required bool nameMatch,
  }) {
    double score = 10.0;
    if (hasKeywords) score += 30.0;

    if (nameMatch) score += 40.0;

    final lengthFactor = (ocrText.length.clamp(0, 200) / 200.0) * 20.0;
    score += lengthFactor;
    if (score > 100.0) score = 100.0;
    return double.parse(score.toStringAsFixed(1));
  }

  Future<bool> _verifyBarangayClearanceAI(String base64Image) async {
    setState(() {
      _aiVerifying = true;
      _aiVerified = false;
      _aiConfidence = 0.0;
    });

    try {
      // Convert Base64 image to File
      final bytes = base64Decode(base64Image);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_barangay_clearance.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Initialize text recognizer
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognizedText.text.toLowerCase();
      debugPrint('DEBUG: OCR extracted text: $text');

      // Basic checks for keywords
      final hasBarangay = text.contains('barangay');
      final hasClearance = text.contains('clearance');
      final hasKeywords = hasBarangay && hasClearance;

      // Name matching (loose)
      final first = _firstNameController.text.trim().toLowerCase();
      final last = _lastNameController.text.trim().toLowerCase();
      final nameMatch =
          first.isNotEmpty &&
          last.isNotEmpty &&
          text.contains(first) &&
          text.contains(last);

      // Compute confidence
      final confidence = _computeConfidence(
        ocrText: text,
        hasKeywords: hasKeywords,
        nameMatch: nameMatch,
      );

      setState(() {
        _aiConfidence = confidence;
        // decide verified if confidence >= 70 (heuristic)
        _aiVerified = confidence >= 70.0;
      });

      // Provide clear messages for user
      if (!_aiVerified) {
        if (!hasKeywords) {
          _showErrorMessage(
            'AI check failed: document does not look like a Barangay Clearance.',
          );
        } else if (!nameMatch) {
          _showErrorMessage(
            'AI check failed: name on document does not match the form.',
          );
        } else {
          _showErrorMessage(
            'AI check failed: document quality too low. Try a clearer photo.',
          );
        }
      }

      return _aiVerified;
    } catch (e) {
      debugPrint('AI Verification Error: $e');
      _showErrorMessage(
        'Failed to verify document. Please upload a clearer image.',
      );
      setState(() {
        _aiConfidence = 0.0;
        _aiVerified = false;
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _aiVerifying = false;
        });
      }
    }
  }

  Future<void> _pickBarangayClearance() async {
    // Prevent multiple concurrent file picks
    if (_isPickingFile) {
      _showErrorMessage(
        'File picker is already open. Please wait for the current operation to complete.',
      );
      return;
    }

    // Check if file picker is already active globally (if your service exposes it)
    if (FilePickerService.isPickerActive) {
      _showErrorMessage(
        'Another file picker operation is in progress. Please wait and try again.',
      );
      return;
    }

    setState(() => _isPickingFile = true);

    try {
      debugPrint('DEBUG: Starting file picker...');

      final result = await FilePickerService.pickImageWithBase64();
      debugPrint(
        'DEBUG: File picker result: ${result != null ? 'Success' : 'Cancelled'}',
      );

      if (result != null && mounted) {
        debugPrint(
          'DEBUG: File selected - Name: ${result.fileName}, Base64 length: ${result.base64Data.length}',
        );
        setState(() {
          _barangayClearanceFileName = result.fileName;
          _barangayClearanceBase64 = result.base64Data;
          // reset previous AI state on new upload
          _aiVerified = false;
          _aiConfidence = 0.0;
        });

        // Show verifying indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifying Barangay Clearance with AI...'),
            backgroundColor: Colors.blue,
          ),
        );

        final verified = await _verifyBarangayClearanceAI(result.base64Data);

        if (!verified) {
          setState(() {
            _barangayClearanceBase64 = null;
            _barangayClearanceFileName = null;
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barangay Clearance verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == null) {
        debugPrint('DEBUG: File selection cancelled by user.');
      }
    } catch (e) {
      debugPrint('DEBUG: File picker error: $e');
      _showErrorMessage('Error picking file: $e');
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      _showErrorMessage('Please select at least one skill');
      return;
    }

    if (_selectedExperience == null) {
      _showErrorMessage('Please select your years of experience');
      return;
    }

    if (_selectedBarangay == null) {
      _showErrorMessage('Please select your barangay');
      return;
    }

    if (_barangayClearanceBase64 == null) {
      _showErrorMessage('Please upload your barangay clearance image');
      return;
    }

    if (!_agreeToTerms) {
      _showErrorMessage(
        'Please agree to the terms of service and privacy policy',
      );
      return;
    }

    if (!SupabaseService.isInitialized) {
      _showErrorMessage(
        'Database connection not available. Please check your configuration.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format phone number to include +63 prefix
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+63')) {
        phoneNumber = '+63$phoneNumber';
      }

      final result = await HelperAuthService.registerHelper(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phoneNumber,
        birthdate: _birthdayController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        password: _passwordController.text,
        skills: _selectedSkills,
        experience: _selectedExperience!,
        municipality: _selectedMunicipality!,
        barangay: _selectedBarangay!,
        barangayClearanceBase64: _barangayClearanceBase64,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['message']} Please log in to continue.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(userType: 'Helper'),
          ),
        );
      } else {
        // Registration failed
        _showErrorMessage(result['message']);
      }
    } catch (e) {
      debugPrint('DEBUG: Registration exception: $e');
      if (!mounted) return;
      _showErrorMessage('Registration failed: $e');
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

  Widget _buildAiStatusWidget() {
    if (_isPickingFile) {
      return const SizedBox();
    }

    if (_aiVerifying) {
      return Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Verifying document...', style: TextStyle(color: Colors.blue)),
        ],
      );
    }

    if (_aiConfidence > 0) {
      final verified = _aiVerified;
      final color = verified ? Colors.green : Colors.red;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(verified ? Icons.check_circle : Icons.error, color: color),
          const SizedBox(width: 8),
          Text(
            'AI Confidence: ${_aiConfidence.toStringAsFixed(1)}% — ${verified ? 'Verified' : 'Failed'}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
            'Helper Registration',
            style: TextStyle(
              color: Color(0xFFFF8A50),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // // Profile Picture Section (Optional)
                // const SectionHeader(title: 'Profile Picture (Optional)'),

                // ProfilePictureUploadField(
                //   currentProfilePictureBase64: _profilePictureBase64,
                //   fullName:
                //       '${_firstNameController.text} ${_lastNameController.text}',
                //   onProfilePictureChanged: (String? newProfilePicture) {
                //     setState(() {
                //       _profilePictureBase64 = newProfilePicture;
                //     });
                //   },
                //   label: 'Profile Picture (Optional)',
                // ),

                // Personal Information Section
                const SectionHeader(title: 'Personal Information'),

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

                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[A-Z]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(
                        text: newValue.text.toLowerCase(),
                      );
                    }),
                  ],
                  validator: FormValidators.validateEmail,
                ),

                PhoneTextField(
                  controller: _phoneController,
                  validator: FormValidators.validatePhoneNumber,
                ),

                BirthdayPickerField(
                  birthdayController: _birthdayController,
                  ageController: _ageController,
                  label: 'Birthday',
                  hint: 'Select your birthday',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your birthday';
                    }
                    return null;
                  },
                ),

                CustomTextField(
                  controller: _ageController,
                  label: 'Age',
                  hint: 'Enter your age (18+)',
                  keyboardType: TextInputType.number,
                  validator: FormValidators.validateAge,
                ),

                const SectionHeader(title: 'Skills & Experience'),

                GestureDetector(
                  onTap: () async {
                    final List<String> skills = HelperConstants.skills;
                    final List<String>? selected =
                        await showDialog<List<String>>(
                          context: context,
                          builder: (BuildContext context) {
                            final tempSelected = List<String>.from(
                              _selectedSkills,
                            );
                            return AlertDialog(
                              title: const Text('Select Your Skills'),
                              content: StatefulBuilder(
                                builder: (context, setState) {
                                  return SingleChildScrollView(
                                    child: Column(
                                      children: skills.map((skill) {
                                        final isSelected = tempSelected
                                            .contains(skill);
                                        return CheckboxListTile(
                                          title: Text(skill),
                                          value: isSelected,
                                          onChanged: (bool? checked) {
                                            setState(() {
                                              if (checked == true) {
                                                tempSelected.add(skill);
                                              } else {
                                                tempSelected.remove(skill);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8A50),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, tempSelected),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );

                    if (selected != null) {
                      setState(() => _selectedSkills = selected);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedSkills.isEmpty
                                ? 'Select your skills'
                                : _selectedSkills.join(', '),
                            style: TextStyle(
                              color: _selectedSkills.isEmpty
                                  ? Colors.grey.shade600
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ExperienceDropdown(
                  selectedExperience: _selectedExperience,
                  experienceList: HelperConstants.experienceLevels,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedExperience = value;
                    });
                  },
                ),

                // Location Section
                const SectionHeader(title: 'Location'),

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

                const SectionHeader(title: 'Required Documents'),
                FileUploadField(
                  label: 'Barangay Clearance Image',
                  fileName: _barangayClearanceFileName,
                  onTap: _isPickingFile ? null : _pickBarangayClearance,
                  placeholder: _isPickingFile
                      ? 'Selecting file...'
                      : 'Upload Barangay Clearance Image (JPG, PNG)',
                  isLoading: _isPickingFile,
                ),
                const SizedBox(height: 8),
                _buildAiStatusWidget(),
                const SizedBox(height: 16),

                // Security Section
                const SectionHeader(title: 'Security'),

                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  isPassword: true,
                  isPasswordVisible: _isPasswordVisible,
                  onPasswordToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: FormValidators.validatePassword,
                ),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Verify Password',
                  hint: 'Re-enter your password',
                  isPassword: true,
                  isPasswordVisible: _isConfirmPasswordVisible,
                  onPasswordToggle: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) => FormValidators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),

                // Terms and Conditions
                TermsAgreementCheckbox(
                  isAgreed: _agreeToTerms,
                  onChanged: (bool value) {
                    setState(() {
                      _agreeToTerms = value;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A50),
                      foregroundColor: Colors.white,
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
                        : const Text(
                            'Register as Helper',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
