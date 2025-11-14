import 'package:flutter/material.dart';

class ExperienceDropdown extends StatelessWidget {
  final String? selectedExperience;
  final List<String> experienceList;
  final ValueChanged<String?> onChanged;

  const ExperienceDropdown({
    super.key,
    required this.selectedExperience,
    required this.experienceList,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Years of Experience',
          style: TextStyle(
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
              value: selectedExperience,
              hint: const Text(
                'Select years of experience',
                style: TextStyle(color: Color(0xFF9E9E9E)),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF1565C0),
              ),
              isExpanded: true,
              items: experienceList.map((String experience) {
                return DropdownMenuItem<String>(
                  value: experience,
                  child: Text(
                    experience.contains('year')
                        ? experience
                        : '$experience years',
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
