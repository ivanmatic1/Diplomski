import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/user_profile_page/profile_header_section.dart';
import 'package:terminko/components/user_profile_page/profile_stats_section.dart';
import 'package:terminko/services/profile_page_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/models/stat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  StatModel globalStats = StatModel.empty();
  Map<String, StatModel> sportStats = {};
  List<String> selectedSports = [];
  bool isLoading = true;

  bool isEditingEmail = false;
  bool isEditingPhone = false;
  bool isEditingPassword = false;
  bool isEditingBirthDate = false;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userSubscription = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snapshot) async {
        if (!snapshot.exists) return;
        final user = UserModel.fromMap(snapshot.id, snapshot.data()!);
        final global = await fetchGlobalStatsModel();
        final sports = await fetchSelectedSports();
        final statsBySport = await fetchStatsBySportModel(sports);

        if (mounted) {
          setState(() {
            _user = user;
            globalStats = global;
            sportStats = statsBySport;
            selectedSports = sports;
            isLoading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = await uploadProfileImage(File(pickedFile.path));
      if (url != null && _user != null) {
        await updateUserProfile(imageUrl: url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.profile),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: isLoading || _user == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeaderSection(
                      user: _user!,
                      onProfileImageTap: _pickImage,
                    ),
                    const SizedBox(height: 20),
                    ProfileStatsSection(
                      globalStats: globalStats,
                      sportStats: sportStats,
                      selectedSports: selectedSports,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
