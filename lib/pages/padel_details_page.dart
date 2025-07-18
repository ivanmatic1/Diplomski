import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:terminko/providers/locale_provider.dart';
import 'package:terminko/components/custom_language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/models/sport_details_model.dart';

class PadelDetailsPage extends StatefulWidget {
  final VoidCallback onNext;

  const PadelDetailsPage({super.key, required this.onNext});

  @override
  State<PadelDetailsPage> createState() => _PadelDetailsPageState();
}

class _PadelDetailsPageState extends State<PadelDetailsPage> {
  final Set<String> selectedPositions = {};
  final Set<String> selectedMatchTypes = {};
  TimeOfDay? selectedTime;

  late List<String> allPositionKeys;
  late List<String> allMatchTypeKeys;
  late Map<String, String> positionKeys;
  late Map<String, String> matchTypeKeys;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;

    positionKeys = {
      'Left': loc.padel_position_left,
      'Right': loc.padel_position_right,
      'Flex': loc.padel_position_flexible,
    };

    matchTypeKeys = {
      '2v2': loc.match_type_2v2,
    };

    allPositionKeys = positionKeys.keys.toList();
    allMatchTypeKeys = matchTypeKeys.keys.toList();
  }

  String formatTimeOfDay24h(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (selectedPositions.isEmpty || selectedMatchTypes.isEmpty || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fill_all_fields)),
      );
      return;
    }

    try {
      final model = SportDetailsModel(
        positions: selectedPositions.toList(),
        matchTypes: selectedMatchTypes.toList(),
        preferredTime: formatTimeOfDay24h(selectedTime!),
        location: null,
      );

      await saveSportData('padel', model);

      final user = await getUserById(uid);
      if (user == null) throw Exception("Korisnik nije pronađen");

      widget.onNext();
    } catch (e) {
      debugPrint('Error saving padel details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error_title}: $e')),
      );
    }
  }

  Widget _simpleContainer({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Align(
              alignment: Alignment.topRight,
              child: LanguageSelector(
                onSelect: (langCode) {
                  final provider = Provider.of<LocaleProvider>(context, listen: false);
                  provider.setLocale(Locale(langCode));
                },
              ),
            ),
            const SizedBox(height: 20),
            _simpleContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.padel_details_title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Text(loc.positions_title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: allPositionKeys.map((key) {
                      final displayText = positionKeys[key] ?? key;
                      return FilterChip(
                        label: Text(displayText),
                        selected: selectedPositions.contains(key),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        selectedColor: colorScheme.primary.withAlpha(30),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedPositions.add(key);
                            } else {
                              selectedPositions.remove(key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(loc.match_type_title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: allMatchTypeKeys.map((key) {
                      final displayText = matchTypeKeys[key] ?? key;
                      return FilterChip(
                        label: Text(displayText),
                        selected: selectedMatchTypes.contains(key),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        selectedColor: colorScheme.primary.withAlpha(30),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedMatchTypes.add(key);
                            } else {
                              selectedMatchTypes.remove(key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(loc.preferred_time_title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                      selectedTime != null ? selectedTime!.format(context) : loc.select_time,
                      style: TextStyle(
                        color: selectedTime != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withAlpha(60),
                      ),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _pickTime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      loc.continue_button,
                      style: TextStyle(color: colorScheme.onPrimary, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}