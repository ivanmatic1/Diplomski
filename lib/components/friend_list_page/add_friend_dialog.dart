import 'package:flutter/material.dart';
import 'package:terminko/services/friends_list_service.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _handleSend() async {
    final loc = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = loc.error_fill_in_all_fields);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final targetUserId = await getUserIdByEmail(email);

      if (targetUserId == null) {
        setState(() {
          _error = loc.error_user_not_found;
          _isLoading = false;
        });
        return;
      }

      await sendFriendRequest(targetUserId);

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.friend_request_sent)),
      );
    } catch (e) {
      setState(() {
        _error = '${loc.error_title}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.friend_add_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: loc.email_hint,
              errorText: _error,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleSend,
          child: Text(loc.send),
        ),
      ],
    );
  }
}
