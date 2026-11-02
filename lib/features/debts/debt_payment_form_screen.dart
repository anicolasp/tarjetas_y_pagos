import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/debts.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../data/models/debt_payment.dart';
import '../../data/repositories/debts_repository.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';

/// "Registrar abono": amount (at most what is left; prefilled with it),
/// date and note. Paying what is left settles the debt.
class DebtPaymentFormScreen extends ConsumerWidget {
  const DebtPaymentFormScreen({super.key, required this.debtId});

  final int debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    if (!finance.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final summary = finance.value!.debtSummary(debtId);
    if (summary == null || summary.settled) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            summary == null
                ? context.l10n.debtNotFound
                : context.l10n.debtAlreadySettled,
          ),
        ),
      );
    }
    return _PaymentForm(summary: summary);
  }
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.summary});

  final DebtSummary summary;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: centsToInput(widget.summary.remainingCents),
  );
  final _note = TextEditingController();
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
    final first = DateTime(today.year - 5); // see earliestPaymentDate
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : _date,
      firstDate: first,
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
      final repo = (await ref.read(reposProvider.future)).debts;
      await repo.addPayment(
        user.id!,
        DebtPayment(
          debtId: widget.summary.debt.id!,
          amountCents: parseMoneyToCents(_amount.text)!,
          date: _date,
          note: _note.text,
        ),
      );
      refreshFinance(ref);
      if (mounted) context.pop();
    } on FieldErrorException catch (e) {
      // Business rule from the repository: show why.
      if (mounted) {
        showErrorSnackBar(context, context.l10n.fieldError(e.error)!);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = widget.summary;
    final currency = s.debt.currency;
    const gap = SizedBox(height: 14);

    return Scaffold(
      key: const ValueKey('debtPayment.root'),
      appBar: AppBar(title: Text(context.l10n.addDebtPayment)),
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
                  Text(s.debt.creditor, style: text.titleMedium),
                  Text(
                    context.l10n.debtRemaining(
                      formatMoney(s.remainingCents, currency),
                    ),
                    key: const ValueKey('debtPayment.remaining'),
                    style: text.bodyMedium,
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('debtPayment.amount'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final cents = parseMoneyToCents(v ?? '');
                      if (cents == null || cents <= 0) {
                        return context.l10n.fieldAmountPositive;
                      }
                      if (cents > s.remainingCents) {
                        return context.l10n.maxAmountValue(
                          formatMoney(s.remainingCents, currency),
                        );
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: context.l10n.debtPaymentAmount,
                      prefixText: '${currency.symbol} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  gap,
                  InkWell(
                    key: const ValueKey('debtPayment.date'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.l10n.debtPaymentDate,
                        prefixIcon: const Icon(Icons.event_outlined),
                      ),
                      child: Text(formatDate(_date)),
                    ),
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('debtPayment.note'),
                    controller: _note,
                    maxLength: debtNoteMaxLength,
                    decoration: InputDecoration(
                      labelText: context.l10n.noteOptional,
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    key: const ValueKey('debtPayment.save'),
                    label: context.l10n.addDebtPayment,
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
