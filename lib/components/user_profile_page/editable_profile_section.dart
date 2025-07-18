import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/components/user_profile_page/editable_profile_field.dart';
import 'package:terminko/components/user_profile_page/editable_date_field.dart';

class EditableProfileSection extends StatelessWidget {
  final UserModel user;
  final String password;

  final bool isEditingEmail;
  final bool isEditingPhone;
  final bool isEditingPassword;
  final bool isEditingBirthDate;

  final void Function(String) onEmailChanged;
  final void Function(String) onPhoneChanged;
  final void Function(String) onPasswordChanged;
  final void Function(DateTime) onBirthDateChanged;


  final VoidCallback onEditEmail;
  final VoidCallback onEditPhone;
  final VoidCallback onEditPassword;
  final VoidCallback onEditBirthDate;

  final VoidCallback onCancelEmail;
  final VoidCallback onCancelPhone;
  final VoidCallback onCancelPassword;
  final VoidCallback onCancelBirthDate;

  final void Function(String) onSaveEmail;
  final void Function(String) onSavePhone;
  final void Function(String) onSavePassword;
  final void Function(DateTime) onSaveBirthDate;

  const EditableProfileSection({
    super.key,
    required this.user,
    required this.password,
    required this.isEditingEmail,
    required this.isEditingPhone,
    required this.isEditingPassword,
    required this.isEditingBirthDate,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onEditEmail,
    required this.onEditPhone,
    required this.onEditPassword,
    required this.onEditBirthDate,
    required this.onCancelEmail,
    required this.onCancelPhone,
    required this.onCancelPassword,
    required this.onCancelBirthDate,
    required this.onSaveEmail,
    required this.onSavePhone,
    required this.onSavePassword,
    required this.onSaveBirthDate,
    required this.onBirthDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        EditableProfileField(
          label: loc.email_hint,
          fieldKey: 'email',
          user: user,
          isEditing: isEditingEmail,
          onChanged: onEmailChanged,
          onEdit: onEditEmail,
          onCancel: onCancelEmail,
          onSave: onSaveEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        EditableProfileField(
          label: loc.phone_hint,
          fieldKey: 'phone',
          user: user,
          isEditing: isEditingPhone,
          onChanged: onPhoneChanged,
          onEdit: onEditPhone,
          onCancel: onCancelPhone,
          onSave: onSavePhone,
          keyboardType: TextInputType.phone,
        ),
        EditableProfileField(
          label: loc.password_hint,
          fieldKey: 'password',
          user: user,
          isEditing: isEditingPassword,
          onChanged: onPasswordChanged,
          onEdit: onEditPassword,
          onCancel: onCancelPassword,
          onSave: onSavePassword,
          keyboardType: TextInputType.visiblePassword,
        ),
        EditableDateField(
          label: loc.birth_date_label,
          value: user.birthDate,
          isEditing: isEditingBirthDate,
          onEdit: onEditBirthDate,
          onCancel: onCancelBirthDate,
          onSave: onSaveBirthDate,
        ),
      ],
    );
  }
}
