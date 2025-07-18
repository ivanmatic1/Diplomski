import 'package:flutter/material.dart';

class CustomBoxImg extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;

  const CustomBoxImg({
    super.key,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? Colors.white.withAlpha(8)
        : Colors.black.withAlpha(5);

    final borderColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
            imagePath,
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
