import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/debt_payment.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';
import '../expenses/widgets/movement_tile.dart';
import 'debts_screen.dart';

/// A debt: its figures, "Registrar abono" and the payment history (a
/// payment can be deleted; a settled debt then goes back to Activas).
class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final int debtId;

  Future<void> _deletePayment(
    BuildContext context,
    WidgetRef ref,
    DebtPayment payment,
    String amount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este abono?'),
        content: Text('Lo que falta por pagar volverá a subir $amount.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('debtDetail.deletePaymentConfirm'),
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
      final repo = (await ref.read(reposProvider.future)).debts;
      await repo.deletePayment(user.id!, payment.id!);
      refreshFinance(ref);
    } catch (_) {
      if (context.mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finance = ref.watch(financeProvider);
    final today = ref.watch(clockProvider)();
    if (!finance.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final snapshot = finance.value!;
    final summary = snapshot.debtSummary(debtId);
    if (summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Deuda no encontrada')),
      );
    }
    final d = summary.debt;
    final payments = [
      for (final p in snapshot.debtPayments)
        if (p.debtId == debtId) p,
    ];
    final text = Theme.of(context).textTheme;
    const paid = Color(0xFF2E7D32); // reads in both themes

    return Scaffold(
      key: const ValueKey('debtDetail.root'),
      appBar: AppBar(
        title: const Text('Deuda'),
        actions: [
          IconButton(
            key: const ValueKey('debtDetail.edit'),
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.debtEdit(debtId)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DebtSummaryView(
                      summary: summary,
                      today: today,
                      large: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!summary.settled)
                  FilledButton.icon(
                    key: const ValueKey('debtDetail.addPayment'),
                    onPressed: () => context.push(Routes.debtPay(debtId)),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar abono'),
                  )
                else
                  Row(
                    key: const ValueKey('debtDetail.settled'),
                    children: [
                      const Icon(Icons.check_circle, color: paid),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Deuda saldada', style: text.titleMedium),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Text('Abonos', style: text.titleMedium),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  Text(
                    'Todavía no hay abonos.',
                    key: const ValueKey('debtDetail.noPayments'),
                    style: text.bodyMedium,
                  )
                else
                  for (final p in payments)
                    MovementTile(
                      key: ValueKey('debtDetail.payment.${p.id}'),
                      icon: Icons.check_circle_outline,
                      color: paid,
                      title: formatDate(p.date),
                      subtitle: p.note,
                      amount: '−${formatMoney(p.amountCents, d.currency)}',
                      amountColor: paid,
                      onTap: () => _deletePayment(
                        context,
                        ref,
                        p,
                        formatMoney(p.amountCents, d.currency),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
