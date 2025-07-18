import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final focusOverlay = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8);
    final bgColor = _isFocused ? focusOverlay : baseColor;
    final borderColor = isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(10);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        readOnly: widget.onTap != null,
        onTap: widget.onTap,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.prefixIcon,
            color: colorScheme.onSurface.withAlpha(180),
          ),
          suffixIcon: widget.suffixIcon != null
              ? GestureDetector(
                  onTap: widget.onSuffixTap,
                  child: Icon(
                    widget.suffixIcon,
                    color: colorScheme.onSurface.withAlpha(180),
                  ),
                )
              : null,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withAlpha(130),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}
