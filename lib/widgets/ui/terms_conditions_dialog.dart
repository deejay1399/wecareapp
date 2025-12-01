import 'package:flutter/material.dart';

class TermsConditionsDialog extends StatelessWidget {
  const TermsConditionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),

            // Terms Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'By using WeCare App, you agree to the following:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTermsItem(
                      '• The app connects helpers and employers within Bohol.',
                    ),
                    _buildTermsItem(
                      '• Users must be 18+ and provide truthful information.',
                    ),
                    _buildTermsItem(
                      '• A free trial is available; continued use requires a paid subscription.',
                    ),
                    _buildTermsItem(
                      '• You may post jobs, chat, share location, and accept/reject applications.',
                    ),
                    _buildTermsItem(
                      '• Users are responsible for their own safety and compliance with laws.',
                    ),
                    _buildTermsItem(
                      '• WeCare is not an employer or agency and is not liable for disputes.',
                    ),
                    _buildTermsItem(
                      '• Accounts may be suspended for misuse or violations.',
                    ),
                    _buildTermsItem(
                      '• If the agreed schedule exceeds the 2-hour limit and one party cancels, they must pay the other party the agreed compensation. Failure to pay may allow the affected party to report the issue or request the account to be blocked by the app administrators.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),

            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'I Understand and Agree',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF616161),
          height: 1.4,
        ),
      ),
    );
  }
}
