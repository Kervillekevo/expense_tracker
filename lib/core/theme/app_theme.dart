import 'package:flutter/material.dart';

class AppColors {
  static const dark = Color(0xFF0F3D2E);
  static const primary = Color(0xFF2E7D5B);
  static const accent = Color(0xFFF2D43D);
  static const sheet = Color(0xFFEAF6D6);
  static const field = Color(0xFFF6FBEC);
  static const border = Color(0xFFCFE3B8);
  static const expense = Color(0xFFC62828);
  static const income = Color(0xFF2E7D5B);
  static const muted = Color(0xFF6B7F74);
}

InputDecoration fieldDecoration({
  String? hint,
  String? label,
  IconData? icon,
  Widget? suffix,
  Color fill = AppColors.field,
}) {
  OutlineInputBorder outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    labelText: label,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: outline(AppColors.border),
    enabledBorder: outline(AppColors.border),
    focusedBorder: outline(AppColors.primary, 1.6),
    errorBorder: outline(AppColors.expense),
    focusedErrorBorder: outline(AppColors.expense, 1.6),
  );
}

class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.activeColors,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, Color>? activeColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          final color = activeColors?[option] ?? AppColors.dark;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}