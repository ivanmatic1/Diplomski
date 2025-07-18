import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:terminko/theme/theme.dart';
import 'package:terminko/pages/auth_page.dart';
import 'package:terminko/pages/friend_list_page.dart';
import 'package:terminko/l10n/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:terminko/providers/locale_provider.dart';
import 'package:terminko/providers/theme_provider.dart';
import 'package:terminko/components/home_page/match_confirmation_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission();

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage?.data['type'] == 'friend_request') {
    Future.delayed(Duration.zero, () {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const FriendListPage()),
      );
    });
  }

  runApp(const MyApp());

  setupFCMListener();
}

void setupFCMListener() {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final type = message.data['type'];

    if (type == 'friend_request' || type == 'friend_accepted') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const FriendListPage()),
      );
    }

    if (type == 'match_found') {
      final matchId = message.data['matchId'];
      final sportId = message.data['sportId'];
      if (matchId != null && sportId != null && navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (_) => MatchConfirmationDialog(
            matchId: matchId,
            sportId: sportId,
          ),
        );
      }
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final type = message.data['type'];

    if (type == 'match_found') {
      final matchId = message.data['matchId'];
      final sportId = message.data['sportId'];
      if (matchId != null && sportId != null && navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (_) => MatchConfirmationDialog(
            matchId: matchId,
            sportId: sportId,
          ),
        );
      }
    }
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            supportedLocales: L10n.all,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: localeProvider.locale,
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: themeProvider.themeMode,
            home: const AuthPage(),
          );
        },
      ),
    );
  }
}
