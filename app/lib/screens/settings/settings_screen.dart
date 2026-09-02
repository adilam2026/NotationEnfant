import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/child_mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../root/root_shell.dart';
import 'manage_children_screen.dart';
import 'pin_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editFamilyName(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('👨‍👩‍👧 Nom de la famille'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<AuthProvider>().updateFamilyName(name);
    }
  }

  Future<void> _enterChildMode(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.profile?.parentPin == null || auth.profile!.parentPin!.isEmpty) {
      final go = await showConfirmDialog(
        context,
        title: '🔐 Configurez d\'abord un PIN',
        message:
            'Un code parent est nécessaire pour pouvoir quitter le mode enfant.',
        confirmLabel: 'Configurer',
        destructive: false,
      );
      if (go && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        );
      }
      return;
    }
    if (context.mounted) {
      context.read<ChildModeProvider>().enter();
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Se déconnecter ?',
      message: 'Vous pourrez vous reconnecter à tout moment.',
      confirmLabel: 'Déconnexion',
      destructive: false,
    );
    if (!confirmed) return;
    context.read<FamilyProvider>().reset();
    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '⚙️ Réglages'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _SettingsTile(
                emoji: '👨‍👩‍👧',
                title: 'Famille',
                subtitle: profile?.familyName ?? '',
                onTap: () => _editFamilyName(context, profile?.familyName ?? ''),
              ),
              _SettingsTile(
                emoji: '👧',
                title: 'Enfants',
                subtitle: 'Ajouter, modifier, supprimer',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageChildrenScreen()),
                ),
              ),
              _SettingsTile(
                emoji: '🔐',
                title: 'PIN parent',
                subtitle: (profile?.parentPin == null || profile!.parentPin!.isEmpty)
                    ? 'Non configuré'
                    : 'Configuré',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppColors.mint.withValues(alpha: 0.5),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  leading: const Text('👀', style: TextStyle(fontSize: 24)),
                  title: const Text('Mode enfant',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Vue simplifiée, sans les boutons de note'),
                  onTap: () => _enterChildMode(context),
                ),
              ),
              const SizedBox(height: 24),
              _SettingsTile(
                emoji: '🚪',
                title: 'Déconnexion',
                subtitle: null,
                color: AppColors.softRedDark,
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
