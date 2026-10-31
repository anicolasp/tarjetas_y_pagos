import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart' show notifyDaysRange;
import '../../l10n/l10n.dart';

/// − N días + for the reminders' notice (0–30). Keys are
/// `<keyPrefix>`, `<keyPrefix>.minus` and `<keyPrefix>.plus`.
class NoticeDaysStepper extends StatelessWidget {
  const NoticeDaysStepper({
    super.key,
    required this.days,
    required this.onChanged,
    required this.keyPrefix,
  });

  final int days;
  final ValueChanged<int>? onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('$keyPrefix.minus'),
          tooltip: context.l10n.fewerDays,
          onPressed: onChanged == null || days <= notifyDaysRange.min
              ? null
              : () => onChanged!(days - 1),
          icon: const Icon(Icons.remove),
        ),
        // Wraps instead of overflowing: "3 jours avant" is much longer than
        // "3 días" on a small phone.
        Flexible(
          child: Text(
            context.l10n.daysCount(days),
            key: ValueKey(keyPrefix),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: ValueKey('$keyPrefix.plus'),
          tooltip: context.l10n.moreDays,
          onPressed: onChanged == null || days >= notifyDaysRange.max
              ? null
              : () => onChanged!(days + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
