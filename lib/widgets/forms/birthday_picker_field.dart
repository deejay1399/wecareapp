import 'package:flutter/material.dart';

class BirthdayPickerField extends StatelessWidget {
  final TextEditingController birthdayController;
  final TextEditingController ageController;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const BirthdayPickerField({
    super.key,
    required this.birthdayController,
    required this.ageController,
    this.label = 'Birthday',
    this.hint = 'Select your birthday',
    this.validator,
  });

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
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
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: birthdayController,
            readOnly: true,
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                birthdayController.text =
                    "${pickedDate.toLocal()}".split(' ')[0];
                int age = _calculateAge(pickedDate);
                ageController.text = age.toString();
              }
            },
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your birthday';
                  }
                  return null;
                },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              prefixIcon: const Icon(Icons.cake, color: Color(0xFF9E9E9E)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
