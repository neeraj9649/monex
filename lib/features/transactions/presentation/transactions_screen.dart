import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formats.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/finance_models.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/data_panel.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_theme.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _query = '';
  FinanceScope? _scope;
  TransactionType? _type;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeControllerProvider);
    final filtered = state.transactions.where((txn) {
      final text =
          '${txn.description} ${txn.category} ${txn.invoiceNumber ?? ''} ${txn.vendorName ?? ''}'
              .toLowerCase();
      return (_query.isEmpty || text.contains(_query.toLowerCase())) &&
          (_scope == null || txn.scope == _scope) &&
          (_type == null || txn.type == _type);
    }).toList();

    return FinancePage(
      title: 'All transactions',
      subtitle:
          'Searchable ledger with personal, company, income, expense, transfer, due-date, and attachment filters.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
      children: [
        DataPanel(
          title: 'Ledger filters',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search transactions',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<FinanceScope?>(
                  initialValue: _scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All scopes'),
                    ),
                    ...FinanceScope.values.map(
                      (scope) => DropdownMenuItem(
                        value: scope,
                        child: Text(scope.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _scope = value),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<TransactionType?>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All types'),
                    ),
                    ...TransactionType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (filtered.isEmpty) {
              return const _EmptyLedger();
            }
            return constraints.maxWidth >= 860
                ? _DesktopLedger(transactions: filtered)
                : _MobileLedger(transactions: filtered);
          },
        ),
      ],
    );
  }
}

class _MobileLedger extends StatelessWidget {
  const _MobileLedger({required this.transactions});

  final List<FinanceTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      title: 'Transactions',
      child: Column(
        children: [
          for (final txn in transactions)
            _LedgerListRow(
              transaction: txn,
              onTap: () => context.go('/transactions/${txn.id}'),
            ),
        ],
      ),
    );
  }
}

class _DesktopLedger extends StatelessWidget {
  const _DesktopLedger({required this.transactions});

  final List<FinanceTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      title: 'Professional ledger',
      trailing: Text(
        '${transactions.length} records',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 940),
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('Transaction')),
              DataColumn(label: Text('Scope')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Amount'), numeric: true),
            ],
            rows: [
              for (final txn in transactions)
                DataRow(
                  onSelectChanged: (_) => context.go('/transactions/${txn.id}'),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          _LedgerIcon(transaction: txn),
                          const SizedBox(width: AppSpacing.md),
                          SizedBox(
                            width: 320,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  txn.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(txn.scope.label)),
                    DataCell(Text(txn.type.label)),
                    DataCell(Text(AppDates.short.format(txn.date))),
                    DataCell(StatusBadge(status: txn.status)),
                    DataCell(_AmountText(transaction: txn)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerListRow extends StatelessWidget {
  const _LedgerListRow({required this.transaction, required this.onTap});

  final FinanceTransaction transaction;
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
            leading: _LedgerIcon(transaction: transaction),
            title: Text(
              transaction.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${transaction.category} • ${transaction.scope.label} • ${AppDates.short.format(transaction.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AmountText(transaction: transaction),
                const SizedBox(height: 4),
                StatusBadge(status: transaction.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerIcon extends StatelessWidget {
  const _LedgerIcon({required this.transaction});

  final FinanceTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final accent = _isDebit(transaction) ? colors.expense : colors.income;
    return CircleAvatar(
      backgroundColor: accent.withValues(alpha: .12),
      child: Icon(
        AppIcons.transaction(transaction.type),
        color: accent,
        size: 20,
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({required this.transaction});

  final FinanceTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final debit = _isDebit(transaction);
    return Text(
      debit
          ? '-${Money.format(transaction.amountPaise)}'
          : Money.format(transaction.amountPaise),
      style: AppTypography.money(
        Theme.of(context).textTheme.titleSmall?.copyWith(
          color: debit ? colors.expense : colors.income,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SurfacePanel(
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: scheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matching transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Clear filters or add a new transaction to start building the ledger.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

bool _isDebit(FinanceTransaction txn) =>
    txn.type == TransactionType.expense ||
    txn.type == TransactionType.emiPayment ||
    txn.type == TransactionType.moneyLent ||
    txn.type == TransactionType.repayment;
