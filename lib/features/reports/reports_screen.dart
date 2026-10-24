import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_icons.dart';
import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/report.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/category.dart';
import '../../data/models/credit_card.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expenses_repository.dart';
import '../cards/cards_providers.dart';
import '../expenses/expense_filter_sheet.dart';
import '../expenses/widgets/movement_tile.dart';
import 'report_charts.dart';

/// Reports: one filter bar scopes both tabs (summary and movements).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  var _period = ReportPeriod.thisMonth;
  DateTimeRange? _customRange;
  var _cardIds = <int>{};

  /// Categories, merchant and amounts (from the shared filter sheet).
  var _more = const ExpenseFilter();

  /// Chosen by the user when both currencies have data.
  Currency? _currency;

  ({DateTime from, DateTime to}) get _range {
    final quick = _period.rangeFor(ref.read(clockProvider)());
    if (quick != null) return quick;
    final r = _customRange!;
    return (from: r.start, to: r.end);
  }

  ExpenseFilter get _filter {
    final (:from, :to) = _range;
    return ExpenseFilter(
      cardIds: _cardIds,
      categoryIds: _more.categoryIds,
      from: from,
      to: to,
      merchant: _more.merchant,
      minCents: _more.minCents,
      maxCents: _more.maxCents,
    );
  }

  Future<void> _pickPeriod() async {
    final picked = await showModalBottomSheet<ReportPeriod>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in ReportPeriod.values)
                ListTile(
                  key: ValueKey('reports.period.${p.name}'),
                  title: Text(p.label),
                  trailing: p == _period ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked == ReportPeriod.custom) {
      await _pickRange();
    } else {
      setState(() {
        _period = picked;
        _customRange = null;
      });
    }
  }

  Future<void> _pickRange() async {
    final today = ref.read(clockProvider)();
    final (:from, :to) = _range;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: from.isAfter(today) ? today : from,
        end: to.isAfter(today) ? today : to,
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _period = ReportPeriod.custom;
      _customRange = range;
    });
  }

  Future<void> _pickCards(List<CreditCard> cards) async {
    final picked = await showModalBottomSheet<Set<int>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CardPicker(cards: cards, selected: _cardIds),
    );
    if (picked != null && mounted) setState(() => _cardIds = picked);
  }

  Future<void> _moreFilters(List<Category> categories) async {
    final (:from, :to) = _range;
    final picked = await showExpenseFilterSheet(
      context,
      current: ExpenseFilter(
        categoryIds: _more.categoryIds,
        from: from,
        to: to,
        merchant: _more.merchant,
        minCents: _more.minCents,
        maxCents: _more.maxCents,
      ),
      categories: categories,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _more = ExpenseFilter(
        categoryIds: picked.categoryIds,
        merchant: picked.merchant,
        minCents: picked.minCents,
        maxCents: picked.maxCents,
      );
      // A range changed in the sheet becomes the custom period; a cleared
      // one goes back to the default.
      if (picked.from == null || picked.to == null) {
        _period = ReportPeriod.thisMonth;
        _customRange = null;
      } else if (picked.from != from || picked.to != to) {
        _period = ReportPeriod.custom;
        _customRange = DateTimeRange(start: picked.from!, end: picked.to!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = _filter;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final cards = ref.watch(allCardsProvider).value ?? const [];

    final bar = _FilterBar(
      period: _period,
      range: _range,
      cards: cards,
      cardIds: _cardIds,
      categories: categories,
      more: _more,
      onPeriod: _pickPeriod,
      onCards: () => _pickCards(cards.where((c) => !c.archived).toList()),
      onMore: () => _moreFilters(categories),
      onRemoveCard: (id) =>
          setState(() => _cardIds = {..._cardIds}..remove(id)),
      onRemoveCategory: (id) => setState(
        () => _more = ExpenseFilter(
          categoryIds: {..._more.categoryIds}..remove(id),
          merchant: _more.merchant,
          minCents: _more.minCents,
          maxCents: _more.maxCents,
        ),
      ),
      onRemoveMerchant: () => setState(
        () => _more = ExpenseFilter(
          categoryIds: _more.categoryIds,
          minCents: _more.minCents,
          maxCents: _more.maxCents,
        ),
      ),
      onRemoveAmount: () => setState(
        () => _more = ExpenseFilter(
          categoryIds: _more.categoryIds,
          merchant: _more.merchant,
        ),
      ),
      onRemoveRange: () => setState(() {
        _period = ReportPeriod.thisMonth;
        _customRange = null;
      }),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: const ValueKey('reports.root'),
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: const TabBar(
            tabs: [
              Tab(key: ValueKey('reports.tabSummary'), text: 'Resumen'),
              Tab(key: ValueKey('reports.tabList'), text: 'Movimientos'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _Summary(
                filterBar: bar,
                filter: filter,
                range: _range,
                categories: categories,
                cards: cards,
                currency: _currency,
                onCurrency: (c) => setState(() => _currency = c),
              ),
              _Movements(
                filterBar: bar,
                filter: filter,
                categories: categories,
                cards: cards,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Period, cards and "Más filtros" in one row above both tabs, then the
/// active filters as removable chips.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.period,
    required this.range,
    required this.cards,
    required this.cardIds,
    required this.categories,
    required this.more,
    required this.onPeriod,
    required this.onCards,
    required this.onMore,
    required this.onRemoveCard,
    required this.onRemoveCategory,
    required this.onRemoveMerchant,
    required this.onRemoveAmount,
    required this.onRemoveRange,
  });

  final ReportPeriod period;
  final ({DateTime from, DateTime to}) range;
  final List<CreditCard> cards;
  final Set<int> cardIds;
  final List<Category> categories;
  final ExpenseFilter more;
  final VoidCallback onPeriod;
  final VoidCallback onCards;
  final VoidCallback onMore;
  final ValueChanged<int> onRemoveCard;
  final ValueChanged<int> onRemoveCategory;
  final VoidCallback onRemoveMerchant;
  final VoidCallback onRemoveAmount;
  final VoidCallback onRemoveRange;

  @override
  Widget build(BuildContext context) {
    final byCardId = {for (final c in cards) c.id!: c};
    final byCategoryId = {for (final c in categories) c.id!: c};
    // The dates of a custom range live in its removable chip below.
    final rangeLabel =
        '${formatShortDate(range.from)} – ${formatShortDate(range.to)}';
    final amountLabel = switch ((more.minCents, more.maxCents)) {
      (null, null) => null,
      (final min?, null) => 'Desde ${centsToInput(min)}',
      (null, final max?) => 'Hasta ${centsToInput(max)}',
      (final min?, final max?) => '${centsToInput(min)} – ${centsToInput(max)}',
    };

    return Column(
      key: const ValueKey('reports.filters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const ValueKey('reports.period'),
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text(period.label),
              onPressed: onPeriod,
            ),
            ActionChip(
              key: const ValueKey('reports.cards'),
              avatar: const Icon(Icons.credit_card, size: 18),
              label: Text(
                cardIds.isEmpty
                    ? 'Todas las tarjetas'
                    : 'Tarjetas (${cardIds.length})',
              ),
              onPressed: onCards,
            ),
            ActionChip(
              key: const ValueKey('reports.moreFilters'),
              avatar: const Icon(Icons.tune, size: 18),
              label: const Text('Más filtros'),
              onPressed: onMore,
            ),
          ],
        ),
        if (cardIds.isNotEmpty ||
            !more.isEmpty ||
            period == ReportPeriod.custom) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (period == ReportPeriod.custom)
                InputChip(
                  key: const ValueKey('reports.chip.range'),
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(rangeLabel),
                  onDeleted: onRemoveRange,
                ),
              for (final id in cardIds)
                InputChip(
                  key: ValueKey('reports.chip.card.$id'),
                  label: Text(
                    byCardId[id] == null
                        ? 'Tarjeta'
                        : '${byCardId[id]!.alias} •••• ${byCardId[id]!.last4}',
                  ),
                  onDeleted: () => onRemoveCard(id),
                ),
              for (final id in more.categoryIds)
                InputChip(
                  key: ValueKey('reports.chip.category.$id'),
                  avatar: Icon(
                    categoryIcon(byCategoryId[id]?.icon ?? 'category'),
                    size: 18,
                  ),
                  label: Text(byCategoryId[id]?.name ?? 'Categoría'),
                  onDeleted: () => onRemoveCategory(id),
                ),
              if ((more.merchant ?? '').isNotEmpty)
                InputChip(
                  key: const ValueKey('reports.chip.merchant'),
                  label: Text('“${more.merchant}”'),
                  onDeleted: onRemoveMerchant,
                ),
              if (amountLabel != null)
                InputChip(
                  key: const ValueKey('reports.chip.amount'),
                  label: Text(amountLabel),
                  onDeleted: onRemoveAmount,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CardPicker extends StatefulWidget {
  const _CardPicker({required this.cards, required this.selected});

  final List<CreditCard> cards;
  final Set<int> selected;

  @override
  State<_CardPicker> createState() => _CardPickerState();
}

class _CardPickerState extends State<_CardPicker> {
  late final _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Column(
            key: const ValueKey('reports.cardPicker'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tarjetas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              for (final c in widget.cards)
                CheckboxListTile(
                  key: ValueKey('reports.cardOption.${c.id}'),
                  value: _selected.contains(c.id),
                  title: Text('${c.alias} •••• ${c.last4}'),
                  subtitle: Text(c.bank),
                  onChanged: (on) => setState(
                    () => on! ? _selected.add(c.id!) : _selected.remove(c.id),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      key: const ValueKey('reports.cardsAll'),
                      onPressed: () => Navigator.pop(context, <int>{}),
                      child: const Text('Todas'),
                    ),
                    FilledButton(
                      key: const ValueKey('reports.cardsApply'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 44),
                      ),
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A scrollable tab: the filter bar first, then [children].
class _TabPage extends StatelessWidget {
  const _TabPage({required this.filterBar, required this.children});

  final Widget filterBar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ResponsiveCenter(
        maxWidth: ContentWidth.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [filterBar, const SizedBox(height: 16), ...children],
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({
    required this.filterBar,
    required this.filter,
    required this.range,
    required this.categories,
    required this.cards,
    required this.currency,
    required this.onCurrency,
  });

  final Widget filterBar;
  final ExpenseFilter filter;
  final ({DateTime from, DateTime to}) range;
  final List<Category> categories;
  final List<CreditCard> cards;
  final Currency? currency;
  final ValueChanged<Currency> onCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(filter));
    const gap = SizedBox(height: 16);
    return _TabPage(
      filterBar: filterBar,
      children: switch (report) {
        AsyncData(:final value) when value.isEmpty => [const _Empty()],
        AsyncData(:final value) => _content(context, value, gap),
        AsyncError() => [
          const _Message(
            key: ValueKey('reports.loadError'),
            icon: Icons.error_outline,
            text: 'No se pudo cargar el reporte',
          ),
        ],
        _ => [
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      },
    );
  }

  List<Widget> _content(BuildContext context, ExpenseReport r, Widget gap) {
    final currencies = r.currencies;
    final shown = currencies.contains(currency) ? currency! : currencies.first;
    final months = r.monthsIn(shown, from: range.from, to: range.to);
    return [
      for (final c in currencies) ...[
        CurrencyTotalsTile(
          key: ValueKey('reports.totals.${c.code}'),
          totals: r.totals[c]!,
        ),
        gap,
      ],
      if (currencies.length > 1) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SegmentedButton<Currency>(
            key: const ValueKey('reports.currency'),
            segments: [
              for (final c in currencies)
                ButtonSegment(
                  value: c,
                  label: Text(
                    '${c.symbol} ${c.code}',
                    key: ValueKey('reports.currency.${c.code}'),
                  ),
                ),
            ],
            selected: {shown},
            onSelectionChanged: (s) => onCurrency(s.single),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Los gráficos muestran un solo tipo de moneda; no se suman.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        gap,
      ],
      ReportSection(
        key: const ValueKey('reports.byCategory'),
        title: 'Por categoría (${shown.symbol})',
        child: CategoryDonut(
          report: r,
          currency: shown,
          categories: {for (final c in categories) c.id!: c},
        ),
      ),
      // One month is one bar: nothing to compare (its total is above).
      if (months.length > 1) ...[
        gap,
        ReportSection(
          key: const ValueKey('reports.byMonth'),
          title: 'Por mes (${shown.symbol})',
          child: MonthBars(months: months, currency: shown),
        ),
      ],
      gap,
      ReportSection(
        key: const ValueKey('reports.byCard'),
        title: 'Por tarjeta (${shown.symbol})',
        child: CardTotals(
          totals: r.cardsIn(shown),
          currency: shown,
          cards: {for (final c in cards) c.id!: c},
        ),
      ),
    ];
  }
}

class _Movements extends ConsumerWidget {
  const _Movements({
    required this.filterBar,
    required this.filter,
    required this.categories,
    required this.cards,
  });

  final Widget filterBar;
  final ExpenseFilter filter;
  final List<Category> categories;
  final List<CreditCard> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider(filter));
    final byCategory = {for (final c in categories) c.id!: c};
    final byCard = {for (final c in cards) c.id!: c};
    return _TabPage(
      filterBar: filterBar,
      children: switch (expenses) {
        AsyncData(:final value) when value.isEmpty => [const _Empty()],
        AsyncData(:final value) => [
          for (final e in value)
            _ExpenseRow(
              expense: e,
              category: byCategory[e.categoryId],
              card: byCard[e.cardId],
            ),
        ],
        AsyncError() => [
          const _Message(
            key: ValueKey('reports.loadError'),
            icon: Icons.error_outline,
            text: 'No se pudieron cargar los gastos',
          ),
        ],
        _ => [
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      },
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.card,
  });

  final Expense expense;
  final Category? category;
  final CreditCard? card;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    return MovementTile(
      key: ValueKey('reports.expense.${e.id}'),
      icon: categoryIcon(category?.icon ?? 'category'),
      color: Color(category?.color ?? 0xFF757575),
      title: e.merchant,
      subtitle: [
        formatShortDate(e.date),
        category?.name ?? 'Sin categoría',
        if (card != null) '${card!.alias} •••• ${card!.last4}',
      ].join(' · '),
      amount: formatMoney(e.amountCents, e.currency),
      onTap: () => context.push(Routes.expenseEdit(e.id!)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const _Message(
    key: ValueKey('reports.empty'),
    icon: Icons.search_off,
    text: 'No hay gastos con estos filtros',
  );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 56),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
