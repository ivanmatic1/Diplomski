import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/home_page/invite_friend_dialog.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/services/party_service.dart';
import 'package:terminko/services/queue_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QueueInfoSection extends StatefulWidget {
  final List<UserModel> partyMembers;
  final bool isQueueing;
  final String currentSportId;
  final String partyHostId;
  final VoidCallback onEnteredQueue;
  final VoidCallback onLeftQueue;

  const QueueInfoSection({
    super.key,
    required this.partyMembers,
    required this.isQueueing,
    required this.currentSportId,
    required this.partyHostId,
    required this.onEnteredQueue,
    required this.onLeftQueue,
  });

  @override
  State<QueueInfoSection> createState() => _QueueInfoSectionState();
}

class _QueueInfoSectionState extends State<QueueInfoSection> {
  DateTime? queueStartTime;
  Timer? queueTimer;
  Duration elapsed = Duration.zero;
  late String currentUserId;
  int totalInQueue = 0;
  StreamSubscription? _queueSub;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
      if (widget.isQueueing) {
        _startTimer();
      }
      _listenToQueue();
    }
  }

  void _listenToQueue() {
    _queueSub = FirebaseFirestore.instance
        .collection('queueEntries')
        .where('sportId', isEqualTo: widget.currentSportId)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        totalInQueue = snapshot.docs.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant QueueInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isQueueing != widget.isQueueing) {
      if (widget.isQueueing) {
        _startTimer();
      } else {
        _stopTimer();
        setState(() {
          elapsed = Duration.zero;
        });
      }
    }
    if (oldWidget.currentSportId != widget.currentSportId) {
      _queueSub?.cancel();
      _listenToQueue();
    }
  }

  void _startTimer() {
    queueStartTime = DateTime.now();
    queueTimer?.cancel();
    queueTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsed = DateTime.now().difference(queueStartTime!);
      });
    });
  }

  void _stopTimer() {
    queueTimer?.cancel();
    queueTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _queueSub?.cancel();
    super.dispose();
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isInParty = widget.partyMembers.any((user) => user.id == currentUserId);
    final isHost = widget.partyHostId == currentUserId;

    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ...widget.partyMembers.map((user) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: '${user.firstName} ${user.lastName}',
                      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(user.avatarUrl!),
                            )
                          : CircleAvatar(
                              radius: 22,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  )),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => InviteFriendDialog(sportId: widget.currentSportId),
                  );
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary.withAlpha(70),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              if (isInParty) const SizedBox(width: 8),
              if (isInParty)
                GestureDetector(
                  onTap: () async {
                    if (isHost) {
                      await PartyService().disbandParty(widget.currentSportId);
                    } else {
                      await PartyService().leaveParty(widget.currentSportId);
                    }
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.red.withAlpha(100),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${loc.total_players_in_queue}: $totalInQueue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.isQueueing
                ? () async {
                    await FirebaseFirestore.instance
                        .collection('queueEntries')
                        .doc('$currentUserId-${widget.currentSportId}')
                        .delete();
                    _stopTimer();
                    setState(() {
                      elapsed = Duration.zero;
                    });
                    widget.onLeftQueue();
                  }
                : () async {
                    try {
                      await QueueService().addToQueue(widget.currentSportId);
                      _startTimer();
                      widget.onEnteredQueue();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Greška: $e')),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isQueueing ? Colors.green : colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isQueueing
                      ? '${loc.queueing_button} (${formatDuration(elapsed)})'
                      : loc.play_button,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isQueueing) const SizedBox(width: 8),
                if (widget.isQueueing)
                  const Icon(Icons.close, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
