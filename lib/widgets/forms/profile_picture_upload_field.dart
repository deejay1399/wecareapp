import 'package:flutter/material.dart';
import '../ui/profile_picture_widget.dart';
import '../../services/file_picker_service.dart';

class ProfilePictureUploadField extends StatefulWidget {
  final String? currentProfilePictureBase64;
  final String fullName;
  final Function(String?) onProfilePictureChanged;
  final String label;

  const ProfilePictureUploadField({
    super.key,
    this.currentProfilePictureBase64,
    required this.fullName,
    required this.onProfilePictureChanged,
    this.label = 'Profile Picture',
  });

  @override
  State<ProfilePictureUploadField> createState() =>
      _ProfilePictureUploadFieldState();
}

class _ProfilePictureUploadFieldState extends State<ProfilePictureUploadField> {
  String? _profilePictureBase64;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _profilePictureBase64 = widget.currentProfilePictureBase64;
  }

  Future<void> _pickProfilePicture() async {
    // Prevent multiple concurrent file picks
    if (_isPickingFile) {
      _showErrorMessage(
        'File picker is already open. Please wait for the current operation to complete.',
      );
      return;
    }

    // Check if file picker is already active globally
    if (FilePickerService.isPickerActive) {
      _showErrorMessage(
        'Another file picker operation is in progress. Please wait and try again.',
      );
      return;
    }

    setState(() => _isPickingFile = true);

    try {
      debugPrint('DEBUG: Starting profile picture picker...');
      // Get both filename and base64 data in single call
      // Allow larger profile pictures (10MB) while keeping other uploads at the default 5MB
      final result = await FilePickerService.pickImageWithBase64(
        maxFileSizeBytes: 10 * 1024 * 1024,
      );
      debugPrint(
        'DEBUG: Profile picture picker result: ${result != null ? 'Success' : 'Cancelled'}',
      );

      if (result != null && mounted) {
        debugPrint(
          'DEBUG: Profile picture selected - Name: ${result.fileName}, Base64 length: ${result.base64Data.length}',
        );
        setState(() {
          _profilePictureBase64 = result.base64Data;
        });

        // Notify parent widget
        widget.onProfilePictureChanged(_profilePictureBase64);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile picture "${result.fileName}" uploaded successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint('DEBUG: Profile picture upload state updated successfully');
      } else if (result == null) {
        debugPrint('DEBUG: Profile picture selection was cancelled by user');
      }
    } catch (e) {
      debugPrint('DEBUG: Profile picture picker error: $e');
      if (!mounted) return;

      String errorMessage = e.toString();
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  void _removeProfilePicture() {
    setState(() {
      _profilePictureBase64 = null;
    });
    widget.onProfilePictureChanged(null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture removed'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 16),

        // Profile picture display and controls
        Center(
          child: Column(
            children: [
              // Profile picture widget
              LargeProfilePictureWidget(
                profilePictureBase64: _profilePictureBase64,
                fullName: widget.fullName,
                onTap: _isPickingFile ? null : _pickProfilePicture,
                showEditIcon: true,
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Upload/Change button
                  ElevatedButton.icon(
                    onPressed: _isPickingFile ? null : _pickProfilePicture,
                    icon: _isPickingFile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      _isPickingFile
                          ? 'Uploading...'
                          : (_profilePictureBase64 != null
                                ? 'Change'
                                : 'Upload'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Remove button (only show if there's a profile picture)
                  if (_profilePictureBase64 != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _removeProfilePicture,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Help text
              Text(
                'Upload a JPG or PNG image (max 10MB)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
