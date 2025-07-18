import 'package:flutter/material.dart';
import 'package:terminko/models/user_model.dart';

class EditableProfileField extends StatefulWidget {
  final String label;
  final String fieldKey;
  final UserModel user;
  final bool isEditing;
  final ValueChanged<String> onChanged;
  final VoidCallback onEdit;
  final void Function(String) onSave;
  final VoidCallback onCancel;
  final TextInputType keyboardType;

  const EditableProfileField({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.user,
    required this.isEditing,
    required this.onChanged,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<EditableProfileField> createState() => _EditableProfileFieldState();
}

class _EditableProfileFieldState extends State<EditableProfileField> {
  late TextEditingController _controller;

  String _getFieldValue() {
    switch (widget.fieldKey) {
      case 'email':
        return widget.user.email;
      case 'phone':
        return widget.user.phone ?? '';
      case 'birthDate':
        return widget.user.birthDate != null
            ? "${widget.user.birthDate!.year}-${widget.user.birthDate!.month.toString().padLeft(2, '0')}-${widget.user.birthDate!.day.toString().padLeft(2, '0')}"
            : '';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getFieldValue());
  }

  @override
  void didUpdateWidget(covariant EditableProfileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_getFieldValue() != _controller.text) {
      _controller.text = _getFieldValue();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.isEditing
        ? theme.colorScheme.primary.withAlpha(6)
        : isDark
            ? Colors.white.withAlpha(8)
            : Colors.black.withAlpha(4);

    final borderColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(8);

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
                Text(widget.label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                widget.isEditing
                    ? TextField(
                        autofocus: true,
                        controller: _controller,
                        onChanged: widget.onChanged,
                        keyboardType: widget.keyboardType,
                        style: theme.textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        _getFieldValue(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
          widget.isEditing
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 20),
                      onPressed: () => widget.onSave(_controller.text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: widget.onCancel,
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: widget.onEdit,
                ),
        ],
      ),
    );
  }
}
