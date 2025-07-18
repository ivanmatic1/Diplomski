import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terminko/services/party_service.dart';
import 'package:terminko/services/friends_list_service.dart';
import 'package:terminko/models/user_model.dart';

class InviteFriendDialog extends StatefulWidget {
  final String sportId;

  const InviteFriendDialog({
    super.key,
    required this.sportId,
  });

  @override
  State<InviteFriendDialog> createState() => _InviteFriendDialogState();
}

class _InviteFriendDialogState extends State<InviteFriendDialog> {
  final Set<String> sentInvites = {};
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allFriends = [];
  List<String> _partyMemberIds = [];
  final Map<String, bool> _animateSent = {};

  late BuildContext _rootContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rootContext = Navigator.of(context, rootNavigator: true).context;
  }

  @override
  void initState() {
    super.initState();
    _loadPartyMembers();
  }

  Future<void> _loadPartyMembers() async {
    final doc = await FirebaseFirestore.instance
        .collection('parties')
        .doc(widget.sportId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        final members = List<String>.from(data['members'] ?? []);
        if (!mounted) return;
        setState(() {
          _partyMemberIds = members;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredFriends {
    final query = _searchController.text.toLowerCase();
    final availableFriends = _allFriends
        .where((user) => !_partyMemberIds.contains(user.id))
        .toList();

    if (query.isEmpty) return availableFriends;

    return availableFriends.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.invite_friends_title),
      content: FutureBuilder<List<UserModel>>(
        future: getFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          _allFriends = data;

          if (_filteredFriends.isEmpty) {
            return Text(loc.no_friends_to_invite);
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: loc.search_friends_hint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final alreadySent = sentInvites.contains(friend.id);
                      final isAnimating = _animateSent[friend.id] ?? false;

                      return ListTile(
                        leading: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                            ? CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(friend.avatarUrl!),
                              )
                            : CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  friend.firstName.isNotEmpty
                                      ? friend.firstName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        title: Text('${friend.firstName} ${friend.lastName}'),
                        trailing: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: isAnimating ? -10 : 0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, value),
                              child: GestureDetector(
                                onTap: alreadySent
                                    ? null
                                    : () async {
                                        if (!mounted) return;
                                        setState(() {
                                          _animateSent[friend.id] = true;
                                        });

                                        await PartyService().inviteMoreUsers(
                                          widget.sportId,
                                          [friend.id],
                                        );

                                        if (!mounted) return;
                                        setState(() {
                                          sentInvites.add(friend.id);
                                        });

                                        await Future.delayed(
                                            const Duration(milliseconds: 400));
                                        if (!mounted) return;
                                        setState(() {
                                          _animateSent[friend.id] = false;
                                        });

                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          ScaffoldMessenger.maybeOf(_rootContext)?.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  loc.invite_sent_to(friend.firstName)),
                                            ),
                                          );
                                        });
                                      },
                                child: Icon(
                                  alreadySent ? Icons.check : Icons.send,
                                  color: alreadySent
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.close),
        ),
      ],
    );
  }
}
