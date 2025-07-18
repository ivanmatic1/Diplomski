import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class CountrySelector extends StatefulWidget {
  final Country? initialCountry;
  final ValueChanged<Country>? onCountryChanged;

  const CountrySelector({
    super.key,
    this.initialCountry,
    this.onCountryChanged,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  late Country selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry ?? Country.parse('HR');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3);
    final borderColor = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showCountryPicker(
            context: context,
            showPhoneCode: false,
            onSelect: (Country country) {
              setState(() => selectedCountry = country);
              widget.onCountryChanged?.call(country);
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedCountry.flagEmoji} ${selectedCountry.name}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSurface.withAlpha(70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
