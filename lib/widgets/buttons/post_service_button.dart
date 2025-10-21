import 'package:flutter/material.dart';
import '../../localization_manager.dart';

class PostServiceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PostServiceButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        shadowColor: const Color(0xFFFF8A50).withValues(alpha: 0.3),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF8A50),
                  Color(0xFFFF7A40),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFFFF8A50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  LocalizationManager.translate('post_your_first_service'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
