import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;

  const CustomButton({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDisabled = onTap == null;

    final backgroundColor = isDisabled
        ? colorScheme.onSurface.withAlpha(12)
        : colorScheme.primary.withAlpha(85);

    final textColor = isDisabled
        ? colorScheme.onSurface.withAlpha(60)
        : colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDisabled
                    ? colorScheme.onSurface.withAlpha(10)
                    : colorScheme.primary.withAlpha(30),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
