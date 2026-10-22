import 'package:flutter/material.dart';

/// Material 3 window size classes, by available width.
enum ScreenSize {
  /// Phones in portrait (< 600dp).
  compact,

  /// Large phones in landscape, small tablets (600–839dp).
  medium,

  /// Tablets and larger (>= 840dp).
  expanded;

  static ScreenSize fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    return expanded;
  }
}

/// Max widths so content never stretches edge to edge on wide screens.
abstract final class ContentWidth {
  static const form = 480.0;
  static const page = 840.0;
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize =>
      ScreenSize.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompact => screenSize == ScreenSize.compact;

  /// Horizontal page padding for the current size class.
  double get pagePadding => switch (screenSize) {
    ScreenSize.compact => 16,
    ScreenSize.medium => 24,
    ScreenSize.expanded => 32,
  };
}

/// Centers [child] horizontally, caps its width at [maxWidth] and applies the
/// size-class page padding. Use it as the body wrapper of every screen.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    this.maxWidth = ContentWidth.page,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
          child: child,
        ),
      ),
    );
  }
}

/// Vertically centered content that scrolls instead of overflowing when the
/// screen is short (landscape, large text scale, keyboard open).
class CenteredScrollView extends StatelessWidget {
  const CenteredScrollView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
