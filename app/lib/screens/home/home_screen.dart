import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/child_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../child/add_edit_child_screen.dart';
import '../child/child_detail_screen.dart';
import '../root/root_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '⭐ Mes étoiles',
          trailing: family.children.isEmpty
              ? null
              : IconButton(
                  onPressed: () => _openAddChild(context),
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppColors.mintDark, size: 32),
                ),
        ),
        if (family.isOffline) const OfflineBanner(),
        if (!family.isOffline && family.errorMessage != null)
          ErrorBanner(
            message: family.errorMessage!,
            onRetry: () => family.refresh(),
          ),
        Expanded(
          child: family.isLoading && family.children.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.mintDark))
              : family.children.isEmpty
                  ? _EmptyChildren(onAdd: () => _openAddChild(context))
                  : RefreshIndicator(
                      color: AppColors.mintDark,
                      onRefresh: family.refresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: family.children.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final child = family.children[i];
                          return ChildCard(
                            child: child,
                            rewards: family.rewards,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChildDetailScreen(childId: child.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _openAddChild(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditChildScreen()),
    );
  }
}

class _EmptyChildren extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyChildren({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '👋',
      title: 'Qui collectionne les étoiles ?',
      actionLabel: '➕ Ajouter un enfant',
      onAction: onAdd,
    );
  }
}
