import 'package:flutter/material.dart';

import '../../core/category_icons.dart';
import '../../core/formatters.dart';
import '../../data/models/category.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../l10n/l10n.dart';

/// Bottom sheet to filter expenses. Returns the new filter, or null if
/// dismissed. "Limpiar" returns a filter with only the card.
Future<ExpenseFilter?> showExpenseFilterSheet(
  BuildContext context, {
  required ExpenseFilter current,
  required List<Category> categories,
}) {
  return showModalBottomSheet<ExpenseFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _FilterSheet(current: current, categories: categories),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.categories});

  final ExpenseFilter current;
  final List<Category> categories;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _form = GlobalKey<FormState>();
  late final Set<int> _categories = {...widget.current.categoryIds};
  late DateTimeRange? _range = widget.current.from == null
      ? null
      : DateTimeRange(start: widget.current.from!, end: widget.current.to!);
  late final _merchant = TextEditingController(text: widget.current.merchant);
  late final _min = TextEditingController(
    text: widget.current.minCents == null
        ? ''
        : centsToInput(widget.current.minCents!),
  );
  late final _max = TextEditingController(
    text: widget.current.maxCents == null
        ? ''
        : centsToInput(widget.current.maxCents!),
  );

  @override
  void dispose() {
    _merchant.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  String? _amount(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    return parseMoneyToCents(v!) == null
        ? context.l10n.fieldAmountInvalid
        : null;
  }

  void _apply() {
    if (!_form.currentState!.validate()) return;
    final min = _min.text.trim().isEmpty ? null : parseMoneyToCents(_min.text);
    final max = _max.text.trim().isEmpty ? null : parseMoneyToCents(_max.text);
    Navigator.pop(
      context,
      ExpenseFilter(
        cardId: widget.current.cardId,
        cardIds: widget.current.cardIds,
        categoryIds: _categories,
        from: _range?.start,
        to: _range?.end,
        merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
        minCents: min,
        maxCents: max,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const gap = SizedBox(height: 16);

    return Padding(
      // Keep the fields above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _form,
              child: Column(
                key: const ValueKey('expenseFilter.root'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.filterExpenses, style: text.titleLarge),
                  gap,
                  Text(context.l10n.sectionCategories, style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in widget.categories)
                        FilterChip(
                          key: ValueKey('expenseFilter.category.${c.name}'),
                          showCheckmark: false,
                          avatar: Icon(categoryIcon(c.icon), size: 18),
                          label: Text(context.l10n.categoryLabel(c)),
                          selected: _categories.contains(c.id),
                          onSelected: (on) => setState(
                            () => on
                                ? _categories.add(c.id!)
                                : _categories.remove(c.id),
                          ),
                        ),
                    ],
                  ),
                  gap,
                  OutlinedButton.icon(
                    key: const ValueKey('expenseFilter.dates'),
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _range == null
                          ? context.l10n.allDates
                          : '${formatShortDate(_range!.start)} – '
                                '${formatShortDate(_range!.end)}',
                    ),
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('expenseFilter.merchant'),
                    controller: _merchant,
                    decoration: InputDecoration(
                      labelText: context.l10n.merchantContains,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  gap,
                  // Wrap so both amount fields stack on narrow screens.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final half = (constraints.maxWidth - 12) / 2;
                      final width = half < 160 ? constraints.maxWidth : half;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              key: const ValueKey('expenseFilter.min'),
                              controller: _min,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: _amount,
                              decoration: InputDecoration(
                                labelText: context.l10n.minAmount,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              key: const ValueKey('expenseFilter.max'),
                              controller: _max,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: _amount,
                              decoration: InputDecoration(
                                labelText: context.l10n.maxAmount,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('expenseFilter.apply'),
                    onPressed: _apply,
                    child: Text(context.l10n.apply),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('expenseFilter.clear'),
                    onPressed: () =>
                        Navigator.pop(context, widget.current.cleared()),
                    child: Text(context.l10n.clearFilters),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
