import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wraps content in a centered container with a maximum width on Web/Desktop.
/// This prevents the UI from stretching too far on wide screens.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool center;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A specialized version for Grids (like the product vitrin).
class ResponsiveGridWrapper extends StatelessWidget {
  final Widget Function(BuildContext context, int crossAxisCount) builder;

  const ResponsiveGridWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 2; // Default for mobile
        if (constraints.maxWidth > 1200) {
          count = 5;
        } else if (constraints.maxWidth > 900) {
          count = 4;
        } else if (constraints.maxWidth > 600) {
          count = 3;
        }
        return builder(context, count);
      },
    );
  }
}
