import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing_cycle.dart';
import '../../core/category_icons.dart';
import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../core/statement.dart';
import '../../data/finance_snapshot.dart';
import '../../data/models/card_payment.dart';
import '../../data/models/category.dart';
import '../../data/models/credit_card.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expenses_repository.dart';
import '../auth/auth_widgets.dart';
import '../expenses/expense_filter_sheet.dart';
import 'cards_providers.dart';
import 'recommendation_text.dart';
import 'widgets/credit_card_tile.dart';
import '../expenses/widgets/movement_tile.dart';

/// A card: balance per currency, limit usage, what to pay this cut, and its
/// movements (expenses and payments) by date, with filters.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final int cardId;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  late var _filter = ExpenseFilter(cardId: widget.cardId);

  Future<void> _openFilter(List<Category> categories) async {
    final result = await showExpenseFilterSheet(
      context,
      current: _filter,
      categories: categories,
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final today = ref.watch(clockProvider)();
    final card = finance.value?.card(widget.cardId);

    return Scaffold(
      key: const ValueKey('cardDetail.root'),
      appBar: AppBar(
        title: Text(card?.alias ?? 'Tarjeta'),
        actions: [
          if (card != null) ...[
            IconButton(
              key: const ValueKey('cardDetail.filter'),
              tooltip: 'Filtrar gastos',
              onPressed: () => _openFilter(categories),
              icon: Badge(
                isLabelVisible: !_filter.isEmpty,
                child: const Icon(Icons.filter_list),
              ),
            ),
            IconButton(
              key: const ValueKey('cardDetail.edit'),
              tooltip: 'Editar tarjeta',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.cardEdit(widget.cardId)),
            ),
          ],
        ],
      ),
      floatingActionButton: card == null
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('cardDetail.addExpense'),
              onPressed: () =>
                  context.push(Routes.expenseNew(cardId: widget.cardId)),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo gasto'),
            ),
      body: SafeArea(
        child: switch (finance) {
          AsyncData(:final value) when card != null => _Body(
            card: card,
            snapshot: value,
            categories: {for (final c in categories) c.id!: c},
            today: today,
            filter: _filter,
            onClearFilter: () => setState(() => _filter = _filter.cleared()),
          ),
          AsyncData() ||
          AsyncError() => const Center(child: Text('Tarjeta no encontrada')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.card,
    required this.snapshot,
    required this.categories,
    required this.today,
    required this.filter,
    required this.onClearFilter,
  });

  final CreditCard card;
  final FinanceSnapshot snapshot;
  final Map<int, Category> categories;
  final DateTime today;
  final ExpenseFilter filter;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statement = snapshot.statementOf(card, today);
    final recommendation = recommendationFor(
      card,
      today,
      balances: statement.balances,
    );
    final text = Theme.of(context).textTheme;

    // Without filters: every expense and payment. With filters: the SQL
    // query (expenses only).
    final List<Object> movements;
    AsyncValue<List<Expense>>? filtered;
    if (filter.isEmpty) {
      movements = [
        ...snapshot.expensesOf(card.id!),
        ...snapshot.paymentsOf(card.id!),
      ];
    } else {
      final query = ref.watch(filteredExpensesProvider(filter));
      filtered = query;
      movements = [...?query.value];
    }
    final groups = _groupByDay(movements);

    return ListView(
      // Room for the FAB below the last movement.
      padding: const EdgeInsets.only(top: 16, bottom: 96),
      children: [
        ResponsiveCenter(
          maxWidth: ContentWidth.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreditCardTile(card: card, recommendation: recommendation),
              const SizedBox(height: 16),
              _StatementCard(
                card: card,
                statement: statement,
                recommendation: recommendation,
                today: today,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text('Movimientos', style: text.titleMedium)),
                  if (!filter.isEmpty)
                    TextButton.icon(
                      key: const ValueKey('cardDetail.clearFilter'),
                      onPressed: onClearFilter,
                      icon: const Icon(Icons.filter_list_off, size: 18),
                      label: const Text('Quitar filtros'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // A filtered query still running or failed is not "no results".
              if (filtered != null && filtered.hasError)
                Column(
                  key: const ValueKey('cardDetail.filterError'),
                  children: [
                    const Text('No se pudieron filtrar los gastos'),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(filteredExpensesProvider(filter)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                )
              else if (filtered != null && !filtered.hasValue)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      key: ValueKey('cardDetail.filterLoading'),
                    ),
                  ),
                )
              else if (groups.isEmpty)
                _EmptyMovements(filtered: !filter.isEmpty)
              else
                for (final (day, items) in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      _dayLabel(day, today),
                      style: text.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final m in items)
                    switch (m) {
                      Expense e => _ExpenseTile(
                        expense: e,
                        category: categories[e.categoryId],
                      ),
                      CardPayment p => _PaymentTile(payment: p),
                      _ => const SizedBox.shrink(),
                    },
                ],
            ],
          ),
        ),
      ],
    );
  }

  /// Newest day first; inside a day, newest first (by id).
  static List<(DateTime, List<Object>)> _groupByDay(List<Object> movements) {
    DateTime day(Object m) =>
        dateOnly(m is Expense ? m.date : (m as CardPayment).date);
    int id(Object m) => (m is Expense ? m.id : (m as CardPayment).id) ?? 0;

    final sorted = [...movements]
      ..sort((a, b) {
        final byDay = day(b).compareTo(day(a));
        return byDay != 0 ? byDay : id(b).compareTo(id(a));
      });
    final groups = <(DateTime, List<Object>)>[];
    for (final m in sorted) {
      if (groups.isEmpty || groups.last.$1 != day(m)) {
        groups.add((day(m), [m]));
      } else {
        groups.last.$2.add(m);
      }
    }
    return groups;
  }

  static String _dayLabel(DateTime day, DateTime today) {
    final diff = dateOnly(today).difference(day).inDays;
    return switch (diff) {
      0 => 'Hoy',
      1 => 'Ayer',
      _ => formatDate(day),
    };
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.card,
    required this.statement,
    required this.recommendation,
    required this.today,
  });

  final CreditCard card;
  final CardStatement statement;
  final CardRecommendation recommendation;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currencies = statement.byCurrency.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Card(
      key: const ValueKey('cardDetail.statement'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in currencies) ...[
              _CurrencyBlock(
                card: card,
                s: statement.byCurrency[c]!,
                dueDate: statement.dueDate,
                today: today,
              ),
              const SizedBox(height: 12),
            ],
            _Row('Próximo corte', formatDate(recommendation.nextCut)),
            _Row(
              'Fecha límite de ese corte',
              formatDate(recommendation.dueDate),
            ),
            _Row(
              'Si la usas hoy, pagas en',
              '${recommendation.financingDays} días',
            ),
            const SizedBox(height: 4),
            Text(
              explainRecommendation(recommendation, today),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('cardDetail.pay'),
              onPressed: () => context.push(Routes.cardPay(card.id!)),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar pago'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyBlock extends StatelessWidget {
  const _CurrencyBlock({
    required this.card,
    required this.s,
    required this.dueDate,
    required this.today,
  });

  final CreditCard card;
  final CurrencyStatement s;
  final DateTime dueDate;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = s.currency;
    final limit = card.limitFor(c);
    final inFavor = s.balanceCents < 0;

    return Column(
      key: ValueKey('cardDetail.balance.${c.code}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          inFavor ? 'Saldo a favor (${c.code})' : 'Balance (${c.code})',
          formatMoney(s.balanceCents.abs(), c),
          emphasize: true,
          valueKey: 'cardDetail.balanceValue.${c.code}',
        ),
        if (limit > 0) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('cardDetail.usage.${c.code}'),
              minHeight: 8,
              value: (s.balanceCents / limit).clamp(0.0, 1.0),
              color: s.balanceCents > limit * (1 - lowCreditRatio)
                  ? scheme.error
                  : scheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Disponible ${formatMoney(limit - s.balanceCents, c)} '
            'de ${formatMoney(limit, c)}',
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: 6),
        _Row(
          'A pagar este corte',
          formatMoney(s.dueCents, c),
          valueKey: 'cardDetail.due.${c.code}',
        ),
        if (s.dueCents > 0 && dueDate.isAfter(dateOnly(today)))
          Text(
            'Paga antes del ${formatDate(dueDate)}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        if (s.overdue)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Vencido: ${formatMoney(s.overdueCents, c)} desde el '
              '${formatDate(s.overdueSince!)}',
              key: ValueKey('cardDetail.overdue.${c.code}'),
              style: text.bodySmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.category});

  final Expense expense;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final color = Color(category?.color ?? 0xFF757575);
    return MovementTile(
      key: ValueKey('cardDetail.expense.${e.id}'),
      icon: categoryIcon(category?.icon ?? 'category'),
      color: color,
      title: e.merchant,
      subtitle: [
        category?.name ?? 'Sin categoría',
        if (e.wasConverted)
          '${formatMoney(e.originalAmountCents!, e.originalCurrency!)} '
              'a ${formatRate(e.exchangeRateMicros!)}',
      ].join(' · '),
      amount: formatMoney(e.amountCents, e.currency),
      onTap: () => context.push(Routes.expenseEdit(e.id!)),
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  const _PaymentTile({required this.payment});

  final CardPayment payment;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este pago?'),
        content: Text(
          'El balance volverá a subir '
          '${formatMoney(payment.amountCents, payment.currency)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('cardDetail.deletePaymentConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final repo = (await ref.read(reposProvider.future)).expenses;
      await repo.deletePayment(user.id!, payment.id!);
      refreshFinance(ref);
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, unexpectedError(context));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fixed green that reads well in both themes.
    const paid = Color(0xFF2E7D32);
    return MovementTile(
      key: ValueKey('cardDetail.payment.${payment.id}'),
      icon: Icons.check_circle_outline,
      color: paid,
      title: 'Pago',
      subtitle: payment.note,
      amount: '−${formatMoney(payment.amountCents, payment.currency)}',
      amountColor: paid,
      onTap: () => _delete(context, ref),
    );
  }
}

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('cardDetail.empty'),
      children: [
        const SizedBox(height: 12),
        Icon(
          filtered ? Icons.search_off : Icons.receipt_long_outlined,
          size: 56,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          filtered
              ? 'Ningún gasto coincide con los filtros'
              : 'Aún no hay movimientos en esta tarjeta',
          textAlign: TextAlign.center,
          style: text.bodyLarge,
        ),
        if (!filtered) ...[
          const SizedBox(height: 4),
          Text(
            'Toca "Nuevo gasto" para registrar el primero.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false, this.valueKey});

  final String label;
  final String value;
  final bool emphasize;
  final String? valueKey;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Wrap so label and value stack instead of overflowing with big text.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 2,
        children: [
          Text(label, style: text.bodyMedium),
          Text(
            value,
            key: valueKey == null ? null : ValueKey<String>(valueKey!),
            style: (emphasize ? text.titleMedium : text.bodyMedium)?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
