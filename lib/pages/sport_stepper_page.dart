import 'package:flutter/material.dart';
import 'package:terminko/pages/football_details_page.dart';
import 'package:terminko/pages/basketball_details_page.dart';
import 'package:terminko/pages/padel_details_page.dart';
import 'package:terminko/pages/select_distance_page.dart';

class SportStepperPage extends StatefulWidget {
  final List<String> sportList;

  const SportStepperPage({super.key, required this.sportList});

  @override
  State<SportStepperPage> createState() => _SportStepperPageState();
}

class _SportStepperPageState extends State<SportStepperPage> {
  int currentSportIndex = 0;

  void goToNextSport() {
    if (!mounted) return;

    if (currentSportIndex + 1 < widget.sportList.length) {
      setState(() => currentSportIndex++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SelectDistancePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSport = widget.sportList[currentSportIndex];

    switch (currentSport) {
      case 'football':
        return FootballDetailsPage(onNext: goToNextSport);
      case 'basketball':
        return BasketballDetailsPage(onNext: goToNextSport);
      case 'padel':
        return PadelDetailsPage(onNext: goToNextSport);
      default:
        return Scaffold(
          body: Center(child: Text("Nepoznat sport: $currentSport")),
        );
    }
  }
}
