import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            title: Text(
              loc.faq,
              style: theme.textTheme.titleMedium,
            ),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
            children: [
              _buildQuestionAnswer(loc.faq_question_1, loc.faq_answer_1, theme),
              const SizedBox(height: 12),
              _buildQuestionAnswer(loc.faq_question_2, loc.faq_answer_2, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionAnswer(String question, String answer, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(70),
          ),
        ),
      ],
    );
  }
}
