import 'package:flutter/material.dart';
import 'package:terminko/components/custom_bottom_nav_bar.dart';
import 'package:terminko/pages/friend_list_page.dart';
import 'package:terminko/pages/matches_page.dart';
import 'package:terminko/pages/main_home_content.dart';
import 'package:terminko/pages/profile_page.dart';
import 'package:terminko/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;

  final List<Widget> _pages = const [
    FriendListPage(),
    MatchesPage(),
    MainHomeContent(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
