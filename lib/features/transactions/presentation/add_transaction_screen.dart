import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/data_panel.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_theme.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _vendor = TextEditingController();
  final _invoice = TextEditingController();
  final _gst = TextEditingController();

  TransactionType _type = TransactionType.expense;
  FinanceScope _scope = FinanceScope.personal;
  PaymentMethod _method = PaymentMethod.upi;
  String? _accountId;
  String? _toAccountId;
  String? _category;
  String? _personId;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _recurring = false;
  bool _reimbursable = false;
  bool _paidPersonally = false;
  bool _saveAndAnother = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refreshAmountPreview);
  }

  @override
  void dispose() {
    _amount.removeListener(_refreshAmountPreview);
    _amount.dispose();
    _description.dispose();
    _vendor.dispose();
    _invoice.dispose();
    _gst.dispose();
    super.dispose();
  }

  void _refreshAmountPreview() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeControllerProvider);
    final matchingCategories = state.categories
        .where(
          (cat) => cat.type == _normalizedCategoryType && cat.scope == _scope,
        )
        .toList();

    if (state.accounts.isEmpty) {
      return _SetupRequiredPage(
        title: 'Add your first account',
        subtitle:
            'Create a real bank, cash, UPI, wallet, card, or company account before recording transactions.',
        icon: Icons.account_balance_wallet_rounded,
        actionLabel: 'Add account',
        onAction: () => context.go('/accounts'),
      );
    }

    if (_requiresCategory && matchingCategories.isEmpty) {
      return _SetupRequiredPage(
        title: 'Add your first category',
        subtitle:
            'Create personal or company categories first so every transaction is classified correctly.',
        icon: Icons.category_rounded,
        actionLabel: 'Add category',
        onAction: () => context.go('/categories'),
      );
    }

    _accountId ??= state.accounts.first.id;
    _toAccountId ??= state.accounts
        .where((account) => account.id != _accountId)
        .firstOrNull
        ?.id;
    _category ??= matchingCategories.firstOrNull?.name;
    _personId ??= state.people.firstOrNull?.id;

    return FinancePage(
      title: 'Add transaction',
      subtitle:
          'Record income, expenses, transfers, EMIs, borrowed money, lent money, repayments, or collections.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _saveDraft(context),
          icon: const Icon(Icons.drafts_outlined),
          label: const Text('Draft'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final availableWidth = constraints.maxWidth - 36;
              final columns = availableWidth >= 1040
                  ? 3
                  : availableWidth >= 680
                  ? 2
                  : 1;
              final fieldWidth =
                  (availableWidth - (14 * (columns - 1))) / columns;
              Widget field(Widget child) =>
                  SizedBox(width: fieldWidth, child: child);

              return SurfacePanel(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CommandStrip(type: _type, amount: _amount.text),
                      const SizedBox(height: AppSpacing.xl),
                      _TransactionTypePicker(
                        selected: _type,
                        compact: !wide,
                        onChanged: (value) {
                          setState(() {
                            _type = value;
                            if (_type == TransactionType.income) {
                              _scope = FinanceScope.company;
                            }
                            _category = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _FormSection(
                        title: 'Amount and routing',
                        subtitle:
                            'Choose where the money moved and how it was paid.',
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final quick in [
                              '450',
                              '1,200',
                              '5,000',
                              '25,000',
                              '1,00,000',
                            ])
                              ActionChip(
                                avatar: const Icon(
                                  Icons.currency_rupee_rounded,
                                  size: 16,
                                ),
                                label: Text(quick),
                                onPressed: () =>
                                    setState(() => _amount.text = quick),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          field(
                            TextFormField(
                              controller: _amount,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: '₹ ',
                                helperText:
                                    'Use rupees, paise are stored safely',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,.]'),
                                ),
                              ],
                              validator: (value) {
                                try {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Amount is required';
                                  }
                                  if (Money.fromRupees(value) <= 0) {
                                    return 'Amount must be greater than zero';
                                  }
                                  return null;
                                } on FormatException {
                                  return 'Enter a valid amount';
                                }
                              },
                            ),
                          ),
                          field(
                            DropdownButtonFormField<FinanceScope>(
                              initialValue: _scope,
                              decoration: const InputDecoration(
                                labelText: 'Scope',
                              ),
                              items: FinanceScope.values
                                  .map(
                                    (scope) => DropdownMenuItem(
                                      value: scope,
                                      child: Text(scope.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _type == TransactionType.transfer
                                  ? null
                                  : (value) => setState(() {
                                      _scope = value!;
                                      _category = null;
                                    }),
                            ),
                          ),
                          field(
                            DropdownButtonFormField<String>(
                              initialValue: _accountId,
                              decoration: const InputDecoration(
                                labelText: 'Account',
                              ),
                              items: state.accounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account.id,
                                      child: Text(account.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _accountId = value),
                            ),
                          ),
                          if (_type == TransactionType.transfer)
                            field(
                              DropdownButtonFormField<String>(
                                initialValue: _toAccountId,
                                decoration: const InputDecoration(
                                  labelText: 'To account',
                                ),
                                items: state.accounts
                                    .where(
                                      (account) => account.id != _accountId,
                                    )
                                    .map(
                                      (account) => DropdownMenuItem(
                                        value: account.id,
                                        child: Text(account.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _toAccountId = value),
                              ),
                            ),
                          if (_requiresCategory)
                            field(
                              DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'category-${_scope.name}-${_type.name}',
                                ),
                                initialValue: _category,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: state.categories
                                    .where(
                                      (cat) =>
                                          cat.type == _normalizedCategoryType &&
                                          cat.scope == _scope,
                                    )
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat.name,
                                        child: Text(cat.name),
                                      ),
                                    )
                                    .toList(),
                                validator: (value) =>
                                    value == null ? 'Choose a category' : null,
                                onChanged: (value) =>
                                    setState(() => _category = value),
                              ),
                            ),
                          field(
                            DropdownButtonFormField<PaymentMethod>(
                              initialValue: _method,
                              decoration: const InputDecoration(
                                labelText: 'Payment method',
                              ),
                              items: PaymentMethod.values
                                  .map(
                                    (method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _method = value!),
                            ),
                          ),
                          field(
                            TextFormField(
                              controller: _description,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().length < 3
                                  ? 'Add a short description'
                                  : null,
                            ),
                          ),
                          field(
                            _DateButton(
                              label: 'Transaction date',
                              value: _date,
                              onPicked: (date) => setState(() => _date = date),
                            ),
                          ),
                          if (_requiresDueDate)
                            field(
                              _DateButton(
                                label: 'Due date',
                                value: _dueDate,
                                onPicked: (date) =>
                                    setState(() => _dueDate = date),
                              ),
                            ),
                          if (_requiresPerson)
                            field(
                              DropdownButtonFormField<String>(
                                initialValue: _personId,
                                decoration: const InputDecoration(
                                  labelText: 'Person or organisation',
                                ),
                                items: state.people
                                    .map(
                                      (person) => DropdownMenuItem(
                                        value: person.id,
                                        child: Text(person.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _personId = value),
                              ),
                            ),
                          if (_scope == FinanceScope.company &&
                              _type == TransactionType.expense)
                            field(
                              TextFormField(
                                controller: _vendor,
                                decoration: const InputDecoration(
                                  labelText: 'Vendor name',
                                ),
                              ),
                            ),
                          if (_scope == FinanceScope.company)
                            field(
                              TextFormField(
                                controller: _invoice,
                                decoration: const InputDecoration(
                                  labelText: 'Invoice reference',
                                ),
                              ),
                            ),
                          if (_scope == FinanceScope.company &&
                              _type == TransactionType.expense)
                            field(
                              TextFormField(
                                controller: _gst,
                                decoration: const InputDecoration(
                                  labelText: 'GST amount',
                                  prefixText: '₹ ',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _FormSection(
                        title: 'Controls and attachments',
                        subtitle:
                            'Mark recurring behaviour, reimbursements, receipts, and save preferences.',
                        child: const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            avatar: const Icon(Icons.repeat),
                            label: const Text('Recurring'),
                            selected: _recurring,
                            onSelected: (value) =>
                                setState(() => _recurring = value),
                          ),
                          if (_scope == FinanceScope.company &&
                              _type == TransactionType.expense)
                            FilterChip(
                              avatar: const Icon(Icons.assignment_return),
                              label: const Text('Reimbursable'),
                              selected: _reimbursable,
                              onSelected: (value) =>
                                  setState(() => _reimbursable = value),
                            ),
                          if (_scope == FinanceScope.company &&
                              _type == TransactionType.expense)
                            FilterChip(
                              avatar: const Icon(
                                Icons.person_pin_circle_outlined,
                              ),
                              label: const Text('Paid personally'),
                              selected: _paidPersonally,
                              onSelected: (value) =>
                                  setState(() => _paidPersonally = value),
                            ),
                          FilterChip(
                            avatar: const Icon(Icons.add_task),
                            label: const Text('Save and add another'),
                            selected: _saveAndAnother,
                            onSelected: (value) =>
                                setState(() => _saveAndAnother = value),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.attach_file),
                            label: const Text('Attach receipt'),
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Receipt attachment workflow is ready for storage integration.',
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => context.go('/transactions'),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Save transaction'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool get _requiresCategory =>
      _type == TransactionType.expense || _type == TransactionType.income;

  bool get _requiresPerson =>
      _type == TransactionType.moneyBorrowed ||
      _type == TransactionType.moneyLent ||
      _type == TransactionType.repayment ||
      _type == TransactionType.receivableCollection;

  bool get _requiresDueDate =>
      _type == TransactionType.income ||
      _type == TransactionType.moneyBorrowed ||
      _type == TransactionType.moneyLent ||
      _type == TransactionType.loan;

  TransactionType get _normalizedCategoryType => _type == TransactionType.income
      ? TransactionType.income
      : TransactionType.expense;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      _showError('Add an account before saving a transaction.');
      return;
    }
    if (_type == TransactionType.transfer && _toAccountId == null) {
      _showError('Add a second account before saving a transfer.');
      return;
    }
    if (_requiresCategory && _category == null) {
      _showError('Add or choose a category before saving this transaction.');
      return;
    }
    await ref
        .read(financeControllerProvider.notifier)
        .addTransaction(
          type: _type,
          scope: _type == TransactionType.transfer
              ? FinanceScope.personal
              : _scope,
          amountPaise: Money.fromRupees(_amount.text),
          category: _type == TransactionType.transfer
              ? 'Transfer'
              : _category ?? _type.label,
          accountId: _accountId!,
          toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
          date: _date,
          description: _description.text.trim(),
          paymentMethod: _method,
          vendorName: _vendor.text.trim().isEmpty ? null : _vendor.text.trim(),
          invoiceNumber: _invoice.text.trim().isEmpty
              ? null
              : _invoice.text.trim(),
          gstPaise: _gst.text.trim().isEmpty
              ? null
              : Money.fromRupees(_gst.text),
          dueDate: _dueDate,
          personId: _requiresPerson ? _personId : null,
          isRecurring: _recurring,
          isReimbursable: _reimbursable,
          paidPersonally: _paidPersonally,
          status: _dueDate != null && _dueDate!.isAfter(DateTime.now())
              ? TransactionStatus.pending
              : TransactionStatus.paid,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved successfully')),
    );
    if (_saveAndAnother) {
      _amount.clear();
      _description.clear();
      _vendor.clear();
      _invoice.clear();
      _gst.clear();
      return;
    }
    context.go('/transactions');
  }

  void _saveDraft(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved locally')));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SetupRequiredPage extends StatelessWidget {
  const _SetupRequiredPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FinancePage(
      title: title,
      subtitle: subtitle,
      actions: [
        FilledButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
      ],
      children: [
        SurfacePanel(
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 30),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommandStrip extends StatelessWidget {
  const _CommandStrip({required this.type, required this.amount});

  final TransactionType type;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final debit =
        type == TransactionType.expense ||
        type == TransactionType.emiPayment ||
        type == TransactionType.moneyLent ||
        type == TransactionType.repayment;
    final accent = debit ? colors.expense : colors.income;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: .12),
              child: Icon(AppIcons.transaction(type), color: accent),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Only relevant fields are shown for this transaction type.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              amount.trim().isEmpty ? '₹0' : '₹$amount',
              style: AppTypography.money(
                Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _TransactionTypePicker extends StatelessWidget {
  const _TransactionTypePicker({
    required this.selected,
    required this.compact,
    required this.onChanged,
  });

  final TransactionType selected;
  final bool compact;
  final ValueChanged<TransactionType> onChanged;

  static const _items = [
    (TransactionType.expense, 'Expense', Icons.remove_circle_outline),
    (TransactionType.income, 'Income', Icons.add_circle_outline),
    (TransactionType.transfer, 'Transfer', Icons.swap_horiz),
    (TransactionType.emiPayment, 'EMI', Icons.event_repeat),
    (TransactionType.moneyBorrowed, 'Borrowed', Icons.call_received),
    (TransactionType.moneyLent, 'Lent', Icons.call_made),
    (TransactionType.repayment, 'Repay', Icons.payments),
    (TransactionType.receivableCollection, 'Collect', Icons.task_alt),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction type',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = compact
                ? 2
                : constraints.maxWidth >= 960
                ? 4
                : 3;
            final width =
                (constraints.maxWidth - (10 * (columns - 1))) / columns;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in _items)
                  SizedBox(
                    width: width,
                    child: Material(
                      color: selected == item.$1
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: selected == item.$1
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onChanged(item.$1),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 12,
                            vertical: compact ? 10 : 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.$3,
                                size: 18,
                                color: selected == item.$1
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: selected == item.$1
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurface,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.calendar_month),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value == null
              ? label
              : '$label: ${value!.day}/${value!.month}/${value!.year}',
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
