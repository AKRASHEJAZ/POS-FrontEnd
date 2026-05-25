import 'package:flutter/material.dart';

class UserFormGrid extends StatelessWidget {
  final double maxWidth;
  final List<Widget> children;

  const UserFormGrid({
    super.key,
    required this.maxWidth,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final width = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 592.0;
    final useTwoColumns = width >= 480;

    if (!useTwoColumns) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[i]),
            if (i + 1 < children.length) ...[
              const SizedBox(width: 16),
              Expanded(child: children[i + 1]),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(children: rows);
  }
}
