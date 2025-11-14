import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfilePictureWidget extends StatelessWidget {
  final String? profilePictureBase64;
  final String fullName;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfilePictureWidget({
    super.key,
    this.profilePictureBase64,
    required this.fullName,
    this.size = 80,
    this.onTap,
    this.showEditIcon = false,
    this.backgroundColor,
    this.iconColor,
  });

  // Get initials from full name
  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';

    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '?';
    }

    final firstInitial = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
    final lastInitial = nameParts[nameParts.length - 1].isNotEmpty
        ? nameParts[nameParts.length - 1][0]
        : '';

    return (firstInitial + lastInitial).toUpperCase();
  }

  // Generate background color from name
  Color _generateColorFromName(String name) {
    if (backgroundColor != null) return backgroundColor!;

    final colors = [
      const Color(0xFF1565C0), // Blue
      const Color(0xFFFF8A50), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // Convert base64 to Uint8List
  Uint8List? _decodeBase64(String base64String) {
    try {
      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(fullName);
    final bgColor = _generateColorFromName(fullName);

    Widget profileWidget;

    // If the stored string is a URL, show network image. Otherwise try base64.
    if (profilePictureBase64 != null && profilePictureBase64!.isNotEmpty) {
      final value = profilePictureBase64!.trim();
      if (value.startsWith('http://') || value.startsWith('https://')) {
        profileWidget = ClipOval(
          child: Image.network(
            value,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading network profile image: $error');
              return _buildInitialsAvatar(initials, bgColor);
            },
          ),
        );
      } else {
        final imageBytes = _decodeBase64(value);
        if (imageBytes != null) {
          profileWidget = ClipOval(
            child: Image.memory(
              imageBytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading profile image: $error');
                return _buildInitialsAvatar(initials, bgColor);
              },
            ),
          );
        } else {
          profileWidget = _buildInitialsAvatar(initials, bgColor);
        }
      }
    } else {
      // No profile picture, show initials
      profileWidget = _buildInitialsAvatar(initials, bgColor);
    }

    // Wrap with gesture detector if onTap is provided
    Widget finalWidget = profileWidget;

    if (onTap != null) {
      finalWidget = GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: profileWidget,
        ),
      );
    }

    // Add edit icon if requested
    if (showEditIcon && onTap != null) {
      finalWidget = Stack(
        children: [
          finalWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                color: iconColor ?? Colors.white,
                size: size * 0.15,
              ),
            ),
          ),
        ],
      );
    }

    return finalWidget;
  }

  Widget _buildInitialsAvatar(String initials, Color bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Smaller version for cards and lists
class SmallProfilePictureWidget extends StatelessWidget {
  final String? profilePictureBase64;
  final String fullName;
  final VoidCallback? onTap;

  const SmallProfilePictureWidget({
    super.key,
    this.profilePictureBase64,
    required this.fullName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilePictureWidget(
      profilePictureBase64: profilePictureBase64,
      fullName: fullName,
      size: 40,
      onTap: onTap,
      showEditIcon: false,
    );
  }
}

// Large version for profile screens
class LargeProfilePictureWidget extends StatelessWidget {
  final String? profilePictureBase64;
  final String fullName;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const LargeProfilePictureWidget({
    super.key,
    this.profilePictureBase64,
    required this.fullName,
    this.onTap,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilePictureWidget(
      profilePictureBase64: profilePictureBase64,
      fullName: fullName,
      size: 120,
      onTap: onTap,
      showEditIcon: showEditIcon,
    );
  }
}
