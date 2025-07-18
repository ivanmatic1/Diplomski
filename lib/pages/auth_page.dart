import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:terminko/pages/home_page.dart';
import 'package:terminko/pages/login_or_register.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:terminko/pages/select_sport_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user == null) {
            return const LoginOrRegisterPage();
          } else {
            return FutureBuilder<bool>(
              future: isUserSetupComplete(user.uid),
              builder: (context, setupSnapshot) {
                if (!setupSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return setupSnapshot.data!
                    ? const HomePage()
                    : const SelectSportPage();
              },
            );
          }
        },
      ),
    );
  }
}
