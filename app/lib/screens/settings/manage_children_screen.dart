import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/avatars.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../child/add_edit_child_screen.dart';

class ManageChildrenScreen extends StatelessWidget {
  const ManageChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('👧 Enfants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.mintDark),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditChildScreen()),
            ),
          ),
        ],
      ),
      body: family.children.isEmpty
          ? EmptyState(
              emoji: '👋',
              title: 'Aucun enfant pour le moment',
              actionLabel: '➕ Ajouter un enfant',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditChildScreen()),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: family.children.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final child = family.children[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.themeColor(child.theme),
                      child: Text(avatarEmoji(child.avatar)),
                    ),
                    title: Text(child.firstName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${child.availableStars} ⭐'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditChildScreen(existing: child),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
