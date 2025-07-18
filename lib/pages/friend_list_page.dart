import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:terminko/components/friend_list_page/friend_card.dart';
import 'package:terminko/components/friend_list_page/request_card.dart';
import 'package:terminko/components/friend_list_page/blocked_user_card.dart';
import 'package:terminko/services/friends_list_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/friend_list_page/add_friend_dialog.dart';
import 'package:terminko/models/friend_model.dart';
import 'package:terminko/models/user_model.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  bool showFriends = true;
  bool showRequests = false;
  bool showBlocked = false;

  Stream<List<FriendModel>>? _requestStream;
  List<String> _previousRequestIds = [];
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _requestStream = getIncomingFriendRequestsStream();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    final bgColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12);
    final borderColor = isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(20);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          loc.friend_title,
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddFriendDialog(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<List<FriendModel>>(
            stream: getFriendsStream(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return _buildSection(
                title: loc.friends_list,
                isExpanded: showFriends,
                onTap: () => setState(() => showFriends = !showFriends),
                content: Column(
                  children: data.map((friend) => FriendCard(
                    friend: friend,
                    onInvite: () async {
                      await sendLobbyInvite(friend.user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.lobby_invite_sent)),
                      );
                    },
                    onRemoved: () async {
                      await removeFriend(friend.user.id);
                    },
                  )).toList(),
                ),
                bgColor: bgColor,
                borderColor: borderColor,
                textTheme: textTheme,
                colorScheme: colorScheme,
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<FriendModel>>(
            stream: _requestStream,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              final newIds = data.map((e) => e.user.id).toList();
              final newlyAdded = newIds.toSet().difference(_previousRequestIds.toSet());

              if (newlyAdded.isNotEmpty && !_isDialogShowing) {
                _isDialogShowing = true;
                Future.microtask(() async {
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.person_add, color: Colors.green),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              loc.new_friend_request,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: newlyAdded.map((id) {
                          final user = data.firstWhere(
                            (u) => u.user.id == id,
                            orElse: () => FriendModel(
                              id: id,
                              user: UserModel(id: id, email: '', firstName: '', lastName: ''),
                            ),
                          );
                          return Text("- ${user.user.firstName} ${user.user.lastName}");
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            for (final id in newlyAdded) {
                              declineFriendRequest(id);
                            }
                            Navigator.of(context).pop();
                          },
                          child: Text(loc.decline),
                        ),
                        TextButton(
                          onPressed: () {
                            for (final id in newlyAdded) {
                              acceptFriendRequest(id);
                            }
                            Navigator.of(context).pop();
                          },
                          child: Text(loc.accept),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(loc.dismiss),
                        ),
                      ],
                    ),
                  );
                  _isDialogShowing = false;
                  _previousRequestIds = newIds;
                });
              }

              if (_previousRequestIds.isEmpty) {
                _previousRequestIds = newIds;
              }

              return _buildSection(
                title: loc.friend_request,
                isExpanded: showRequests,
                onTap: () => setState(() => showRequests = !showRequests),
                content: Column(
                  children: data.map((req) => RequestCard(
                    request: req,
                    onAccept: () async => await acceptFriendRequest(req.user.id),
                    onDecline: () async => await declineFriendRequest(req.user.id),
                  )).toList(),
                ),
                bgColor: bgColor,
                borderColor: borderColor,
                textTheme: textTheme,
                colorScheme: colorScheme,
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<FriendModel>>(
            stream: getBlockedUsersStream(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return _buildSection(
                title: loc.blocked_users,
                isExpanded: showBlocked,
                onTap: () => setState(() => showBlocked = !showBlocked),
                content: Column(
                  children: data.map((blocked) => BlockedUserCard(
                    user: blocked,
                    onUnblocked: () async {
                      await unblockUser(blocked.user.id);
                    },
                  )).toList(),
                ),
                bgColor: bgColor,
                borderColor: borderColor,
                textTheme: textTheme,
                colorScheme: colorScheme,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
    required Color bgColor,
    required Color borderColor,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(title, style: textTheme.titleMedium),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurface,
                ),
                onTap: onTap,
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: content,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
