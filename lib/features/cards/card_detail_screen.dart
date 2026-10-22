import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing_cycle.dart';
import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import 'cards_providers.dart';
import 'recommendation_text.dart';
import 'widgets/credit_card_tile.dart';

/// A card and its movements. Expenses arrive in #5; for now it shows the
/// card, its cycle and an empty movements state.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(cardByIdProvider(cardId));
    final today = ref.watch(clockProvider)();

    return Scaffold(
      key: const ValueKey('cardDetail.root'),
      appBar: AppBar(
        title: Text(card.value?.alias ?? 'Tarjeta'),
        actions: [
          if (card.value != null)
            IconButton(
              key: const ValueKey('cardDetail.edit'),
              tooltip: 'Editar tarjeta',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.cardEdit(cardId)),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (card) {
          AsyncData(value: final c?) => _Body(
            recommendation: recommendationFor(c, today),
            today: today,
          ),
          AsyncData() ||
          AsyncError() => const Center(child: Text('Tarjeta no encontrada')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.recommendation, required this.today});

  final CardRecommendation recommendation;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        ResponsiveCenter(
          maxWidth: ContentWidth.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreditCardTile(card: r.card, recommendation: r),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Row('Próximo corte', formatDate(r.nextCut)),
                      _Row('Fecha límite de pago', formatDate(r.dueDate)),
                      _Row(
                        'Si la usas hoy, pagas en',
                        '${r.financingDays} días',
                      ),
                      _Row(
                        'Disponible',
                        r.availableCents == null
                            ? 'Sin límite registrado'
                            : formatMoney(r.availableCents!, r.card.currency),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explainRecommendation(r, today),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Movimientos', style: text.titleMedium),
              const SizedBox(height: 12),
              Column(
                key: const ValueKey('cardDetail.empty'),
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no hay movimientos en esta tarjeta',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Muy pronto podrás registrar tus gastos aquí.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Wrap so label and value stack instead of overflowing with big text.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 2,
        children: [
          Text(label, style: text.bodyMedium),
          Text(
            value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
