import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formats.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/data_panel.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_badge.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final txn = state.transactions
        .where((item) => item.id == transactionId)
        .firstOrNull;

    if (txn == null) {
      return FinancePage(
        title: 'Transaction not found',
        subtitle: 'The requested transaction may have been removed.',
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.go('/transactions'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ],
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No matching transaction exists.'),
            ),
          ),
        ],
      );
    }

    return FinancePage(
      title: txn.description,
      subtitle:
          '${txn.type.label} • ${txn.scope.label} • ${AppDates.short.format(txn.date)}',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/transactions'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Ledger'),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/edit/${txn.id}'),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
      ],
      children: [
        DataPanel(
          title: 'Transaction details',
          child: Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _Fact(label: 'Amount', value: Money.format(txn.amountPaise)),
              _Fact(label: 'Category', value: txn.category),
              _Fact(label: 'Payment method', value: txn.paymentMethod.label),
              _Fact(
                label: 'Account',
                value:
                    state.accounts
                        .where((a) => a.id == txn.accountId)
                        .firstOrNull
                        ?.name ??
                    'Account not found',
              ),
              _Fact(label: 'Status', value: txn.status.label),
              if (txn.dueDate != null)
                _Fact(
                  label: 'Due date',
                  value: AppDates.short.format(txn.dueDate!),
                ),
              if (txn.vendorName != null)
                _Fact(label: 'Vendor', value: txn.vendorName!),
              if (txn.invoiceNumber != null)
                _Fact(label: 'Invoice', value: txn.invoiceNumber!),
              if (txn.gstPaise != null)
                _Fact(label: 'GST', value: Money.format(txn.gstPaise!)),
              _Fact(label: 'Created by', value: txn.audit.createdBy),
            ],
          ),
        ),
        DataPanel(
          title: 'Workflow state',
          child: Row(
            children: [
              StatusBadge(status: txn.status),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.copy),
                label: const Text('Duplicate'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.attach_file),
                label: const Text('Receipt'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditTransactionScreen extends ConsumerWidget {
  const EditTransactionScreen({super.key, required this.transactionId});
  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final txn = state.transactions
        .where((item) => item.id == transactionId)
        .firstOrNull;

    return FinancePage(
      title: 'Edit transaction',
      subtitle:
          'Audit-safe editing surface with validation and soft-delete workflow.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/transactions/$transactionId'),
          icon: const Icon(Icons.close),
          label: const Text('Close'),
        ),
      ],
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (txn == null)
                  const Text('Transaction not found.')
                else ...[
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          initialValue: Money.format(txn.amountPaise),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          initialValue: txn.category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 360,
                        child: TextFormField(
                          initialValue: txn.description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusBadge(status: txn.status),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.history),
                        label: const Text('Audit history'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Soft delete'),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            context.go('/transactions/$transactionId'),
                        icon: const Icon(Icons.save),
                        label: const Text('Save changes'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
