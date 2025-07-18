// match_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/services/matchmaking_service.dart';

class MatchConfirmationDialog extends StatelessWidget {
  final String matchId;
  final String sportId;

  const MatchConfirmationDialog({
    super.key,
    required this.matchId,
    required this.sportId,
  });

  Future<void> _updateStatus(BuildContext context, String status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docId = '$uid-$sportId';

    await FirebaseFirestore.instance
        .collection('queueEntries')
        .doc(docId)
        .update({'status': status});

    await MatchmakingService().confirmMatchIfAllReady(matchId, sportId);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(loc.match_confirmation_title),
      content: Text(loc.match_confirmation_message),
      actions: [
        TextButton(
          onPressed: () => _updateStatus(context, 'declined'),
          child: Text(loc.no_thanks),
        ),
        ElevatedButton(
          onPressed: () => _updateStatus(context, 'confirmed'),
          child: Text(loc.confirm),
        ),
      ],
    );
  }
}
