import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/statement.dart';
import '../../core/clock.dart';
import '../../core/debts.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/finance_snapshot.dart';
import '../cards/cards_providers.dart';

/// "Deudas": what the cards owe (read only) and the other debts, in
/// Activas / Saldadas tabs.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    final today = ref.watch(clockProvider)();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: const ValueKey('debts.root'),
        appBar: AppBar(
          title: const Text('Deudas'),
          bottom: const TabBar(
            tabs: [
              Tab(key: ValueKey('debts.tabActive'), text: 'Activas'),
              Tab(key: ValueKey('debts.tabSettled'), text: 'Saldadas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('debts.add'),
          onPressed: () => context.push(Routes.debtNew),
          icon: const Icon(Icons.add),
          label: const Text('Nueva deuda'),
        ),
        body: SafeArea(
          child: switch (finance) {
            AsyncData(:final value) => TabBarView(
              children: [
                _ActiveTab(snapshot: value, today: today),
                _SettledTab(snapshot: value, today: today),
              ],
            ),
            AsyncError() => const Center(
              key: ValueKey('debts.loadError'),
              child: Text('No se pudieron cargar las deudas'),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

/// A scrollable tab with room at the bottom for the FAB.
class _TabPage extends StatelessWidget {
  const _TabPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
      child: ResponsiveCenter(
        maxWidth: ContentWidth.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.snapshot, required this.today});

  final FinanceSnapshot snapshot;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cards = [
      for (final c in snapshot.cards)
        if (snapshot
            .statementOf(c, today)
            .byCurrency
            .values
            .any((s) => s.balanceCents > 0))
          c,
    ];
    final active = [
      for (final s in snapshot.debtSummaries)
        if (!s.settled) s,
    ];

    return _TabPage(
      children: [
        Text('Tarjetas', style: text.titleMedium),
        const SizedBox(height: 8),
        if (cards.isEmpty)
          const _Empty(
            key: ValueKey('debts.cardsEmpty'),
            text: 'Tus tarjetas no tienen balance pendiente.',
          )
        else
          for (final c in cards)
            _CardDebtTile(snapshot: snapshot, cardId: c.id!, today: today),
        const SizedBox(height: 24),
        Text('Otras deudas', style: text.titleMedium),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const _Empty(
            key: ValueKey('debts.empty'),
            text: 'No tienes otras deudas activas.',
          )
        else
          for (final s in active) _DebtTile(summary: s, today: today),
      ],
    );
  }
}

class _SettledTab extends StatelessWidget {
  const _SettledTab({required this.snapshot, required this.today});

  final FinanceSnapshot snapshot;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final settled = [
      for (final s in snapshot.debtSummaries)
        if (s.settled) s,
    ];
    return _TabPage(
      children: [
        if (settled.isEmpty)
          const _Empty(
            key: ValueKey('debts.settledEmpty'),
            text: 'Aún no has saldado ninguna deuda.',
          )
        else
          for (final s in settled) _DebtTile(summary: s, today: today),
      ],
    );
  }
}

/// Balance per currency and due date of a card. Read only: tapping opens
/// the card's movements.
class _CardDebtTile extends StatelessWidget {
  const _CardDebtTile({
    required this.snapshot,
    required this.cardId,
    required this.today,
  });

  final FinanceSnapshot snapshot;
  final int cardId;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final card = snapshot.card(cardId)!;
    final statement = snapshot.statementOf(card, today);
    final (date: due, overdue: late) = payBy(card, statement, today);
    return Card(
      key: ValueKey('debts.card.$cardId'),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(Routes.cardDetail(cardId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                children: [
                  Text(card.label, style: text.titleSmall),
                  Row(
                    key: ValueKey('debts.card.$cardId.payBy'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (late) ...[
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          late
                              ? 'Vencido desde el ${formatDayMonth(due)}'
                              : 'Fecha límite ${formatDayMonth(due)}',
                          style: late
                              ? text.bodySmall?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w600,
                                )
                              : text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final s in statement.byCurrency.values)
                if (s.balanceCents > 0)
                  Text(
                    formatMoney(s.balanceCents, s.currency),
                    key: ValueKey('debts.card.$cardId.${s.currency.code}'),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Creditor, paid of total, what is left, progress and due date (red with
/// an icon and the word "Vencida" when late).
class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.summary, required this.today});

  final DebtSummary summary;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final d = summary.debt;
    return Card(
      key: ValueKey('debts.debt.${d.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(Routes.debtDetail(d.id!)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DebtSummaryView(summary: summary, today: today),
        ),
      ),
    );
  }
}

/// The figures of a debt; shared by the list and the detail.
class DebtSummaryView extends StatelessWidget {
  const DebtSummaryView({
    super.key,
    required this.summary,
    required this.today,
    this.large = false,
  });

  final DebtSummary summary;
  final DateTime today;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = summary.debt;
    final late = summary.overdue(today);
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    // Floor, so "100 %" only shows when it really is paid off; the same
    // value is read out by screen readers.
    final percent = (summary.progress * 100).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(d.creditor, style: large ? text.titleLarge : text.titleMedium),
        if (d.description != null) Text(d.description!, style: muted),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              summary.settled
                  ? 'Saldada'
                  : 'Falta ${formatMoney(summary.remainingCents, d.currency)}',
              key: ValueKey('debt.${d.id}.remaining'),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Pagado ${formatMoney(summary.paidCents, d.currency)} de '
              '${formatMoney(d.amountCents, d.currency)}',
              style: muted,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '$percent % pagado',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('debt.${d.id}.progress'),
              value: summary.progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          children: [
            Text('$percent % pagado', style: muted),
            if (d.dueDate != null && !summary.settled)
              Row(
                key: ValueKey('debt.${d.id}.due'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (late) ...[
                    Icon(Icons.warning_amber, size: 16, color: scheme.error),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      late
                          ? 'Vencida el ${formatShortDate(d.dueDate!)}'
                          : 'Vence el ${formatShortDate(d.dueDate!)}',
                      style: late
                          ? text.bodySmall?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                            )
                          : muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
