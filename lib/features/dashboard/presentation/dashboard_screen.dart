import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formats.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/data_panel.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/summary_card.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final metrics = ref.watch(dashboardMetricsProvider);
    final colors = Theme.of(context).extension<FinanceColors>()!;

    return FinancePage(
      title: 'Financial command center',
      subtitle:
          'Live founder view across personal cash, company spend, loans, EMIs, receivables, and payables.',
      actions: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'month', label: Text('Month')),
            ButtonSegment(value: 'fy', label: Text('FY')),
            ButtonSegment(value: 'all', label: Text('All')),
          ],
          selected: const {'month'},
          onSelectionChanged: (_) {},
        ),
        FilledButton.icon(
          onPressed: () => context.go('/add'),
          icon: const Icon(Icons.add),
          label: const Text('Transaction'),
        ),
      ],
      children: [
        _FinancialPositionHero(metrics: metrics),
        ResponsiveGrid(
          minItemWidth: 260,
          childAspectRatio: 1.62,
          children: [
            SummaryCard(
              label: 'Total income',
              value: Money.format(metrics.totalIncomePaise, compact: true),
              icon: Icons.trending_up_rounded,
              color: colors.income,
              detail: 'Received and expected income included',
            ),
            SummaryCard(
              label: 'Net cash flow',
              value: Money.signed(metrics.netCashFlowPaise),
              icon: Icons.sync_alt_rounded,
              color: metrics.netCashFlowPaise >= 0
                  ? colors.income
                  : colors.expense,
              detail: 'Income less personal and company expenses',
            ),
            SummaryCard(
              label: 'Overdue items',
              value: '${metrics.overdueCount}',
              icon: Icons.warning_amber_rounded,
              color: colors.warning,
              detail: 'EMIs, receivables, and repayments needing attention',
            ),
            SummaryCard(
              label: 'Outstanding loans',
              value: Money.format(metrics.outstandingLoansPaise, compact: true),
              icon: Icons.account_balance_rounded,
              color: colors.info,
              detail: 'Principal still open across active loans',
            ),
          ],
        ),
        DataPanel(
          title: 'Setup and master data',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 560
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _SetupAction(
                      icon: Icons.account_balance,
                      title: 'Add account',
                      subtitle: 'Bank, UPI, wallet, card',
                      onTap: () => context.go('/accounts'),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _SetupAction(
                      icon: Icons.category,
                      title: 'Manage categories',
                      subtitle: 'Expense and income masters',
                      onTap: () => context.go('/categories'),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _SetupAction(
                      icon: Icons.payments,
                      title: 'Add active loan',
                      subtitle: 'Principal, EMI, schedule',
                      onTap: () => context.go('/loans/add'),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _SetupAction(
                      icon: Icons.sms_outlined,
                      title: 'Bank imports',
                      subtitle: 'Paste and review drafts',
                      onTap: () => context.go('/sms-imports'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final panels = [
              Expanded(child: _CashFlowChart(metrics: metrics)),
              Expanded(child: _CategoryChart()),
            ];
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [panels[0], const SizedBox(width: 18), panels[1]],
                  )
                : Column(
                    children: [
                      panels[0],
                      const SizedBox(height: 18),
                      panels[1],
                    ],
                  );
          },
        ),
        ResponsiveGrid(
          minItemWidth: 300,
          children: [
            SummaryCard(
              label: 'Personal expenses',
              value: Money.format(metrics.personalExpensesPaise, compact: true),
              icon: Icons.person_rounded,
              color: colors.expense,
              detail: 'Rent, food, medical, education, investments, and more',
            ),
            SummaryCard(
              label: 'Company expenses',
              value: Money.format(metrics.companyExpensesPaise, compact: true),
              icon: Icons.business_center_rounded,
              color: colors.expense,
              detail:
                  'Payroll, GST invoices, vendors, subscriptions, compliance',
            ),
            SummaryCard(
              label: 'Amount I owe',
              value: Money.format(metrics.owePaise, compact: true),
              icon: Icons.call_made_rounded,
              color: colors.warning,
              detail: 'Tracked with partial repayment history',
            ),
            SummaryCard(
              label: 'Owed to me',
              value: Money.format(metrics.owedToMePaise, compact: true),
              icon: Icons.call_received_rounded,
              color: colors.info,
              detail: 'Expected receivables and follow-up reminders',
            ),
          ],
        ),
        DataPanel(
          title: 'Upcoming and overdue reminders',
          trailing: TextButton.icon(
            onPressed: () => context.go('/reminders'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('View all'),
          ),
          child: Column(
            children: state.reminders
                .map(
                  (item) => _ReminderRow(
                    title: item.title,
                    date: AppDates.short.format(item.dueAt),
                    amount: Money.format(item.amountPaise),
                    status: item.status,
                  ),
                )
                .toList(),
          ),
        ),
        DataPanel(
          title: 'Recent transactions',
          trailing: TextButton.icon(
            onPressed: () => context.go('/transactions'),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Open ledger'),
          ),
          child: Column(
            children: state.transactions.take(6).map((txn) {
              final signed =
                  txn.type == TransactionType.expense ||
                  txn.type == TransactionType.emiPayment ||
                  txn.type == TransactionType.moneyLent;
              return _TransactionRow(
                icon: AppIcons.transaction(txn.type),
                accent: signed ? colors.expense : colors.income,
                title: txn.description,
                subtitle:
                    '${txn.category} • ${txn.scope.label} • ${AppDates.short.format(txn.date)}',
                amount: signed
                    ? '-${Money.format(txn.amountPaise)}'
                    : Money.format(txn.amountPaise),
                onTap: () => context.go('/transactions/${txn.id}'),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FinancialPositionHero extends StatelessWidget {
  const _FinancialPositionHero({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final positive = metrics.netCashFlowPaise >= 0;

    return SurfacePanel(
      accent: scheme.primary,
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 860;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total financial position',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                Money.format(metrics.totalBalancePaise, compact: true),
                style: AppTypography.money(
                  Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _FinanceSignal(
                    icon: positive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    label: positive ? 'Cash flow positive' : 'Cash flow tight',
                    color: positive ? colors.income : colors.expense,
                  ),
                  _FinanceSignal(
                    icon: Icons.event_available_rounded,
                    label: 'Upcoming EMI reminders',
                    color: colors.warning,
                  ),
                ],
              ),
            ],
          );

          final details = Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _HeroFact(
                label: 'Personal spend',
                value: Money.format(
                  metrics.personalExpensesPaise,
                  compact: true,
                ),
              ),
              _HeroFact(
                label: 'Company spend',
                value: Money.format(
                  metrics.companyExpensesPaise,
                  compact: true,
                ),
              ),
              _HeroFact(
                label: 'Receivable',
                value: Money.format(metrics.owedToMePaise, compact: true),
              ),
              _HeroFact(
                label: 'Payable',
                value: Money.format(metrics.owePaise, compact: true),
              ),
            ],
          );

          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: summary),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(flex: 4, child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summary,
                    const SizedBox(height: AppSpacing.x2),
                    details,
                  ],
                );
        },
      ),
    );
  }
}

class _FinanceSignal extends StatelessWidget {
  const _FinanceSignal({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 170,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: AppTypography.money(
                  Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupAction extends StatelessWidget {
  const _SetupAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String title;
  final String date;
  final String amount;
  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = status == TransactionStatus.overdue;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ListTile(
          leading: Icon(
            overdue
                ? Icons.error_outline_rounded
                : Icons.event_available_rounded,
            color: overdue ? scheme.error : scheme.primary,
          ),
          title: Text(title),
          subtitle: Text(date),
          trailing: Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                amount,
                style: AppTypography.money(
                  Theme.of(context).textTheme.titleSmall,
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: .12),
              child: Icon(icon, color: accent, size: 20),
            ),
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              amount,
              style: AppTypography.money(
                Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  const _CashFlowChart({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    return DataPanel(
      title: 'Income versus expense',
      child: SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final labels = ['Income', 'Personal', 'Company'];
                    return Text(
                      labels[value.toInt().clamp(0, labels.length - 1)],
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              _bar(0, metrics.totalIncomePaise, colors.income),
              _bar(1, metrics.personalExpensesPaise, colors.expense),
              _bar(2, metrics.companyExpensesPaise, colors.warning),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, int paise, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (paise / 100000).clamp(1, 700).toDouble(),
          width: 38,
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

class _CategoryChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).extension<FinanceColors>()!.warning,
      Theme.of(context).extension<FinanceColors>()!.expense,
    ];
    final grouped = <String, int>{};
    for (final txn in state.transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      grouped.update(
        txn.category,
        (value) => value + txn.amountPaise,
        ifAbsent: () => txn.amountPaise,
      );
    }
    final entries = grouped.entries.toList();
    return DataPanel(
      title: 'Category-wise spending',
      child: SizedBox(
        height: 260,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 44,
            sections: [
              for (var i = 0; i < entries.length; i++)
                PieChartSectionData(
                  value: entries[i].value / 100,
                  title: entries[i].key.split(' ').first,
                  radius: 82,
                  color: colors[i % colors.length],
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
