import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing_cycle.dart';
import '../../core/clock.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../l10n/l10n.dart';
import 'cards_providers.dart';
import 'widgets/credit_card_tile.dart';

/// "Mis tarjetas": active cards, add and edit.
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider)();
    final ranking = ref
        .watch(financeProvider)
        .whenData((f) => f.inAddedOrder(today));

    return Scaffold(
      key: const ValueKey('cards.root'),
      appBar: AppBar(title: Text(context.l10n.myCards)),
      floatingActionButton: (ranking.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('cards.add'),
              onPressed: () => context.push(Routes.cardNew),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.add),
            ),
      body: SafeArea(
        child: switch (ranking) {
          AsyncError() => _Message(
            icon: Icons.error_outline,
            text: context.l10n.cardsLoadError,
          ),
          AsyncData(value: final list) when list.isEmpty => const _Empty(),
          AsyncData(value: final list) => _List(items: list),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<CardRecommendation> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Room for the FAB under the last card.
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = items[i];
        return ResponsiveCenter(
          maxWidth: ContentWidth.form,
          child: CreditCardTile(
            key: ValueKey('cards.item.${r.card.id}'),
            card: r.card,
            recommendation: r,
            onTap: () => context.push(Routes.cardEdit(r.card.id!)),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CenteredScrollView(
      child: ResponsiveCenter(
        maxWidth: ContentWidth.form,
        child: Column(
          key: const ValueKey('cards.empty'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noCardsYetTitle,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.addFirstCardHint,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('cards.emptyAdd'),
              onPressed: () => context.push(Routes.cardNew),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addCard),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => CenteredScrollView(
    child: ResponsiveCenter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
