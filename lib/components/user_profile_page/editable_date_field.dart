import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditableDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final void Function(DateTime) onSave;

  const EditableDateField({
    super.key,
    required this.label,
    required this.value,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final bgColor = isEditing
        ? colorScheme.primary.withAlpha(6)
        : isDark
            ? Colors.white.withAlpha(8)
            : Colors.black.withAlpha(4);

    final borderColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(8);

    final formatted = value != null
        ? DateFormat('yyyy-MM-dd').format(value!)
        : '--';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          isEditing
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Colors.green, size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: value ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) onSave(picked);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: onCancel,
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
        ],
      ),
    );
  }
}
