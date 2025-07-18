import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:terminko/components/login_register_pages/custom_button.dart';
import 'package:terminko/components/login_register_pages/custom_text_field.dart';
import 'package:terminko/components/login_register_pages/custom_box_img.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:terminko/providers/locale_provider.dart';
import 'package:terminko/components/custom_language_selector.dart';
import 'package:terminko/services/google_sign_in_service.dart';
import 'package:terminko/pages/home_page.dart';
import 'package:terminko/pages/select_sport_page.dart';
import 'package:terminko/services/firestore_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final mailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> obscure = ValueNotifier(true);

  void signIn() async {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      switch (e.code) {
        case 'user-not-found':
          showErrorMessage(loc.error_user_not_found);
          break;
        case 'wrong-password':
          showErrorMessage(loc.error_wrong_password);
          break;
        default:
          showErrorMessage('${loc.error_title}: ${e.message}');
      }
    }
  }

  void showErrorMessage(String message) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void resetPassword() async {
    final loc = AppLocalizations.of(context)!;
    if (mailController.text.trim().isEmpty) {
      showErrorMessage(loc.forgot_password_error_entar_email);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: mailController.text.trim());
      showErrorMessage(loc.forgot_password_succ);
    } catch (e) {
      showErrorMessage(loc.forgot_password_fail);
    }
  }

  Future<void> handleGoogleLogin() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final userCred = await signInWithGoogle();
      if (userCred == null) return;

      final uid = userCred.user?.uid;
      if (!mounted || uid == null) return;

      final user = await getUserById(uid);
      final setupComplete = user?.isSetupComplete ?? false;


      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => setupComplete ? const HomePage() : const SelectSportPage(),
        ),
      );
    } catch (e) {
      showErrorMessage("${loc.error_title}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.topRight,
                child: LanguageSelector(
                  onSelect: (langCode) {
                    final provider = Provider.of<LocaleProvider>(context, listen: false);
                    provider.setLocale(Locale(langCode));
                  },
                ),
              ),
              const SizedBox(height: 10),
              Image.asset('lib/images/logo.png', width: 100, height: 100),
              const SizedBox(height: 10),
              Text(
                loc.login_title,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              Text(
                loc.login_description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0x99)),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomTextField(
                        hintText: loc.email_hint,
                        prefixIcon: Icons.email_outlined,
                        controller: mailController,
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder(
                        valueListenable: obscure,
                        builder: (context, value, _) {
                          return CustomTextField(
                            hintText: loc.password_hint,
                            prefixIcon: Icons.lock_outline,
                            controller: passwordController,
                            obscureText: value,
                            suffixIcon: value ? Icons.visibility_off : Icons.visibility,
                            onSuffixTap: () => obscure.value = !obscure.value,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: resetPassword,
                            child: Text(
                              loc.forgot_password,
                              style: TextStyle(
                                color: colorScheme.primary.withAlpha(80),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      CustomButton(onTap: signIn, text: loc.sign_in),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: Divider(thickness: 0.5, color: colorScheme.outline)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              loc.or_continue,
                              style: TextStyle(color: colorScheme.onSurface.withAlpha(60)),
                            ),
                          ),
                          Expanded(child: Divider(thickness: 0.5, color: colorScheme.outline)),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomBoxImg(
                            imagePath: 'lib/images/google.png',
                            onTap: handleGoogleLogin,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.not_member,
                            style: TextStyle(color: colorScheme.onSurface.withAlpha(70)),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Text(
                              loc.register_now,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
