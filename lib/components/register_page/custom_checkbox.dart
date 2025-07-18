import 'package:flutter/material.dart';

class CustomCheckboxField extends StatelessWidget {
  final String labelText;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final IconData? prefixIcon;

  const CustomCheckboxField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final bgColor = isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3);
    final borderColor = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (prefixIcon != null)
            Icon(prefixIcon, color: colorScheme.onSurface.withAlpha(70)),
          if (prefixIcon != null)
            const SizedBox(width: 10),
          Expanded(
            child: Text(
              labelText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
            checkColor: colorScheme.onPrimary,
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }
}
