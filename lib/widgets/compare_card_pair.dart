import 'package:flutter/material.dart';

/// The A/B cards on the compare pages: side by side when there is room,
/// stacked on phones (two columns squeezed the labels letter by letter).
class CompareCardPair extends StatelessWidget {
  final Widget? first;
  final Widget? second;

  const CompareCardPair({super.key, this.first, this.second});

  @override
  Widget build(BuildContext context) {
    final cards = [?first, ?second];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}
