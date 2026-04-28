import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_ext.dart';

class QuickReplyChips extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onTap;

  const QuickReplyChips({
    super.key,
    required this.replies,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: replies.map((reply) {
          return ActionChip(
            label: Text(reply),
            labelStyle: TextStyle(
              color: context.colors.primary,
              fontSize: 13,
            ),
            backgroundColor: context.colors.primary.withValues(alpha: 0.12),
            side: BorderSide(
              color: context.colors.primary.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => onTap(reply),
          );
        }).toList(),
      ),
    );
  }
}
