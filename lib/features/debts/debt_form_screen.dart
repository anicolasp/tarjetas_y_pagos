import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/debt.dart';
import '../../data/repositories/debts_repository.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';

/// New debt ([debtId] null) or edit/delete one.
class DebtFormScreen extends ConsumerWidget {
  const DebtFormScreen({super.key, this.debtId});

  final int? debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debtId == null) return const _DebtForm(debt: null, paidCents: 0);
    final finance = ref.watch(financeProvider);
    if (!finance.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final summary = finance.value!.debtSummary(debtId!);
    if (summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Deuda no encontrada')),
      );
    }
    return _DebtForm(debt: summary.debt, paidCents: summary.paidCents);
  }
}

class _DebtForm extends ConsumerStatefulWidget {
  const _DebtForm({required this.debt, required this.paidCents});

  final Debt? debt;
  final int paidCents;

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  final _form = GlobalKey<FormState>();
  late final Debt? _d = widget.debt;
  late final _creditor = TextEditingController(text: _d?.creditor);
  late final _description = TextEditingController(text: _d?.description);
  late final _amount = TextEditingController(
    text: _d == null ? '' : centsToInput(_d.amountCents),
  );
  late var _currency =
      _d?.currency ??
      ref.read(currentUserProvider)?.defaultCurrency ??
      Currency.dop;
  late DateTime? _due = _d?.dueDate;
  var _saving = false;

  bool get _editing => _d != null;

  /// With payments, the currency is fixed (they were made in it).
  bool get _currencyLocked => widget.paidCents > 0;

  @override
  void dispose() {
    for (final c in [_creditor, _description, _amount]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDue() async {
    final today = ref.read(clockProvider)();
    final initial = _due ?? today.add(const Duration(days: 30));
    var first = DateTime(today.year - 5);
    var last = DateTime(today.year + 10);
    // A stored date outside the usual range must still open the picker.
    if (initial.isBefore(first)) first = initial;
    if (initial.isAfter(last)) last = initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    final debt = Debt(
      id: _d?.id,
      userId: user.id!,
      creditor: _creditor.text,
      description: _description.text,
      amountCents: parseMoneyToCents(_amount.text)!,
      currency: _currency,
      dueDate: _due,
      status: _d?.status ?? DebtStatus.active,
      createdAt: _d?.createdAt ?? ref.read(clockProvider)(),
    );
    try {
      final repo = (await ref.read(reposProvider.future)).debts;
      if (_editing) {
        await repo.update(debt);
      } else {
        await repo.create(debt);
      }
      refreshFinance(ref);
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      // Business rule from the repository: show why.
      if (mounted) showErrorSnackBar(context, '${e.message}');
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDestructive(
      context,
      title: '¿Eliminar esta deuda?',
      body: 'También se eliminan sus abonos.',
      confirmKey: const ValueKey('debtForm.deleteConfirm'),
    );
    if (!confirmed || !mounted) return;
    try {
      final repo = (await ref.read(reposProvider.future)).debts;
      await repo.delete(_d!.userId, _d.id!);
      refreshFinance(ref);
      if (mounted) context.go(Routes.debts);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedError(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 14);

    return Scaffold(
      key: const ValueKey('debtForm.root'),
      appBar: AppBar(title: Text(_editing ? 'Editar deuda' : 'Nueva deuda')),
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
                    key: const ValueKey('debtForm.creditor'),
                    controller: _creditor,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: creditorMaxLength,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Escribe a quién le debes'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Acreedor (ej. Préstamo Juan)',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                  ),
                  gap,
                  TextFormField(
                    key: const ValueKey('debtForm.description'),
                    controller: _description,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: debtDescriptionMaxLength,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  gap,
                  Text('Moneda', style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in Currency.values)
                        ChoiceChip(
                          key: ValueKey('debtForm.currency.${c.code}'),
                          label: Text('${c.symbol} ${c.code}'),
                          selected: _currency == c,
                          onSelected: _currencyLocked
                              ? null
                              : (_) => setState(() => _currency = c),
                        ),
                    ],
                  ),
                  if (_currencyLocked)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Text(
                        'Tiene abonos: la moneda ya no se puede cambiar.',
                        style: text.bodySmall,
                      ),
                    ),
                  gap,
                  TextFormField(
                    key: const ValueKey('debtForm.amount'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final cents = parseMoneyToCents(v ?? '');
                      if (cents == null || cents <= 0) {
                        return 'Escribe un monto mayor que 0';
                      }
                      if (cents < widget.paidCents) {
                        return 'Ya abonaste '
                            '${formatMoney(widget.paidCents, _currency)}';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Monto total',
                      prefixText: '${_currency.symbol} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  gap,
                  InkWell(
                    key: const ValueKey('debtForm.dueDate'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDue,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Vence (opcional)',
                        prefixIcon: const Icon(Icons.event_outlined),
                        suffixIcon: _due == null
                            ? null
                            : IconButton(
                                key: const ValueKey('debtForm.clearDue'),
                                tooltip: 'Sin fecha',
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _due = null),
                              ),
                      ),
                      child: Text(
                        _due == null ? 'Sin fecha' : formatDate(_due!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    key: const ValueKey('debtForm.save'),
                    label: _editing ? 'Guardar cambios' : 'Guardar deuda',
                    loading: _saving,
                    onPressed: _save,
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('debtForm.delete'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: scheme.error,
                      ),
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar deuda'),
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
