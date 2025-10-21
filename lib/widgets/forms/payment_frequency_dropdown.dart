import 'package:flutter/material.dart';
import '../../utils/constants/payment_frequency_constants.dart';
import '../../localization_manager.dart';

class PaymentFrequencyDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const PaymentFrequencyDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationManager.translate('payment_frequency'),
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
              color: errorText != null
                  ? Colors.red.shade400
                  : const Color(0xFFD1D5DB),
              width: 1,
            ),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              hintText: LocalizationManager.translate(
                'select_payment_frequency',
              ),
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
            style: const TextStyle(color: Color(0xFF374151), fontSize: 16),
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF6B7280),
            ),
            items: PaymentFrequencyConstants.frequencies.map((frequency) {
              return DropdownMenuItem<String>(
                value: frequency,
                child: Text(
                  PaymentFrequencyConstants.frequencyLabels[frequency] ??
                      frequency,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
