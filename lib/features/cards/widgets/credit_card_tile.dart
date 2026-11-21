import 'package:flutter/material.dart';

import '../../../core/billing_cycle.dart';
import '../../../core/formatters.dart';
import '../../../data/models/credit_card.dart';
import '../../../l10n/l10n.dart';

/// A credit card drawn in its color: bank, brand, alias, `•••• 1234`, next
/// cut and available credit. Height follows the content, so it never
/// overflows with large text.
class CreditCardTile extends StatelessWidget {
  const CreditCardTile({
    super.key,
    required this.card,
    required this.recommendation,
    this.onTap,
  });

  final CreditCard card;
  final CardRecommendation recommendation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(card.color);
    final text = Theme.of(context).textTheme;
    const onCard = Colors.white;
    final muted = onCard.withValues(alpha: 0.78);
    // "Disponible RD$ 50,000.00 · US$ 1,000.00" (one per limited currency).
    final available = recommendation.available.entries
        .map((e) => formatMoney(e.value, e.key))
        .join(' · ');

    final l = context.l10n;
    // One element for screen readers (#40): "Gastos de la casa, Visa
    // ending in 4321, Banco Ficticio, Corte 5/dic, Disponible 50000 pesos
    // dominicanos", with the tap kept as its action.
    final spoken = [
      card.alias,
      l.spokenCardEnding(card),
      card.bank,
      l.cutOn(formatDate(recommendation.nextCut)),
      available.isEmpty ? l.availableNone : l.availableAmount(available),
      if (card.dualCurrency) l.dualBalance,
    ].join(', ');

    return Semantics(
      container: true,
      button: onTap != null,
      label: l.spokenLabel(spoken) ?? spoken,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 170),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, 0.35)!],
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap: with very large text the brand moves below the bank
                // instead of splitting the bank name mid-word.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      card.bank,
                      style: text.labelLarge?.copyWith(color: muted),
                    ),
                    BrandMark(card.brand),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  card.alias,
                  style: text.titleLarge?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '•••• ${card.last4}',
                  style: text.titleMedium?.copyWith(
                    color: onCard,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      context.l10n.cutOn(
                        formatDayMonth(recommendation.nextCut),
                      ),
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                    Text(
                      available.isEmpty
                          ? context.l10n.availableNone
                          : context.l10n.availableAmount(available),
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                    if (card.dualCurrency)
                      Text(
                        context.l10n.dualBalance,
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Visa / Mastercard / Amex mark drawn without image assets.
class BrandMark extends StatelessWidget {
  const BrandMark(this.brand, {super.key});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return switch (brand) {
      CardBrand.visa => const Text(
        'VISA',
        style: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1,
        ),
      ),
      CardBrand.mastercard => Semantics(
        label: 'Mastercard',
        child: const SizedBox(
          width: 38,
          height: 24,
          child: Stack(
            children: [
              Positioned(left: 0, child: _Dot(Color(0xFFEB001B))),
              Positioned(right: 0, child: _Dot(Color(0xCCF79E1B))),
            ],
          ),
        ),
      ),
      CardBrand.amex => const Text(
        'AMEX',
        style: TextStyle(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      CardBrand.other => const Icon(Icons.credit_card, color: white),
    };
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
