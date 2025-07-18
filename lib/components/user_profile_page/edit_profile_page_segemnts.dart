import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/services/firestore_service.dart';

class EditProfilePageSegments extends StatefulWidget {
  final UserModel user;
  final VoidCallback onProfileImageTap;

  const EditProfilePageSegments({
    super.key,
    required this.user,
    required this.onProfileImageTap,
  });

  @override
  State<EditProfilePageSegments> createState() => _EditProfilePageSegmentsState();
}

class _EditProfilePageSegmentsState extends State<EditProfilePageSegments> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  DateTime? _selectedBirthDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _emailController = TextEditingController(text: widget.user.email);
    _selectedBirthDate = widget.user.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context)!;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final updatedUser = UserModel(
      id: widget.user.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      birthDate: _selectedBirthDate,
      avatarUrl: widget.user.avatarUrl,
    );

    try {
      await updateUserModel(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.profile_saved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.error_generic)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final bgColor = theme.brightness == Brightness.dark
        ? Colors.white.withAlpha(6)
        : Colors.black.withAlpha(4);
    final borderColor = theme.brightness == Brightness.dark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(5);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.edit_button),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: widget.onProfileImageTap,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: (widget.user.avatarUrl?.isNotEmpty ?? false)
                            ? NetworkImage(widget.user.avatarUrl!)
                            : null,
                        child: (widget.user.avatarUrl?.isEmpty ?? true)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(loc.firstname_hint, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: loc.firstname_hint,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(loc.lastname_hint, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: loc.lastname_hint,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(loc.phone_hint, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: loc.phone_hint,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(loc.email_hint, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: loc.email_hint,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(loc.birth_date_label, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedBirthDate != null
                            ? DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(_selectedBirthDate!)
                            : loc.select_date,
                        style: TextStyle(
                          color: _selectedBirthDate != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.save, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
