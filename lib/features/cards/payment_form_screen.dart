import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../data/models/card_payment.dart';
import '../../data/models/credit_card.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_widgets.dart';
import 'cards_providers.dart';

/// "Registrar pago" of a card: amount, currency (one the card holds), date
/// and note. Paying more than the balance is allowed (saldo a favor).
class PaymentFormScreen extends ConsumerWidget {
  const PaymentFormScreen({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    final card = finance.value?.card(cardId);
    if (finance.isLoading && !finance.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.cardNotFound)),
      );
    }
    final statement = finance.value!.statementOf(
      card,
      ref.watch(clockProvider)(),
    );
    return _PaymentForm(
      card: card,
      dueCents: {
        for (final s in statement.byCurrency.values) s.currency: s.dueCents,
      },
    );
  }
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.card, required this.dueCents});

  final CreditCard card;

  /// "A pagar este corte" per currency, offered as a shortcut.
  final Map<Currency, int> dueCents;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late var _currency = widget.card.currency;
  late var _date = ref.read(clockProvider)();
  var _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final repo = (await ref.read(reposProvider.future)).expenses;
      await repo.addPayment(
        user.id!,
        CardPayment(
          cardId: widget.card.id!,
          amountCents: parseMoneyToCents(_amount.text)!,
          currency: _currency,
          date: _date,
          note: _note.text,
        ),
      );
      refreshFinance(ref);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final due = widget.dueCents[_currency] ?? 0;
    const gap = SizedBox(height: 14);

    return Scaffold(
      key: const ValueKey('paymentForm.root'),
      appBar: AppBar(title: Text(context.l10n.registerPayment)),
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
                  Text(
                    '${widget.card.alias} •••• ${widget.card.last4}',
                    style: text.titleMedium,
                  ),
                  gap,
                  if (widget.card.currencies.length > 1) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in widget.card.currencies)
                          ChoiceChip(
                            key: ValueKey('paymentForm.currency.${c.code}'),
                            label: Text('${c.symbol} ${c.code}'),
                            selected: _currency == c,
                            onSelected: (_) => setState(() => _currency = c),
                          ),
                      ],
                    ),
                    gap,
                  ],
                  TextFormField(
                    key: const ValueKey('paymentForm.amount'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final cents = parseMoneyToCents(v ?? '');
                      return cents != null && cents > 0
                          ? null
                          : context.l10n.fieldAmountPositive;
                    },
                    decoration: InputDecoration(
                      labelText: context.l10n.amountPaid,
                      prefixText: '${_currency.symbol} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  if (due > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const ValueKey('paymentForm.fillDue'),
                        onPressed: () =>
                            setState(() => _amount.text = centsToInput(due)),
                        child: Text(
                          context.l10n.payStatementDue(formatMoney(due, _currency)),
                        ),
                      ),
                    ),
                  gap,
                  InkWell(
                    key: const ValueKey('paymentForm.date'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.l10n.paymentDate,
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(formatDate(_date)),
                    ),
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('paymentForm.note'),
                    controller: _note,
                    maxLength: notesMaxLength,
                    decoration: InputDecoration(
                      labelText: context.l10n.noteOptional,
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    key: const ValueKey('paymentForm.save'),
                    label: context.l10n.registerPayment,
                    loading: _saving,
                    onPressed: _save,
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
