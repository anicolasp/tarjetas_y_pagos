import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_icons.dart';
import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/category.dart';
import '../../data/models/credit_card.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expenses_repository.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';

/// New expense ([expenseId] null; [initialCardId] preselects the card) or
/// edit/delete an existing one.
class ExpenseFormScreen extends ConsumerWidget {
  const ExpenseFormScreen({super.key, this.expenseId, this.initialCardId});

  final int? expenseId;
  final int? initialCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    final categories = ref.watch(categoriesProvider);
    final expense = expenseId == null
        ? const AsyncData<Expense?>(null)
        : ref.watch(expenseByIdProvider(expenseId!));

    Widget message(String text) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(text, textAlign: TextAlign.center)),
    );

    if (finance.hasError || categories.hasError || expense.hasError) {
      return message('No se pudo cargar el gasto');
    }
    if (!finance.hasValue || !categories.hasValue || !expense.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (expenseId != null && expense.value == null) {
      return message('Gasto no encontrado');
    }
    final cards = finance.value!.cards;
    if (cards.isEmpty) return const _NoCards();

    return _ExpenseForm(
      cards: cards,
      categories: categories.value!,
      expense: expense.value,
      initialCardId: initialCardId,
    );
  }
}

class _NoCards extends StatelessWidget {
  const _NoCards();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('expenseForm.noCards'),
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: SafeArea(
        child: CenteredScrollView(
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card_off_outlined, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Primero agrega una tarjeta para registrar gastos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('expenseForm.addCard'),
                  onPressed: () => context.pushReplacement(Routes.cardNew),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar tarjeta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({
    required this.cards,
    required this.categories,
    required this.expense,
    required this.initialCardId,
  });

  final List<CreditCard> cards;
  final List<Category> categories;
  final Expense? expense;
  final int? initialCardId;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

enum _RateStatus { idle, loading, online, stale, unavailable }

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _form = GlobalKey<FormState>();
  late final Expense? _e = widget.expense;
  late final _merchant = TextEditingController(text: _e?.merchant);
  // When editing a converted expense, show what was paid originally.
  late final _amount = TextEditingController(
    text: _e == null
        ? ''
        : centsToInput(_e.originalAmountCents ?? _e.amountCents),
  );
  late final _notes = TextEditingController(text: _e?.notes);
  late final _rate = TextEditingController(
    text: _e?.exchangeRateMicros == null
        ? ''
        : formatRate(_e!.exchangeRateMicros!),
  );

  /// Selected card by id: [widget.cards] holds fresh objects after every
  /// reload, so the selection must not depend on object identity.
  late int? _cardId = _initialCardId();
  CreditCard? get _card {
    for (final c in widget.cards) {
      if (c.id == _cardId) return c;
    }
    return null;
  }

  /// Editing an expense whose card is archived: it can be deleted, but not
  /// edited (moving it to another card would change both balances).
  late final bool _cardArchived =
      _e != null && !widget.cards.any((c) => c.id == _e.cardId);

  /// The user typed a rate: a late online answer must not replace it.
  var _rateTouched = false;
  late int? _categoryId = _e?.categoryId;
  late Currency _currency =
      _e?.originalCurrency ?? _e?.currency ?? _card?.currency ?? Currency.dop;
  late DateTime _date = _e?.date ?? ref.read(clockProvider)();
  var _rateStatus = _RateStatus.idle;
  var _saving = false;
  String? _categoryError;

  bool get _editing => _e != null;

  int? _initialCardId() {
    final id = _e?.cardId ?? widget.initialCardId;
    if (widget.cards.any((c) => c.id == id)) return id;
    // Never fall back to another card when editing (archived card).
    if (_e != null) return null;
    // A preselected card from the detail; otherwise the user picks one,
    // unless there is only one.
    return widget.cards.length == 1 ? widget.cards.single.id : null;
  }

  /// The card holds a single currency different from the typed one.
  bool get _needsConversion =>
      _card != null && !_card!.currencies.contains(_currency);

  @override
  void initState() {
    super.initState();
    if (_needsConversion && _rate.text.isEmpty) _loadRate();
  }

  @override
  void dispose() {
    for (final c in [_merchant, _amount, _notes, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  /// [force]: the user asked for today's rate (refresh button), replacing
  /// whatever is typed.
  Future<void> _loadRate({bool force = false}) async {
    if (force) _rateTouched = false;
    setState(() => _rateStatus = _RateStatus.loading);
    final quote = await ref.read(exchangeRateServiceProvider).usdToDop();
    if (!mounted) return;
    setState(() {
      if (_rateTouched) {
        _rateStatus = _RateStatus.idle;
        return;
      }
      if (quote == null) {
        _rateStatus = _RateStatus.unavailable;
        return;
      }
      _rate.text = formatRate(quote.usdToDopMicros);
      _rateStatus = quote.stale ? _RateStatus.stale : _RateStatus.online;
    });
  }

  void _selectCard(int? id) {
    setState(() {
      _cardId = id;
      final card = _card;
      // Default to the card's (main) currency when switching cards.
      if (card != null && !card.currencies.contains(_currency)) {
        _currency = card.currency;
      }
    });
  }

  void _selectCurrency(Currency c) {
    setState(() => _currency = c);
    if (_needsConversion && _rate.text.isEmpty) _loadRate();
  }

  /// Amount that will count on the card, or null if not computable yet.
  int? get _cardAmountCents {
    final typed = parseMoneyToCents(_amount.text);
    if (typed == null || _card == null) return null;
    if (!_needsConversion) return typed;
    final rate = parseRateMicros(_rate.text);
    if (rate == null) return null;
    return convertBetween(typed, _currency, _card!.currency, rate);
  }

  Future<void> _pickDate() async {
    final today = ref.read(clockProvider)();
    final fiveYearsAgo = DateTime(today.year - 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // An older expense being edited must still open the picker.
      firstDate: _date.isBefore(fiveYearsAgo) ? _date : fiveYearsAgo,
      lastDate: today, // no future expenses
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(
      () => _categoryError = _categoryId == null ? 'Elige una categoría' : null,
    );
    final valid = _form.currentState!.validate();
    if (_saving || !valid || _categoryError != null) return;
    final user = ref.read(currentUserProvider);
    final cardCents = _cardAmountCents;
    if (user == null || cardCents == null || cardCents <= 0) return;

    final typed = parseMoneyToCents(_amount.text)!;
    final converted = _needsConversion;
    final expense = Expense(
      id: _e?.id,
      userId: user.id!,
      cardId: _card!.id!,
      categoryId: _categoryId!,
      merchant: _merchant.text,
      amountCents: cardCents,
      currency: converted ? _card!.currency : _currency,
      date: _date,
      notes: _notes.text,
      source: _e?.source ?? ExpenseSource.manual,
      originalAmountCents: converted ? typed : null,
      originalCurrency: converted ? _currency : null,
      exchangeRateMicros: converted ? parseRateMicros(_rate.text) : null,
      createdAt: _e?.createdAt ?? ref.read(clockProvider)(),
    );

    setState(() => _saving = true);
    try {
      final repo = (await ref.read(reposProvider.future)).expenses;
      if (_editing) {
        await repo.update(expense);
      } else {
        await repo.create(expense);
      }
      refreshFinance(ref);
      if (mounted) context.pop();
    } catch (_) {
      // Repository errors (ArgumentError/StateError) and I/O failures.
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este gasto?'),
        content: const Text('Se quitará de la tarjeta y de los reportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('expenseForm.deleteConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final repo = (await ref.read(reposProvider.future)).expenses;
      await repo.delete(_e!.userId, _e.id!);
      refreshFinance(ref);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 14);

    return Scaffold(
      key: const ValueKey('expenseForm.root'),
      appBar: AppBar(title: Text(_editing ? 'Editar gasto' : 'Nuevo gasto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('expenseForm.merchant'),
                    controller: _merchant,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: merchantMaxLength,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Escribe el comercio' : null,
                    decoration: const InputDecoration(
                      labelText: 'Comercio',
                      prefixIcon: Icon(Icons.storefront_outlined),
                      counterText: '',
                    ),
                  ),
                  gap,
                  Text('Categoría', style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in widget.categories)
                        ChoiceChip(
                          key: ValueKey('expenseForm.category.${c.name}'),
                          // The tinted background marks the selection; a
                          // checkmark would cover the category icon.
                          showCheckmark: false,
                          avatar: Icon(
                            categoryIcon(c.icon),
                            size: 18,
                            color: Color(c.color),
                          ),
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(() {
                            _categoryId = c.id;
                            _categoryError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_categoryError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Text(
                        _categoryError!,
                        style: text.bodySmall?.copyWith(color: scheme.error),
                      ),
                    ),
                  gap,
                  if (_cardArchived)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'La tarjeta de este gasto está archivada: puedes '
                        'eliminarlo, pero no editarlo.',
                        key: const ValueKey('expenseForm.archivedCard'),
                        style: text.bodyMedium?.copyWith(color: scheme.error),
                      ),
                    ),
                  DropdownButtonFormField<int>(
                    key: const ValueKey('expenseForm.card'),
                    initialValue: _cardId,
                    isExpanded: true,
                    validator: (id) => id == null ? 'Elige una tarjeta' : null,
                    decoration: const InputDecoration(
                      labelText: 'Tarjeta',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    items: [
                      for (final c in widget.cards)
                        DropdownMenuItem(
                          key: ValueKey('expenseForm.cardOption.${c.id}'),
                          value: c.id,
                          child: Text(
                            '${c.alias} •••• ${c.last4}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _cardArchived ? null : _selectCard,
                  ),
                  gap,
                  Text('Moneda del gasto', style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in Currency.values)
                        ChoiceChip(
                          key: ValueKey('expenseForm.currency.${c.code}'),
                          label: Text('${c.symbol} ${c.code}'),
                          selected: _currency == c,
                          onSelected: (_) => _selectCurrency(c),
                        ),
                    ],
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('expenseForm.amount'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final cents = parseMoneyToCents(v ?? '');
                      return cents != null && cents > 0
                          ? null
                          : 'Escribe un monto mayor que 0';
                    },
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixText: '${_currency.symbol} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  if (_needsConversion) ...[
                    gap,
                    _RateField(
                      controller: _rate,
                      status: _rateStatus,
                      onChanged: () => setState(() => _rateTouched = true),
                      onRetry: () => _loadRate(force: true),
                    ),
                    if (_cardAmountCents case final cents?)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8),
                        child: Text(
                          'Se registra en la tarjeta como '
                          '${formatMoney(cents, _card!.currency)}',
                          key: const ValueKey('expenseForm.convertedPreview'),
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  gap,
                  InkWell(
                    key: const ValueKey('expenseForm.date'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(formatDate(_date)),
                    ),
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('expenseForm.notes'),
                    controller: _notes,
                    maxLength: notesMaxLength,
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_cardArchived)
                    LoadingButton(
                      key: const ValueKey('expenseForm.save'),
                      label: _editing ? 'Guardar cambios' : 'Guardar gasto',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('expenseForm.delete'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: scheme.error,
                      ),
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar gasto'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tasa (RD$ por US$)" with where it came from and a retry.
class _RateField extends StatelessWidget {
  const _RateField({
    required this.controller,
    required this.status,
    required this.onChanged,
    required this.onRetry,
  });

  final TextEditingController controller;
  final _RateStatus status;
  final VoidCallback onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final helper = switch (status) {
      _RateStatus.loading => 'Buscando la tasa de hoy…',
      _RateStatus.online =>
        'Tasa en línea de hoy. Puedes ajustarla a la de tu banco.',
      _RateStatus.stale => 'Sin conexión: última tasa conocida. Revísala.',
      _RateStatus.unavailable => 'No se pudo obtener la tasa. Escríbela.',
      _RateStatus.idle => 'Tasa usada en la conversión.',
    };
    return TextFormField(
      key: const ValueKey('expenseForm.rate'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      validator: (v) => parseRateMicros(v ?? '') == null
          ? 'Escribe la tasa (ej. 61.40)'
          : null,
      decoration: InputDecoration(
        labelText: 'Tasa (RD\$ por US\$ 1)',
        prefixIcon: const Icon(Icons.currency_exchange),
        helperText: helper,
        helperMaxLines: 2,
        suffixIcon: status == _RateStatus.loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                key: const ValueKey('expenseForm.rateRefresh'),
                tooltip: 'Buscar la tasa de hoy',
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
              ),
      ),
    );
  }
}
