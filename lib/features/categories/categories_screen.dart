import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_icons.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/category.dart';
import '../../l10n/l10n.dart';
import '../cards/cards_providers.dart';
import '../reports/chart_colors.dart';

/// "Mis categorías": the user's own (editable) and the base ones (read
/// only).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const ValueKey('categories.root'),
      appBar: AppBar(title: Text(context.l10n.sectionCategories)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('categories.add'),
        onPressed: () => context.push(Routes.categoryNew),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newCategory),
      ),
      body: SafeArea(
        child: switch (categories) {
          AsyncData(:final value) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
            child: ResponsiveCenter(
              maxWidth: ContentWidth.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.myCategories, style: text.titleMedium),
                  const SizedBox(height: 8),
                  if (!value.any((c) => !c.isBase))
                    Text(
                      context.l10n.noOwnCategories,
                      key: const ValueKey('categories.empty'),
                      style: text.bodyMedium,
                    )
                  else
                    for (final c in context.l10n.sortedCategories(value))
                      if (!c.isBase)
                        _CategoryTile(
                          category: c,
                          onTap: () => context.push(Routes.categoryEdit(c.id!)),
                        ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.includedCategories,
                    style: text.titleMedium,
                  ),
                  Text(
                    context.l10n.includedCategoriesHint,
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final c in context.l10n.sortedCategories(value))
                    if (c.isBase) _CategoryTile(category: c),
                ],
              ),
            ),
          ),
          AsyncError() => Center(child: Text(context.l10n.categoriesLoadError)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.onTap});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Some base colors (brown, gray) vanish on the dark surface: measure
    // against the tinted circle the icon actually sits on.
    final base = Color(category.color);
    final background = Color.alphaBlend(
      base.withValues(alpha: 0.15),
      Theme.of(context).colorScheme.surface,
    );
    final color = readableOn(base, background);
    return ListTile(
      key: ValueKey('categories.item.${category.id}'),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: background,
        foregroundColor: color,
        child: Icon(categoryIcon(category.icon)),
      ),
      title: Text(context.l10n.categoryLabel(category)),
      trailing: onTap == null
          ? const Icon(Icons.lock_outline, size: 18)
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
