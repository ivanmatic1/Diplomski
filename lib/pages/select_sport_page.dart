import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/register_page/custom_checkbox.dart';
import 'package:terminko/pages/sport_stepper_page.dart';
import 'package:terminko/components/custom_language_selector.dart';
import 'package:terminko/providers/locale_provider.dart';
import 'package:terminko/models/user_model.dart';

class SelectSportPage extends StatefulWidget {
  const SelectSportPage({super.key});

  @override
  State<SelectSportPage> createState() => _SelectSportPageState();
}

class _SelectSportPageState extends State<SelectSportPage> {
  bool playFootball = false;
  bool playBasketball = false;
  bool playPadel = false;

  bool _isLoading = false;

  void _submit() async {
    final loc = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final selectedSports = <String>[];

    if (playFootball) selectedSports.add('football');
    if (playBasketball) selectedSports.add('basketball');
    if (playPadel) selectedSports.add('padel');

    if (selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.select_at_least_one_sport)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await getUserById(uid);
      if (user == null) throw Exception("Korisnik nije pronađen");

      final updatedUser = UserModel(
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        language: user.language,
        birthDate: user.birthDate,
        socialScore: user.socialScore,
        isSetupComplete: user.isSetupComplete,
        selectedSports: selectedSports,
        positions: user.positions,
      );

      await updateUserModel(updatedUser);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SportStepperPage(sportList: selectedSports),
        ),
      );
    } catch (e) {
      debugPrint("Greška kod spremanja sportova: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Greška pri spremanju sportova.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? Colors.white.withAlpha(8)
        : Colors.black.withAlpha(5);
    final borderColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(5);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.select_sport_title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.select_sport_description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withAlpha(70),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  CustomCheckboxField(
                    labelText: loc.football,
                    value: playFootball,
                    prefixIcon: Icons.sports_soccer,
                    onChanged: (value) => setState(() => playFootball = value ?? false),
                  ),
                  const SizedBox(height: 12),

                  CustomCheckboxField(
                    labelText: loc.basketball,
                    value: playBasketball,
                    prefixIcon: Icons.sports_basketball,
                    onChanged: (value) => setState(() => playBasketball = value ?? false),
                  ),
                  const SizedBox(height: 12),

                  CustomCheckboxField(
                    labelText: loc.padel,
                    value: playPadel,
                    prefixIcon: Icons.sports_tennis,
                    onChanged: (value) => setState(() => playPadel = value ?? false),
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
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
