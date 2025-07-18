import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/services/firestore_service.dart';

Future<void> showChangePasswordDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool loading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(loc.change_password_title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                decoration: InputDecoration(labelText: loc.current_password),
                obscureText: true,
                validator: (val) => val == null || val.isEmpty ? loc.field_required : null,
              ),
              TextFormField(
                controller: newController,
                decoration: InputDecoration(labelText: loc.new_password),
                obscureText: true,
                validator: (val) => val != null && val.length >= 6 ? null : loc.password_min_length,
              ),
              TextFormField(
                controller: confirmController,
                decoration: InputDecoration(labelText: loc.confirm_new_password),
                obscureText: true,
                validator: (val) => val != newController.text ? loc.passwords_do_not_match : null,
              ),
            ],
          ),
        ),
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (!loading) ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                setState(() => loading = true);
                final result = await changePassword(
                  context: context,
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                );
                setState(() => loading = false);

                if (result == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.password_changed_success)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                }
              },
              child: Text(loc.save),
            ),
          ],
        ],
      ),
    ),
  );
}
