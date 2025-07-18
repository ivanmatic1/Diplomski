import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';

import 'package:terminko/components/login_register_pages/custom_button.dart';
import 'package:terminko/components/login_register_pages/custom_text_field.dart';
import 'package:terminko/components/register_page/country_selector.dart';
import 'package:terminko/components/custom_language_selector.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:terminko/providers/locale_provider.dart';
import 'package:terminko/pages/select_sport_page.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final mailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? selectedDate;

  Country selectedCountry = Country.parse('HR');

 Future<void> signUp() async {
    final loc = AppLocalizations.of(context)!;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final langCode = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    if ([firstnameController, lastnameController, mailController, passwordController, confirmPasswordController, phoneController, birthDateController]
        .any((controller) => controller.text.trim().isEmpty)) {
      showErrorMessage(loc.error_fill_in_all_fields);
      return;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      showErrorMessage(loc.error_password_mismatch);
      return;
    }

    final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length < 9) {
      showErrorMessage(loc.error_invalid_phone);
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await createUser(
        email: cred.user!.email!,
        firstName: firstnameController.text.trim(),
        lastName: lastnameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        country: selectedCountry.countryCode,
        dateOfBirth: birthDateController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'fcmToken': fcmToken,
        'language': langCode,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SelectSportPage()));
    } on FirebaseAuthException catch (e) {
      final errorMap = {
        'email-already-in-use': loc.error_email_in_use,
        'invalid-email': loc.error_invalid_email,
        'weak-password': loc.error_weak_password,
      };
      showErrorMessage(errorMap[e.code] ?? '${loc.error_title}: ${e.message}');
    } catch (e) {
      showErrorMessage('${loc.error_title}: $e');
    }
  }



  void showErrorMessage(String message) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.error_title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        birthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          children: [
            Align(
              alignment: Alignment.topRight,
              child: LanguageSelector(
                onSelect: (langCode) {
                  Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(langCode));
                },
              ),
            ),
            const SizedBox(height: 10),
            Image.asset('lib/images/logo.png', width: 100, height: 100),
            const SizedBox(height: 10),
            Text(loc.register_title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(loc.register_description, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(150))),
            const SizedBox(height: 30),

            CustomTextField(controller: firstnameController, hintText: loc.firstname_hint, obscureText: false, prefixIcon: Icons.person),
            const SizedBox(height: 10),
            CustomTextField(controller: lastnameController, hintText: loc.lastname_hint, prefixIcon: Icons.person, obscureText: false),
            const SizedBox(height: 10),
            CustomTextField(controller: mailController, hintText: loc.email_hint, prefixIcon: Icons.email_outlined, obscureText: false),
            const SizedBox(height: 10),
            CustomTextField(controller: passwordController, hintText: loc.password_hint, prefixIcon: Icons.lock_outline, obscureText: true),
            const SizedBox(height: 10),
            CustomTextField(controller: confirmPasswordController, hintText: loc.confirm_password_hint, prefixIcon: Icons.lock_outline, obscureText: true),
            const SizedBox(height: 10),
            CustomTextField(controller: birthDateController, hintText: loc.birth_date_label, prefixIcon: Icons.calendar_today, obscureText: false, onTap: _pickDate),
            const SizedBox(height: 10),
            CountrySelector(onCountryChanged: (country) => setState(() => selectedCountry = country)),
            const SizedBox(height: 10),
            CustomTextField(controller: phoneController, hintText: loc.phone_hint, prefixIcon: Icons.phone, obscureText: false),
            const SizedBox(height: 25),

            CustomButton(onTap: signUp, text: loc.register_button),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.already_have_account, style: TextStyle(color: colorScheme.onSurface.withAlpha(150))),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(loc.go_to_login, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
