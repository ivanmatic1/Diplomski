import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final Function(String) onSelect;

  const LanguageSelector({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;

    return PopupMenuButton<String>(
      onSelected: onSelect,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              Text('🇬🇧'),
              SizedBox(width: 8),
              Text('English'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'hr',
          child: Row(
            children: [
              Text('🇭🇷'),
              SizedBox(width: 8),
              Text('Hrvatski'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localeCode == 'hr' ? '🇭🇷' : '🇬🇧',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 6),
            Text(
              localeCode.toUpperCase(),
              style: TextStyle(color: colorScheme.onSurface),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}
