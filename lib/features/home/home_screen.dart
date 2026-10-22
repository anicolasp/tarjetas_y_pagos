import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing_cycle.dart';
import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/greeting.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/app_user.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';
import '../cards/recommendation_text.dart';
import '../cards/widgets/credit_card_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // "Today" changes while the app is in the background (a new day, a cut
    // date passing, morning → evening): recompute greeting and ranking when
    // the user comes back.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(cardRankingProvider);
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider)();
    final ranking = ref.watch(cardRankingProvider);
    final cards = ref.watch(userCardsProvider).value ?? const [];
    if (user == null) return const SizedBox.shrink();

    final ranked = ranking.value ?? const <CardRecommendation>[];
    // A failed load must not look like "no cards" (and invite duplicates).
    final failed = ranking.hasError;
    const gap = SizedBox(height: 20);

    return Scaffold(
      key: const ValueKey('home.root'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(user: user, now: now),
                  gap,
                  _MonthSummary(user: user, now: now, ranked: ranked),
                  gap,
                  if (failed)
                    const _LoadError()
                  else
                    _BestCard(ranked: ranked, today: now),
                  gap,
                  const _QuickAccess(),
                  gap,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mis tarjetas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (ranked.isNotEmpty)
                        TextButton(
                          key: const ValueKey('home.seeAllCards'),
                          onPressed: () => context.push(Routes.cards),
                          child: const Text('Ver todas'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (!failed) _Carousel(cards: inAddedOrder(cards, ranked)),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('home.loadError'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudieron cargar tus tarjetas',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('home.retry'),
              onPressed: () => refreshCards(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.now});

  final AppUser user;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${greetingFor(now)}, ${user.firstName}',
            key: const ValueKey('home.greeting'),
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Mi perfil',
          child: InkWell(
            key: const ValueKey('home.avatar'),
            customBorder: const CircleBorder(),
            onTap: () => context.push(Routes.profile),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(
                initialsOf(user.firstName, user.lastName),
                style: const TextStyle(fontWeight: FontWeight.w700),
                // Keep the initials inside the circle with large text.
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.user,
    required this.now,
    required this.ranked,
  });

  final AppUser user;
  final DateTime now;
  final List<CardRecommendation> ranked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Show the currencies the cards use, or the default one.
    final currencies = {for (final r in ranked) r.card.currency}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    if (currencies.isEmpty) currencies.add(user.defaultCurrency);

    return Card(
      key: const ValueKey('home.summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // Stretch so each row's Wrap gets the full width and pushes the
          // amount to the right.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumen de ${formatMonthName(now)}', style: text.titleMedium),
            const SizedBox(height: 12),
            for (final c in currencies) ...[
              _SummaryRow(label: 'Gastado este mes', cents: 0, currency: c),
              _SummaryRow(label: 'Deuda total', cents: 0, currency: c),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.cents,
    required this.currency,
  });

  final String label;
  final int cents;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        children: [
          Text(label, style: text.bodyMedium),
          Text(
            formatMoney(cents, currency),
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BestCard extends StatelessWidget {
  const _BestCard({required this.ranked, required this.today});

  final List<CardRecommendation> ranked;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      key: const ValueKey('home.bestCard'),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mejor tarjeta hoy',
                    style: text.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (ranked.isEmpty) ...[
              Text(
                'Agrega una tarjeta para saber cuál te conviene usar hoy.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const ValueKey('home.addFirstCard'),
                  onPressed: () => context.push(Routes.cardNew),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar tarjeta'),
                ),
              ),
            ] else ...[
              for (final (i, r) in ranked.take(3).indexed)
                _RankRow(
                  key: ValueKey('home.rank.$i'),
                  position: i + 1,
                  recommendation: r,
                  today: today,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    super.key,
    required this.position,
    required this.recommendation,
    required this.today,
  });

  final int position;
  final CardRecommendation recommendation;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final first = position == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$position. ${r.card.alias} •••• ${r.card.last4}',
            style: (first ? text.titleLarge : text.bodyLarge)?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: first ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            explainRecommendation(r, today),
            style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
          ),
          if (r.lowCredit)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Poco crédito disponible',
                      key: ValueKey('home.lowCredit.${r.card.id}'),
                      style: text.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    void soon() => showErrorSnackBar(context, 'Próximamente');
    final items = [
      (
        key: 'home.quick.cards',
        icon: Icons.credit_card,
        label: 'Mis tarjetas',
        onTap: () => context.push(Routes.cards),
      ),
      (
        key: 'home.quick.expense',
        icon: Icons.add_card,
        label: 'Nuevo gasto',
        onTap: soon,
      ),
      (
        key: 'home.quick.reports',
        icon: Icons.insights,
        label: 'Reportes',
        onTap: soon,
      ),
      (
        key: 'home.quick.debts',
        icon: Icons.account_balance_wallet_outlined,
        label: 'Deudas',
        onTap: soon,
      ),
    ];

    // 2 columns on phones, 4 when there is room. Rows size to their content
    // so labels can wrap with large text.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += columns) {
          final row = items.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (j, item) in row.indexed) ...[
                    if (j > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        key: ValueKey(item.key),
                        icon: item.icon,
                        label: item.label,
                        onTap: item.onTap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              row,
            ],
          ],
        );
      },
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({required this.cards});

  /// Cards in the order they were added.
  final List<CardRecommendation> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return ResponsiveCenter(
        child: Text(
          'Aún no tienes tarjetas.',
          key: const ValueKey('home.carouselEmpty'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    // Height follows the tallest card (IntrinsicHeight), so large text
    // never overflows a fixed carousel height. The first card starts where
    // the centered, width-capped content above starts (same math as
    // ResponsiveCenter), and the cards can scroll to the screen edges.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final padding =
            context.pagePadding +
            (available > ContentWidth.page
                ? (available - ContentWidth.page) / 2
                : 0);
        return SingleChildScrollView(
          key: const ValueKey('home.carousel'),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, r) in cards.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: 280,
                    child: CreditCardTile(
                      key: ValueKey('home.carousel.${r.card.id}'),
                      card: r.card,
                      recommendation: r,
                      onTap: () => context.push(Routes.cardDetail(r.card.id!)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
