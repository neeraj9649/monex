import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../models/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TransactionStatus.paid ||
      TransactionStatus.settled => const Color(0xFF059669),
      TransactionStatus.pending ||
      TransactionStatus.partial => const Color(0xFFD97706),
      TransactionStatus.overdue => const Color(0xFFDC2626),
      TransactionStatus.draft => const Color(0xFF64748B),
    };

    final icon = switch (status) {
      TransactionStatus.paid || TransactionStatus.settled => Icons.check_circle,
      TransactionStatus.pending || TransactionStatus.partial => Icons.schedule,
      TransactionStatus.overdue => Icons.error,
      TransactionStatus.draft => Icons.edit_note,
    };

    return Semantics(
      label: 'Status ${status.label}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
