import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/category_icons.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/report.dart';
import '../../data/models/category.dart';
import '../../data/models/credit_card.dart';
import 'chart_colors.dart';

/// A titled section of the summary.
class ReportSection extends StatelessWidget {
  const ReportSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Total, average and count of one currency.
class CurrencyTotalsTile extends StatelessWidget {
  const CurrencyTotalsTile({super.key, required this.totals});

  final CurrencyTotals totals;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final code = totals.currency.code;
    Widget stat(String key, String label, String value) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        key: ValueKey('reports.$key.$code'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: text.titleLarge),
        ],
      ),
    );

    return ReportSection(
      title: 'Gastos en ${totals.currency.symbol}',
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          stat(
            'total',
            'Total',
            formatMoney(totals.totalCents, totals.currency),
          ),
          stat(
            'average',
            'Promedio por gasto',
            formatMoney(totals.averageCents, totals.currency),
          ),
          stat('count', 'Cantidad', '${totals.count}'),
        ],
      ),
    );
  }
}

/// Donut of the largest categories plus "Resto", with a legend that names
/// every slice (icon, name, amount, %): the color is never the only cue.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.report,
    required this.currency,
    required this.categories,
  });

  final ExpenseReport report;
  final Currency currency;
  final Map<int, Category> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (:top, :rest) = report.topCategoriesIn(currency);
    final total = report.totals[currency]?.totalCents ?? 0;
    if (total == 0) return const SizedBox.shrink();

    // Gray, lighter than "Otros" (#757575), so the two never look alike.
    final restColor = readableOn(scheme.outlineVariant, scheme.surface);
    final slices = [
      for (final t in top)
        (
          key: 'reports.category.${t.categoryId}',
          label: categories[t.categoryId]?.name ?? 'Sin categoría',
          icon: categoryIcon(categories[t.categoryId]?.icon ?? 'category'),
          color: readableOn(
            Color(categories[t.categoryId]?.color ?? 0xFF757575),
            scheme.surface,
          ),
          cents: t.totalCents,
        ),
      if (rest != null)
        (
          key: 'reports.category.rest',
          label: 'Resto (${rest.categories})',
          icon: Icons.more_horiz,
          color: restColor,
          cents: rest.totalCents,
        ),
    ];

    final donut = SizedBox.square(
      dimension: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 58,
              startDegreeOffset: -90,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.cents.toDouble(),
                    color: s.color,
                    radius: 28,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(64),
            child: FittedBox(
              child: Text(
                formatMoney(total, currency),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in slices)
          _LegendRow(
            key: ValueKey(s.key),
            icon: s.icon,
            color: s.color,
            label: s.label,
            value: formatMoney(s.cents, currency),
            percent: '${(s.cents * 100 / total).round()} %',
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 520
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                donut,
                const SizedBox(width: 24),
                Expanded(child: legend),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: donut),
                const SizedBox(height: 16),
                legend,
              ],
            ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String percent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(label, style: text.bodyMedium),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '  $percent',
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spending per month: one series, so one color (the app's primary).
class MonthBars extends StatelessWidget {
  const MonthBars({super.key, required this.months, required this.currency});

  final List<({DateTime month, int totalCents})> months;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final multiYear =
        months.isNotEmpty && months.first.month.year != months.last.month.year;
    final maxCents = months.fold(
      0,
      (m, e) => e.totalCents > m ? e.totalCents : m,
    );
    final compact = NumberFormat.compact(locale: appLocale);
    String monthLabel(DateTime m, {bool long = false}) {
      final name = DateFormat(
        long ? 'MMMM y' : 'MMM',
        appLocale,
      ).format(m).replaceAll('.', '');
      return !long && multiYear ? '$name ${m.year % 100}' : name;
    }

    return SizedBox(
      height: 200 + 24 * scale,
      child: BarChart(
        BarChartData(
          maxY: maxCents == 0 ? 1 : maxCents * 1.15,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40 * scale,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    compact.format(value / 100),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24 * scale,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    monthLabel(months[value.toInt()].month),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${monthLabel(months[group.x].month, long: true)}\n'
                '${formatMoney(months[group.x].totalCents, currency)}',
                TextStyle(color: scheme.onInverseSurface),
              ),
            ),
          ),
          barGroups: [
            for (final (i, m) in months.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: m.totalCents.toDouble(),
                    color: scheme.primary,
                    width: months.length > 8 ? 10 : 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Totals per card: a row per card with its color as a swatch and a thin
/// bar for its share.
class CardTotals extends StatelessWidget {
  const CardTotals({
    super.key,
    required this.totals,
    required this.currency,
    required this.cards,
  });

  final List<CardTotal> totals;
  final Currency currency;
  final Map<int, CreditCard> cards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final largest = totals.isEmpty ? 1 : totals.first.totalCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in totals)
          Padding(
            key: ValueKey('reports.card.${t.cardId}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  children: [
                    Text(_cardName(cards[t.cardId]), style: text.bodyMedium),
                    Text(
                      formatMoney(t.totalCents, currency),
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: t.totalCents / largest,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: readableOn(
                      Color(cards[t.cardId]?.color ?? 0xFF757575),
                      scheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _cardName(CreditCard? c) => c == null
      ? 'Tarjeta'
      : '${c.alias} •••• ${c.last4}${c.archived ? ' (archivada)' : ''}';
}
