import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/imports/bank_sms_parser.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/imported_bank_message.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/sms_import_providers.dart';
import '../../../shared/widgets/data_panel.dart';
import '../../../shared/widgets/page_scaffold.dart';

class SmsImportsScreen extends ConsumerStatefulWidget {
  const SmsImportsScreen({super.key});

  @override
  ConsumerState<SmsImportsScreen> createState() => _SmsImportsScreenState();
}

class _SmsImportsScreenState extends ConsumerState<SmsImportsScreen> {
  final _manualMessage = TextEditingController();
  List<ImportedBankMessage> _manualDrafts = const [];
  String? _shownMessage;

  @override
  void dispose() {
    _manualMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(smsImportControllerProvider);
    final controller = ref.read(smsImportControllerProvider.notifier);
    final supported = controller.isSupported;

    // Surface controller messages once each, without a listener rebuild loop.
    final message = importState.message;
    if (message != null && message != _shownMessage) {
      _shownMessage = message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      });
    }

    final drafts = [...importState.drafts, ..._manualDrafts];

    return FinancePage(
      title: 'Bank message imports',
      subtitle: supported
          ? 'MONEX reads bank SMS on this device, detects credit/debit, amount, '
                'bank and account, then queues each one for your approval.'
          : 'Paste bank SMS text here. Automatic capture runs on Android only.',
      actions: [
        if (supported)
          FilledButton.icon(
            onPressed: importState.isScanning
                ? null
                : () => controller.scanInbox(),
            icon: importState.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(importState.isScanning ? 'Scanning' : 'Scan inbox'),
          ),
      ],
      children: [
        if (supported) _AutoCapturePanel(state: importState),
        DataPanel(
          title: 'Paste a message',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _manualMessage,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bank SMS text',
                  hintText:
                      'Example: IDBI Bank Acct XX330 debited for Rs 2000.00 '
                      'on 31-Jul-26; Bal Rs 18239.89',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _parseManualMessage,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Parse pasted message'),
              ),
            ],
          ),
        ),
        DataPanel(
          title: 'Waiting for approval (${drafts.length})',
          child: drafts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No pending bank messages. Detected transactions appear '
                    'here for review before anything is written to the ledger.',
                  ),
                )
              : Column(
                  children: [
                    for (final draft in drafts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SmsDraftCard(
                          key: ValueKey(draft.id),
                          message: draft,
                          onResolved: () => setState(() {
                            _manualDrafts = _manualDrafts
                                .where((item) => item.id != draft.id)
                                .toList();
                          }),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _parseManualMessage() {
    final parsed = BankSmsParser.parse(
      sender: 'Manual',
      body: _manualMessage.text,
      date: DateTime.now(),
    );
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not detect a bank transaction in this message.'),
        ),
      );
      return;
    }
    setState(() => _manualDrafts = [parsed, ..._manualDrafts]);
    _manualMessage.clear();
  }
}

class _AutoCapturePanel extends ConsumerWidget {
  const _AutoCapturePanel({required this.state});

  final SmsImportState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(smsImportControllerProvider.notifier);
    final lastScan = state.lastScanAt;

    return DataPanel(
      title: 'Automatic capture',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state.autoCaptureEnabled,
            onChanged: (value) => controller.setAutoCapture(value),
            title: const Text('Read bank SMS on this device'),
            subtitle: const Text(
              'New bank messages are detected in the background and queued '
              'below. Nothing is added to the ledger until you approve it.',
            ),
          ),
          if (state.autoCaptureEnabled && !state.permissionGranted)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.warning_amber_rounded),
              title: Text('SMS permission is not granted'),
              subtitle: Text(
                'Open Android app settings and allow SMS for MONEX.',
              ),
            ),
          if (lastScan != null)
            Text(
              'Last inbox scan: ${_formatTimestamp(lastScan)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _SmsDraftCard extends ConsumerStatefulWidget {
  const _SmsDraftCard({required this.message, required this.onResolved, super.key});

  final ImportedBankMessage message;
  final VoidCallback onResolved;

  @override
  ConsumerState<_SmsDraftCard> createState() => _SmsDraftCardState();
}

class _SmsDraftCardState extends ConsumerState<_SmsDraftCard> {
  late final TextEditingController _description;
  String? _category;
  String? _accountId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final message = widget.message;
    _description = TextEditingController(
      text: message.merchant?.isNotEmpty == true
          ? message.merchant!
          : '${message.bankName} ${message.isCredit ? 'credit' : 'debit'}',
    );
    // Preselect whatever the matcher resolved from the account number.
    _accountId = message.matchedAccountId;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeControllerProvider);
    final message = widget.message;
    final categories = state.categories
        .where(
          (category) =>
              category.type == message.transactionType &&
              category.scope == FinanceScope.personal,
        )
        .toList();

    _category ??= categories.isNotEmpty ? categories.first.name : null;
    // Only fall back to the first account when nothing was matched.
    if (_accountId != null &&
        !state.accounts.any((account) => account.id == _accountId)) {
      _accountId = null;
    }
    _accountId ??= state.accounts.isNotEmpty ? state.accounts.first.id : null;

    final theme = Theme.of(context);
    final matched = message.matchedAccountId != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Fact('Amount', Money.format(message.amountPaise)),
                _Fact('Type', message.isCredit ? 'Credit' : 'Debit'),
                _Fact('Bank', message.bankName),
                _Fact('Account', message.accountHint),
                if (message.balancePaise != null)
                  _Fact('Balance', Money.format(message.balancePaise!)),
                if (message.merchant != null) _Fact('Party', message.merchant!),
                if (message.referenceId != null)
                  _Fact('Reference', message.referenceId!),
                _Fact('Confidence', '${(message.confidence * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 12),
            if (!matched && state.accounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No account matched "${message.accountHint}". Set the account '
                  'number on your accounts so this matches automatically.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.name,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<String>(
                    initialValue: _accountId,
                    decoration: InputDecoration(
                      labelText: 'Account',
                      helperText: matched ? 'Matched from SMS' : null,
                    ),
                    items: state.accounts
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _accountId = value),
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton.icon(
                  onPressed: _submitting ? null : _dismiss,
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                ),
                FilledButton.icon(
                  onPressed: _category == null || _accountId == null || _submitting
                      ? null
                      : _approve,
                  icon: const Icon(Icons.check),
                  label: const Text('Add to ledger'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve() async {
    setState(() => _submitting = true);
    await ref
        .read(smsImportControllerProvider.notifier)
        .approve(
          message: widget.message,
          category: _category!,
          accountId: _accountId!,
          description: _description.text.trim(),
        );
    if (!mounted) return;
    widget.onResolved();
  }

  Future<void> _dismiss() async {
    setState(() => _submitting = true);
    await ref
        .read(smsImportControllerProvider.notifier)
        .dismiss(widget.message);
    if (!mounted) return;
    widget.onResolved();
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
