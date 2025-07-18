import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/home_page/header_section.dart';
import 'package:terminko/components/home_page/edit_all_details.dart';
import 'package:terminko/components/home_page/queue_info_section.dart';
import 'package:terminko/components/home_page/social_score_card.dart';
import 'package:terminko/components/home_page/sport_selection_tab_bar.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/models/sport_details_model.dart';
import 'package:terminko/pages/edit_sport_parameters_page.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:terminko/services/main_page_service.dart';
import 'package:terminko/services/queue_service.dart';
import 'package:terminko/components/home_page/match_confirmation_dialog.dart';

class MainHomeContent extends StatefulWidget {
  const MainHomeContent({super.key});

  @override
  State<MainHomeContent> createState() => _MainHomeContentState();
}

class _MainHomeContentState extends State<MainHomeContent> {
  String? _lastInviteHash;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  bool isQueueing = false;

  @override
  void initState() {
    super.initState();
    if (uid != null) {
      _listenForInvites(uid);
      checkIfInQueueForInitialSport();
    }
  }

  Future<void> checkIfInQueue(String sportId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('queueEntries')
        .doc('$uid-$sportId')
        .get();

    if (!mounted) return;

    setState(() {
      isQueueing = doc.exists;
    });
  }

  Future<void> checkIfInQueueForInitialSport() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return;
    final userData = userDoc.data()!;
    final activeSport = userData['activeSport'] as String?;
    if (activeSport != null) {
      await checkIfInQueue(activeSport);
    }
  }

  void _listenForInvites(String? userId) {
    if (userId == null) return;
    FirebaseFirestore.instance
      .collection('parties')
      .where('invites', arrayContains: userId)
      .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final invites = List<String>.from(data['invites'] ?? []);
        final hostId = data['hostId'];
        final hash = invites.join(',');

        if (!invites.contains(userId)) {
          _lastInviteHash = null;
          continue;
        }

        if (_lastInviteHash == hash) continue;
        _lastInviteHash = hash;

        final hostSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(hostId).get();
        final hostData = hostSnapshot.data();
        final hostName = hostData != null
            ? "${hostData['firstName']} ${hostData['lastName']}"
            : AppLocalizations.of(context)!.someone;

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.party_invite),
            content: Text(AppLocalizations.of(context)!.party_invite_message(hostName)),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('parties')
                      .doc(doc.id)
                      .update({
                    'invites': FieldValue.arrayRemove([userId]),
                    'members': FieldValue.arrayUnion([userId]),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.accept),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('parties')
                      .doc(doc.id)
                      .update({
                    'invites': FieldValue.arrayRemove([userId]),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.decline),
              ),
            ],
          ),
        );
      }
    });
  }


  List<String> _localizePositions(BuildContext context, String? sport, List<String> positions) {
    final loc = AppLocalizations.of(context)!;

    return positions.map((pos) {
      switch (sport) {
        case 'football':
          switch (pos) {
            case 'Goalkeeper':
              return loc.goalkeeper;
            case 'Player':
              return loc.player;
          }
          break;
        case 'basketball':
          switch (pos) {
            case 'Playmaker':
              return loc.basketball_position_playmaker;
            case 'Shooter':
              return loc.basketball_position_shooter;
            case 'Power Forward':
              return loc.basketball_position_power_forward;
            case 'Center':
              return loc.basketball_position_center;
          }
          break;
        case 'padel':
          switch (pos) {
            case 'Left':
              return loc.padel_position_left;
            case 'Right':
              return loc.padel_position_right;
            case 'Flex':
              return loc.padel_position_flexible;
          }
          break;
      }
      return pos;
    }).toList();
  }

  Stream<List<UserModel>> _partyMembersStream(String sportId) {
    final partyRef = FirebaseFirestore.instance.collection('parties').doc(sportId);
    return partyRef.snapshots().asyncMap((doc) async {
      final data = doc.data();
      if (data == null) return [];

      final memberIds = List<String>.from(data['members'] ?? []);
      final futures = memberIds.map((id) => getUserById(id)).toList();
      final users = await Future.wait(futures);
      final result = users.whereType<UserModel>().toList();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && memberIds.contains(uid)) {
        final queueDoc = await FirebaseFirestore.instance
            .collection('queueEntries')
            .doc('$uid-$sportId')
            .get();

        if (queueDoc.exists) {
          await removeFromQueue(sportId);
          if (mounted) {
            setState(() {
              isQueueing = false;
            });
          }
        }
      }

      return result;
    });
  }

  Stream<SportDetailsModel?> getSportDataStream(String sportId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sports')
        .doc(sportId)
        .snapshots()
        .map((doc) => doc.exists ? SportDetailsModel.fromMap(doc.data()!) : null);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(uid, userData);
        final activeSport = user.activeSport;

        if (activeSport == null) return const SizedBox();

        return StreamBuilder<SportDetailsModel?>(
          stream: getSportDataStream(activeSport),
          builder: (context, sportSnapshot) {
            final sportModel = sportSnapshot.data;

            final rawTime = sportModel?.preferredTime ?? '';
            String formattedTime = '';
            if (rawTime.isNotEmpty) {
              final parts = rawTime.split(':');
              if (parts.length == 2) {
                final hour = int.tryParse(parts[0]);
                final minute = int.tryParse(parts[1]);
                if (hour != null && minute != null) {
                  final timeOfDay = TimeOfDay(hour: hour, minute: minute);
                  formattedTime = timeOfDay.format(context);
                }
              }
            }

            return Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('queueEntries')
                      .doc('$uid-$activeSport')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;

                    final hasPendingMatch = data != null &&
                        data['status'] == 'pending' &&
                        data['proposedMatchId'] != null;

                    if (hasPendingMatch) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showDialog(
                          context: context,
                          builder: (_) => MatchConfirmationDialog(
                            matchId: data['proposedMatchId'],
                            sportId: activeSport,
                          ),
                        );
                      });
                    }

                    return const SizedBox.shrink();
                  },
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderSection(key: ValueKey(user.avatarUrl ?? '')),
                      const SizedBox(height: 20),
                      Center(
                        child: SportSelectionTabBar(
                          selectedIndex: user.selectedSports.indexOf(activeSport),
                          tabs: user.selectedSports,
                          onTabSelected: (index) async {
                            if (index < user.selectedSports.length) {
                              final oldSport = activeSport;
                              await removeFromQueue(oldSport);

                              final service = MainPageService();
                              await service.updateActiveSport(user.selectedSports[index]);

                              await checkIfInQueue(user.selectedSports[index]);
                            }
                          },
                          onToggleSport: (sport, isSelected) async {
                            final updated = isSelected
                                ? [...user.selectedSports, sport]
                                : user.selectedSports.where((s) => s != sport).toList();

                            final updatedUser = user.copyWith(
                              selectedSports: updated,
                              activeSport: updated.contains(user.activeSport)
                                  ? user.activeSport
                                  : (updated.isNotEmpty ? updated.first : null),
                            );

                            await updateUserModel(updatedUser);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      EditAllDetails(
                        positions: _localizePositions(context, activeSport, sportModel?.positions ?? []),
                        time: formattedTime,
                        distanceKm: sportModel?.location?['maxDistanceKm']?.toInt() ?? 0,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditSportParametersPage(sportId: activeSport),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('parties').doc(activeSport).snapshots(),
                        builder: (context, partySnapshot) {
                          final partyData = partySnapshot.data?.data() as Map<String, dynamic>?;
                          final hostId = partyData?['hostId'] as String?;
                          final members = List<String>.from(partyData?['members'] ?? []);
                          final isInParty = members.contains(user.id);

                          if (!isInParty || hostId == null) {
                            return QueueInfoSection(
                              partyMembers: [],
                              isQueueing: isQueueing,
                              currentSportId: activeSport,
                              partyHostId: user.id,
                              onEnteredQueue: () => setState(() => isQueueing = true),
                              onLeftQueue: () => setState(() => isQueueing = false),
                            );
                          }

                          return StreamBuilder<List<UserModel>>(
                            stream: _partyMembersStream(activeSport),
                            builder: (context, snapshot) {
                              final memberModels = snapshot.data ?? [];

                              return QueueInfoSection(
                                partyMembers: memberModels,
                                isQueueing: isQueueing,
                                currentSportId: activeSport,
                                partyHostId: hostId,
                                onEnteredQueue: () => setState(() => isQueueing = true),
                                onLeftQueue: () => setState(() => isQueueing = false),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SocialScoreCard(user: user),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
