import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/avatars.dart';
import '../../models/child.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';

class AddEditChildScreen extends StatefulWidget {
  final Child? existing;

  const AddEditChildScreen({super.key, this.existing});

  @override
  State<AddEditChildScreen> createState() => _AddEditChildScreenState();
}

class _AddEditChildScreenState extends State<AddEditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _avatar;
  late String _theme;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.firstName ?? '');
    _avatar = widget.existing?.avatar ?? kAvatars.first.key;
    _theme = widget.existing?.theme ?? AppColors.childThemes.keys.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final family = context.read<FamilyProvider>();
    try {
      if (_isEdit) {
        await family.updateChild(
          widget.existing!.id,
          firstName: _nameCtrl.text.trim(),
          avatar: _avatar,
          theme: _theme,
        );
      } else {
        await family.addChild(
          firstName: _nameCtrl.text.trim(),
          avatar: _avatar,
          theme: _theme,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer ${widget.existing!.firstName} ?',
      message: 'Toutes ses étoiles et son historique seront supprimés.',
    );
    if (!confirmed) return;
    setState(() => _saving = true);
    try {
      await context.read<FamilyProvider>().deleteChild(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'enfant' : 'Ajouter un enfant'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.softRedDark),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.themeColor(_theme),
                    shape: BoxShape.circle,
                  ),
                  child: Text(avatarEmoji(_avatar), style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Avatar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: kAvatars.map((a) {
                  final selected = a.key == _avatar;
                  return GestureDetector(
                    onTap: () => setState(() => _avatar = a.key),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.themeColor(_theme)
                            : const Color(0xFFF3F1EC),
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: AppColors.mintDark, width: 2.5)
                            : null,
                      ),
                      child: Text(a.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Couleur préférée',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                children: AppColors.childThemes.entries.map((entry) {
                  final selected = entry.key == _theme;
                  return GestureDetector(
                    onTap: () => setState(() => _theme = entry.key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: AppColors.textPrimary, width: 2.5)
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(_isEdit ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
