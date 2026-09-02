import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reward.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';

const _emojiChoices = [
  '🍿', '🍰', '🎮', '🎨', '🎁', '🌳', '🍕', '🎬', '🚲', '🏊', '🎪', '🧩', '📖', '🍦'
];

class AddEditRewardScreen extends StatefulWidget {
  final Reward? existing;

  const AddEditRewardScreen({super.key, this.existing});

  @override
  State<AddEditRewardScreen> createState() => _AddEditRewardScreenState();
}

class _AddEditRewardScreenState extends State<AddEditRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late double _stars;
  late String _emoji;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _stars = (widget.existing?.starsRequired ?? 20).toDouble();
    _emoji = widget.existing?.emoji ?? _emojiChoices.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final family = context.read<FamilyProvider>();
    try {
      if (_isEdit) {
        await family.updateReward(
          widget.existing!.id,
          title: _titleCtrl.text.trim(),
          emoji: _emoji,
          starsRequired: _stars.round(),
        );
      } else {
        await family.addReward(
          title: _titleCtrl.text.trim(),
          emoji: _emoji,
          starsRequired: _stars.round(),
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
      title: 'Supprimer cette récompense ?',
      message: '"${widget.existing!.title}" ne sera plus proposée.',
    );
    if (!confirmed) return;
    setState(() => _saving = true);
    try {
      // ignore: use_build_context_synchronously
      await context.read<FamilyProvider>().deleteReward(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la récompense' : 'Nouvelle récompense'),
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
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.star,
                    shape: BoxShape.circle,
                  ),
                  child: Text(_emoji, style: const TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: _emojiChoices.map((e) {
                  final selected = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.mint : const Color(0xFFF3F1EC),
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: AppColors.mintDark, width: 2)
                            : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Titre de la récompense'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Étoiles nécessaires',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${_stars.round()} ⭐',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.starDark,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _stars,
                min: 5,
                max: 150,
                divisions: 29,
                activeColor: AppColors.starDark,
                onChanged: (v) => setState(() => _stars = v),
              ),
              const SizedBox(height: 20),
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
