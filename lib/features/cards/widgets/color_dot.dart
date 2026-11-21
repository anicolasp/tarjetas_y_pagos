import 'package:flutter/material.dart';

/// A color to pick (card and category forms): a 40 dp dot inside a 48 dp
/// touch area, labeled for screen readers (#40).
class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.checkSize = 20,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// The check mark on the selected dot.
  final double checkSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, color: Colors.white, size: checkSize)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
