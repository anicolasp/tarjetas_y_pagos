import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/debts.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../data/models/debt_payment.dart';
import '../../data/repositories/debts_repository.dart';
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
                ? 'Deuda no encontrada'
                : 'La deuda ya está saldada',
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
    } on ArgumentError catch (e) {
      if (mounted) showErrorSnackBar(context, '${e.message}');
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
      appBar: AppBar(title: const Text('Registrar abono')),
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
                    'Falta ${formatMoney(s.remainingCents, currency)}',
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
                        return 'Escribe un monto mayor que 0';
                      }
                      if (cents > s.remainingCents) {
                        return 'Máximo ${formatMoney(s.remainingCents, currency)}';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Monto del abono',
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
                      decoration: const InputDecoration(
                        labelText: 'Fecha del abono',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(formatDate(_date)),
                    ),
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('debtPayment.note'),
                    controller: _note,
                    maxLength: debtNoteMaxLength,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    key: const ValueKey('debtPayment.save'),
                    label: 'Registrar abono',
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
