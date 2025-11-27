import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SkillsInputField extends StatefulWidget {
  final List<String> skills;
  final ValueChanged<List<String>> onSkillsChanged;
  final String? errorText;
  final String? title;
  final String? hintText;

  const SkillsInputField({
    super.key,
    required this.skills,
    required this.onSkillsChanged,
    this.errorText,
    this.title,
    this.hintText,
  });

  @override
  State<SkillsInputField> createState() => _SkillsInputFieldState();
}

class _SkillsInputFieldState extends State<SkillsInputField> {
  final TextEditingController _skillController = TextEditingController();
  late List<String> _skills;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.skills);
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill) && _skills.length < 5) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
      widget.onSkillsChanged(_skills);
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
    widget.onSkillsChanged(_skills);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        const SizedBox(height: 8),

        // Skills input field
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.errorText != null
                        ? Colors.red.shade400
                        : const Color(0xFFD1D5DB),
                    width: 1,
                  ),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _skillController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s,.-]')),
                  ],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    hintText: widget.hintText ?? 'Type a skill...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _skills.length >= 5
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _skills.length >= 5 ? null : _addSkill,
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),

        // Skills list
        if (_skills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.asMap().entries.map((entry) {
              final index = entry.key;
              final skill = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeSkill(index),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1565C0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        // Skill count indicator
        const SizedBox(height: 8),
        Text(
          '${_skills.length}/5 skills added',
          style: TextStyle(
            color: _skills.length >= 5
                ? Colors.orange.shade600
                : const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Error text
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
