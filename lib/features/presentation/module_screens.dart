import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../core/calculations/emi_calculator.dart';
import '../../core/utils/date_formats.dart';
import '../../core/utils/money.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/finance_models.dart';
import '../../shared/providers/app_lock_providers.dart';
import '../../shared/providers/finance_providers.dart';
import '../../shared/providers/sms_import_providers.dart';
import '../../shared/widgets/data_panel.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/summary_card.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final nextRoute = session.when<String?>(
      data: (isAuthenticated) => isAuthenticated ? '/dashboard' : '/login',
      error: (_, _) => '/login',
      loading: () => null,
    );
    if (nextRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(nextRoute);
      });
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'MONEX',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Sign in to MONEX',
      subtitle:
          'Manage personal money, company cash flow, loans, accounts, and reports from one secure workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isSubmitting ? null : _login,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => context.go('/register'),
            child: const Text('Create new account'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(email: _email.text.trim(), password: _password.text);
      if (mounted) context.go('/dashboard');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyApiError(
                error,
                fallback: 'Login failed. Check your credentials.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _company.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Create your finance workspace',
      subtitle:
          'Register with email and password. Your workspace starts with accounts, categories, loans, and hosted backend support.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _company,
            decoration: const InputDecoration(labelText: 'Company name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _register,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create account'),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_name.text.trim().length < 2 ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8 ||
        _password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid details. Passwords must match and use at least 8 characters.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            companyName: _company.text.trim(),
          );
      if (mounted) context.go('/dashboard');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyApiError(
                error,
                fallback: 'Registration failed. Try another email.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _isSubmitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Reset your password',
      subtitle:
          'Enter your account email. If it exists, the backend will send a secure reset link.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _requestReset,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send reset link'),
          ),
          const SizedBox(height: 12),
          if (_sent)
            const Text(
              'If this email exists, reset instructions have been sent.',
            ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReset() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(apiAuthStoreProvider)
          .requestPasswordReset(email: _email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyApiError(
                error,
                fallback: 'Could not send reset instructions.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Set a new password',
      subtitle: 'Choose a strong password to restore access to your workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _reset,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update password'),
          ),
        ],
      ),
    );
  }

  Future<void> _reset() async {
    if (_password.text.length < 8 || _password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords must match and use at least 8 characters.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(apiAuthStoreProvider)
          .resetPassword(token: widget.token, password: _password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated. Sign in again.')),
        );
        context.go('/login');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyApiError(
                error,
                fallback: 'Reset link is invalid or expired.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
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
    return Scaffold(
      body: Container(
        color: scheme.surface,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 760;
                    final brandPanel = _AuthBrandPanel(wide: wide);
                    final formPanel = _AuthFormPanel(
                      title: title,
                      subtitle: subtitle,
                      child: child,
                    );
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: brandPanel),
                              const SizedBox(width: 18),
                              SizedBox(width: 430, child: formPanel),
                            ],
                          )
                        : Column(
                            children: [
                              brandPanel,
                              const SizedBox(height: 14),
                              formPanel,
                            ],
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: wide ? 560 : 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            bottom: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 28),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'FF',
                        style: TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MONEX',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A serious money desk for founders.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Track income, expenses, loans, EMIs, accounts, payables, receivables, and reports with production-ready auth and hosting.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: .86),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _AuthPill(label: 'Personal + company'),
                    _AuthPill(label: 'Loans & EMIs'),
                    _AuthPill(label: 'Reports'),
                    _AuthPill(label: 'Hostinger backend'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}

class _AuthPill extends StatelessWidget {
  const _AuthPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FinancePage(
      title: 'Set up your finance workspace',
      subtitle:
          'Separate founder, family, company, accounts, GST, loans, and people-ledger tracking from day one.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Open dashboard'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 280,
          children: const [
            SummaryCard(
              label: 'Personal + company separation',
              value: 'Ready',
              icon: Icons.account_tree,
            ),
            SummaryCard(
              label: 'Indian financial year',
              value: 'Apr-Mar',
              icon: Icons.calendar_month,
            ),
            SummaryCard(
              label: 'UPI, GST, EMIs',
              value: 'Enabled',
              icon: Icons.currency_rupee,
            ),
            SummaryCard(
              label: 'Clean workspace',
              value: 'Ready',
              icon: Icons.storage,
            ),
          ],
        ),
      ],
    );
  }
}

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    return FinancePage(
      title: 'Accounts and payment methods',
      subtitle:
          'Cash, bank, cards, UPI, wallets, company current accounts, investments, and transfers.',
      actions: [
        FilledButton.icon(
          onPressed: () => _showAddAccountDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add account'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 280,
          children: state.accounts
              .map(
                (account) => SummaryCard(
                  label: '${account.type.label} • ${account.scope.label}',
                  value: Money.format(account.balancePaise, compact: true),
                  icon: account.type == AccountType.creditCard
                      ? Icons.credit_card
                      : Icons.account_balance,
                  detail:
                      '${account.name}${account.outstandingPaise > 0 ? ' • outstanding ${Money.format(account.outstandingPaise)}' : ''}',
                ),
              )
              .toList(),
        ),
        DataPanel(
          title: 'Account-wise transactions',
          child: Column(
            children: state.accounts
                .map(
                  (account) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    subtitle: Text(
                      '${account.institution ?? 'Custom'} • ${account.scope.label}',
                    ),
                    trailing: Text(
                      Money.format(account.balancePaise),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () => context.go('/accounts/${account.id}'),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = TextEditingController();
    final institution = TextEditingController();
    final accountNumber = TextEditingController();
    final balance = TextEditingController(text: '0');
    AccountType type = AccountType.bank;
    FinanceScope scope = FinanceScope.personal;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add account or payment method'),
          content: _DialogScrollContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Account name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: institution,
                  decoration: const InputDecoration(
                    labelText: 'Bank, wallet, or issuer',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountNumber,
                  decoration: const InputDecoration(
                    labelText: 'Account or card number in SMS',
                    hintText: 'Example: XX330',
                    helperText:
                        'Used to match incoming bank SMS to this account.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: AccountType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => type = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FinanceScope>(
                  initialValue: scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: FinanceScope.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => scope = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balance,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening balance',
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await ref
                    .read(financeControllerProvider.notifier)
                    .addAccount(
                      name: name.text.trim(),
                      type: type,
                      scope: scope,
                      balancePaise: Money.fromRupees(balance.text),
                      institution: institution.text.trim().isEmpty
                          ? null
                          : institution.text.trim(),
                      accountNumber: accountNumber.text.trim().isEmpty
                          ? null
                          : accountNumber.text.trim(),
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save account'),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final matches = state.accounts.where((item) => item.id == accountId);
    if (matches.isEmpty) {
      return FinancePage(
        title: 'Account not found',
        subtitle: 'Create your real account or payment method to continue.',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/accounts'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add account'),
          ),
        ],
        children: const [
          SurfacePanel(child: Text('No matching account exists.')),
        ],
      );
    }
    final account = matches.first;
    final txns = state.transactions.where(
      (txn) => txn.accountId == account.id || txn.toAccountId == account.id,
    );
    return FinancePage(
      title: account.name,
      subtitle:
          '${account.type.label} • ${account.scope.label} • transfers excluded from income and expense metrics.',
      children: [
        ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'Current balance',
              value: Money.format(account.balancePaise),
              icon: Icons.account_balance_wallet,
            ),
            SummaryCard(
              label: 'Available balance',
              value: Money.format(
                account.availableBalancePaise ?? account.balancePaise,
              ),
              icon: Icons.verified,
            ),
            SummaryCard(
              label: 'Credit limit',
              value: Money.format(account.creditLimitPaise ?? 0),
              icon: Icons.credit_score,
            ),
            SummaryCard(
              label: 'Outstanding',
              value: Money.format(account.outstandingPaise),
              icon: Icons.warning_amber,
            ),
          ],
        ),
        DataPanel(
          title: 'Recent activity',
          child: Column(
            children: txns
                .map(
                  (txn) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(txn.description),
                    subtitle: Text(
                      '${txn.type.label} • ${AppDates.short.format(txn.date)}',
                    ),
                    trailing: Text(Money.format(txn.amountPaise)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    return FinancePage(
      title: 'Categories',
      subtitle:
          'Create and manage personal expense, company expense, and income categories used across manual and bank-message imports.',
      actions: [
        FilledButton.icon(
          onPressed: () => _showAddCategoryDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add category'),
        ),
      ],
      children: [
        DataPanel(
          title: 'Category library',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: state.categories
                .map(
                  (category) => Chip(
                    avatar: Icon(
                      category.type == TransactionType.income
                          ? Icons.trending_up
                          : category.scope == FinanceScope.company
                          ? Icons.business_center
                          : Icons.person,
                      size: 18,
                    ),
                    label: Text('${category.name} • ${category.scope.label}'),
                  ),
                )
                .toList(),
          ),
        ),
        DataPanel(
          title: 'How categories are used',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.sms_outlined),
                title: Text('Bank-message imports'),
                subtitle: Text(
                  'Imported bank messages are saved as editable drafts where you can assign category, description, account, and receipt.',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.rule),
                title: Text('Future automation rules'),
                subtitle: Text(
                  'The category model is ready for merchant rules, bank rules, and recurring transaction defaults.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = TextEditingController();
    final subcategories = TextEditingController();
    FinanceScope scope = FinanceScope.personal;
    TransactionType type = TransactionType.expense;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add category'),
          content: _DialogScrollContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Category name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TransactionType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Category type'),
                  items: const [
                    DropdownMenuItem(
                      value: TransactionType.expense,
                      child: Text('Expense'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.income,
                      child: Text('Income'),
                    ),
                  ],
                  onChanged: (value) => setState(() => type = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FinanceScope>(
                  initialValue: scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: FinanceScope.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => scope = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subcategories,
                  decoration: const InputDecoration(
                    labelText: 'Subcategories',
                    hintText: 'Comma separated',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await ref
                    .read(financeControllerProvider.notifier)
                    .addCategory(
                      name: name.text.trim(),
                      scope: scope,
                      type: type,
                      subcategories: subcategories.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(),
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save category'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final outstanding = state.loans.fold<int>(
      0,
      (sum, loan) => sum + loan.remainingPrincipalEstimatePaise,
    );
    return FinancePage(
      title: 'Loans and EMIs',
      subtitle:
          'Loan progress, upcoming EMIs, principal-interest breakup, foreclosure estimates, and repayment history.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/loans/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add active loan'),
        ),
      ],
      children: [
        ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'Outstanding principal',
              value: Money.format(outstanding, compact: true),
              icon: Icons.payments,
            ),
            SummaryCard(
              label: 'Active loans',
              value: '${state.loans.length}',
              icon: Icons.list_alt,
            ),
            SummaryCard(
              label: 'Next EMI',
              value: Money.format(
                state.loans.isEmpty ? 0 : state.loans.first.emiPaise,
              ),
              icon: Icons.event_available,
            ),
            SummaryCard(
              label: 'Interest exposure',
              value: Money.format(
                state.loans.fold<int>(0, (s, l) => s + l.totalInterestPaise),
                compact: true,
              ),
              icon: Icons.percent,
            ),
          ],
        ),
        if (state.loans.isEmpty)
          const SurfacePanel(
            child: Text(
              'No active loans yet. Add your current loan with principal, rate, tenure, EMI, and paid count.',
            ),
          ),
        ...state.loans.map(
          (loan) => DataPanel(
            title: loan.name,
            trailing: TextButton.icon(
              onPressed: () => context.go('/loans/${loan.id}'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Schedule'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: loan.completion.clamp(0, 1)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 22,
                  runSpacing: 10,
                  children: [
                    _Fact('Lender', loan.lenderName),
                    _Fact('EMI', Money.format(loan.emiPaise)),
                    _Fact('Paid', '${loan.paidEmiCount}/${loan.tenureMonths}'),
                    _Fact(
                      'Remaining',
                      Money.format(loan.remainingPrincipalEstimatePaise),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AddLoanScreen extends ConsumerStatefulWidget {
  const AddLoanScreen({super.key});

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _name = TextEditingController();
  final _lender = TextEditingController();
  final _principal = TextEditingController();
  final _interest = TextEditingController();
  final _tenure = TextEditingController();
  final _emi = TextEditingController();
  final _paid = TextEditingController(text: '0');
  final _notes = TextEditingController();
  LoanType _type = LoanType.personal;
  DateTime _startDate = DateTime.now();
  int _dueDay = DateTime.now().day;

  @override
  void dispose() {
    _name.dispose();
    _lender.dispose();
    _principal.dispose();
    _interest.dispose();
    _tenure.dispose();
    _emi.dispose();
    _paid.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FinancePage(
      title: 'Add active loan',
      subtitle:
          'Enter your current loan details. EMI can be auto-calculated from principal, interest rate, and tenure.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/loans'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Loans'),
        ),
      ],
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 820 ? 2 : 1;
                final width =
                    (constraints.maxWidth - (14 * (columns - 1))) / columns;
                Widget field(Widget child) =>
                    SizedBox(width: width, child: child);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        field(
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Loan name',
                            ),
                          ),
                        ),
                        field(
                          TextField(
                            controller: _lender,
                            decoration: const InputDecoration(
                              labelText: 'Lender name',
                            ),
                          ),
                        ),
                        field(
                          DropdownButtonFormField<LoanType>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Loan type',
                            ),
                            items: LoanType.values
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _type = value!),
                          ),
                        ),
                        field(
                          TextField(
                            controller: _principal,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Principal amount',
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        field(
                          TextField(
                            controller: _interest,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Annual interest rate',
                              suffixText: '%',
                            ),
                          ),
                        ),
                        field(
                          TextField(
                            controller: _tenure,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tenure in months',
                            ),
                          ),
                        ),
                        field(
                          TextField(
                            controller: _emi,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'EMI amount',
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        field(
                          TextField(
                            controller: _paid,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Paid EMI count',
                            ),
                          ),
                        ),
                        field(
                          OutlinedButton.icon(
                            onPressed: _pickStartDate,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              'Start date: ${AppDates.short.format(_startDate)}',
                            ),
                          ),
                        ),
                        field(
                          DropdownButtonFormField<int>(
                            initialValue: _dueDay,
                            decoration: const InputDecoration(
                              labelText: 'EMI due day',
                            ),
                            items: List.generate(
                              28,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1}'),
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => _dueDay = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _calculateEmi,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Calculate EMI'),
                        ),
                        FilledButton.icon(
                          onPressed: _saveLoan,
                          icon: const Icon(Icons.save),
                          label: const Text('Save loan'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _calculateEmi() {
    final principal = Money.fromRupees(_principal.text);
    final rate = double.tryParse(_interest.text) ?? 0;
    final months = int.tryParse(_tenure.text) ?? 0;
    final emi = EmiCalculator.calculateMonthlyEmi(
      principalPaise: principal,
      annualInterestRate: rate,
      tenureMonths: months,
    );
    setState(() => _emi.text = (emi / 100).round().toString());
  }

  void _saveLoan() {
    if (_name.text.trim().isEmpty || _lender.text.trim().isEmpty) return;
    ref
        .read(financeControllerProvider.notifier)
        .addLoan(
          name: _name.text.trim(),
          type: _type,
          lenderName: _lender.text.trim(),
          principalPaise: Money.fromRupees(_principal.text),
          interestRate: double.tryParse(_interest.text) ?? 0,
          startDate: _startDate,
          tenureMonths: int.tryParse(_tenure.text) ?? 1,
          emiPaise: Money.fromRupees(_emi.text),
          emiDueDay: _dueDay,
          paidEmiCount: int.tryParse(_paid.text) ?? 0,
          notes: _notes.text.trim(),
        );
    context.go('/loans');
  }
}

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final matches = state.loans.where((item) => item.id == loanId);
    if (matches.isEmpty) {
      return FinancePage(
        title: 'Loan not found',
        subtitle: 'Add your active loan to create an EMI schedule.',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/loans/add'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add loan'),
          ),
        ],
        children: const [SurfacePanel(child: Text('No matching loan exists.'))],
      );
    }
    final loan = matches.first;
    final schedule = EmiCalculator.buildSchedule(
      principalPaise: loan.principalPaise,
      annualInterestRate: loan.interestRate,
      tenureMonths: loan.tenureMonths,
      startDate: loan.startDate,
      paidCount: loan.paidEmiCount,
    );
    return FinancePage(
      title: loan.name,
      subtitle:
          '${loan.lenderName} • ${loan.interestRate}% • EMI due day ${loan.emiDueDay}',
      children: [
        ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'Principal',
              value: Money.format(loan.principalPaise, compact: true),
              icon: Icons.account_balance,
            ),
            SummaryCard(
              label: 'Monthly EMI',
              value: Money.format(loan.emiPaise),
              icon: Icons.calendar_month,
            ),
            SummaryCard(
              label: 'Total payable',
              value: Money.format(loan.totalPayablePaise, compact: true),
              icon: Icons.receipt,
            ),
            SummaryCard(
              label: 'Foreclosure estimate',
              value: Money.format(
                loan.remainingPrincipalEstimatePaise,
                compact: true,
              ),
              icon: Icons.lock_open,
            ),
          ],
        ),
        DataPanel(
          title: 'EMI schedule',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Due date')),
                DataColumn(label: Text('EMI')),
                DataColumn(label: Text('Principal')),
                DataColumn(label: Text('Interest')),
                DataColumn(label: Text('Balance')),
                DataColumn(label: Text('Status')),
              ],
              rows: schedule.take(18).map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text('${item.index}')),
                    DataCell(Text(AppDates.short.format(item.dueDate))),
                    DataCell(Text(Money.format(item.amountPaise))),
                    DataCell(Text(Money.format(item.principalPaise))),
                    DataCell(Text(Money.format(item.interestPaise))),
                    DataCell(Text(Money.format(item.remainingBalancePaise))),
                    DataCell(
                      StatusBadge(
                        status: item.isPaid
                            ? TransactionStatus.paid
                            : TransactionStatus.pending,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class EmiCalendarScreen extends ConsumerWidget {
  const EmiCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(financeControllerProvider).loans;
    return _ListModuleScreen(
      title: 'EMI calendar',
      subtitle:
          'Upcoming EMI due dates with amount, lender, and payment status.',
      items: loans
          .map(
            (loan) => ListTile(
              leading: const Icon(Icons.event),
              title: Text('${loan.name} EMI'),
              subtitle: Text('${loan.lenderName} • due day ${loan.emiDueDay}'),
              trailing: Text(
                Money.format(loan.emiPaise),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          )
          .toList(),
    );
  }
}

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    return _ListModuleScreen(
      title: 'Person ledgers',
      subtitle:
          'Borrowed, lent, returned, received, settlement, reminders, and exports by person or organisation.',
      items: state.people
          .map(
            (person) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(person.name),
              subtitle: Text('${person.relationship} • ${person.phone}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/people/${person.id}'),
            ),
          )
          .toList(),
    );
  }
}

class PersonLedgerScreen extends ConsumerWidget {
  const PersonLedgerScreen({super.key, required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final person = state.people.firstWhere(
      (item) => item.id == personId,
      orElse: () => state.people.first,
    );
    final payable = state.payables.where((item) => item.personId == person.id);
    final receivable = state.receivables.where(
      (item) => item.personId == person.id,
    );
    return FinancePage(
      title: person.name,
      subtitle:
          '${person.relationship} ledger with repayments, collections, reminders, notes, and attachments.',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.notifications),
          label: const Text('Reminder'),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/add'),
          icon: const Icon(Icons.add),
          label: const Text('Record'),
        ),
      ],
      children: [
        ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'Borrowed from them',
              value: Money.format(
                payable.fold<int>(0, (s, p) => s + p.amountBorrowedPaise),
              ),
              icon: Icons.call_received,
            ),
            SummaryCard(
              label: 'Returned',
              value: Money.format(
                payable.fold<int>(0, (s, p) => s + p.amountReturnedPaise),
              ),
              icon: Icons.task_alt,
            ),
            SummaryCard(
              label: 'Lent to them',
              value: Money.format(
                receivable.fold<int>(0, (s, r) => s + r.amountGivenPaise),
              ),
              icon: Icons.call_made,
            ),
            SummaryCard(
              label: 'Received back',
              value: Money.format(
                receivable.fold<int>(0, (s, r) => s + r.amountReceivedPaise),
              ),
              icon: Icons.payments,
            ),
          ],
        ),
        DataPanel(
          title: 'Settlement history',
          child: Column(
            children: [
              ...payable.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Money I owe'),
                  subtitle: Text(
                    'Expected ${AppDates.short.format(p.expectedReturnDate)} • ${p.notes}',
                  ),
                  trailing: StatusBadge(status: p.status),
                ),
              ),
              ...receivable.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Money owed to me'),
                  subtitle: Text(
                    'Expected ${AppDates.short.format(r.expectedReturnDate)} • ${r.notes}',
                  ),
                  trailing: StatusBadge(status: r.status),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PayablesScreen extends ConsumerWidget {
  const PayablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    return _ListModuleScreen(
      title: 'Money I owe',
      subtitle:
          'Partial repayments automatically reduce remaining balances and flag overdue returns.',
      items: state.payables.map((item) {
        final person = state.people.firstWhere((p) => p.id == item.personId);
        return ListTile(
          leading: const Icon(Icons.call_received),
          title: Text(person.name),
          subtitle: Text(
            'Remaining ${Money.format(item.remainingPaise)} • due ${AppDates.short.format(item.expectedReturnDate)}',
          ),
          trailing: StatusBadge(status: item.status),
        );
      }).toList(),
    );
  }
}

class ReceivablesScreen extends ConsumerWidget {
  const ReceivablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    return _ListModuleScreen(
      title: 'Money owed to me',
      subtitle:
          'Track lent money, partial collections, follow-up reminders, and settlement status.',
      items: state.receivables.map((item) {
        final person = state.people.firstWhere((p) => p.id == item.personId);
        return ListTile(
          leading: const Icon(Icons.call_made),
          title: Text(person.name),
          subtitle: Text(
            'Receivable ${Money.format(item.remainingPaise)} • due ${AppDates.short.format(item.expectedReturnDate)}',
          ),
          trailing: StatusBadge(status: item.status),
        );
      }).toList(),
    );
  }
}

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(financeControllerProvider).budgets;
    return FinancePage(
      title: 'Budgets',
      subtitle:
          'Monthly and yearly limits for personal categories, company projects, departments, and accounts.',
      children: budgets
          .map(
            (budget) => DataPanel(
              title: budget.name,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: budget.consumed.clamp(0, 1)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 22,
                    runSpacing: 10,
                    children: [
                      _Fact('Scope', budget.scope.label),
                      _Fact('Category', budget.category),
                      _Fact('Used', Money.format(budget.usedPaise)),
                      _Fact('Remaining', Money.format(budget.remainingPaise)),
                      _Fact(
                        'Consumed',
                        '${(budget.consumed * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    return FinancePage(
      title: 'Reports and analytics',
      subtitle:
          'Income, expenses, cash flow, profit and loss, loans, tax-ready GST expenses, vendors, and yearly comparisons.',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.table_chart),
          label: const Text('CSV'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.print),
          label: const Text('Print'),
        ),
      ],
      children: [
        DataPanel(
          title: 'Monthly cash flow trend',
          child: SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minY: 0,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    color: Theme.of(context).colorScheme.primary,
                    spots: [
                      const FlSpot(0, 22),
                      const FlSpot(1, 31),
                      FlSpot(
                        2,
                        (metrics.netCashFlowPaise.abs() / 1000000).clamp(8, 90),
                      ),
                      const FlSpot(3, 42),
                      const FlSpot(4, 36),
                      const FlSpot(5, 48),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'Tax-ready expenses',
              value: Money.format(metrics.companyExpensesPaise),
              icon: Icons.request_quote,
            ),
            SummaryCard(
              label: 'Profit and loss',
              value: Money.signed(metrics.netCashFlowPaise),
              icon: Icons.assessment,
            ),
            SummaryCard(
              label: 'Payables',
              value: Money.format(metrics.owePaise),
              icon: Icons.call_received,
            ),
            SummaryCard(
              label: 'Receivables',
              value: Money.format(metrics.owedToMePaise),
              icon: Icons.call_made,
            ),
          ],
        ),
        DataPanel(
          title: 'Report summary',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Report')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Export')),
              ],
              rows: [
                DataRow(
                  cells: [
                    const DataCell(Text('Company expenses')),
                    DataCell(Text(Money.format(metrics.companyExpensesPaise))),
                    const DataCell(Text('GST ready')),
                    const DataCell(Text('PDF / CSV')),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Cash flow')),
                    DataCell(Text(Money.signed(metrics.netCashFlowPaise))),
                    const DataCell(Text('Reviewed')),
                    const DataCell(Text('PDF / CSV')),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Receivables')),
                    DataCell(Text(Money.format(metrics.owedToMePaise))),
                    const DataCell(Text('Follow-up')),
                    const DataCell(Text('CSV')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(financeControllerProvider).reminders;
    return _ListModuleScreen(
      title: 'Notifications and reminders',
      subtitle:
          'EMIs, credit cards, recurring bills, subscription renewals, expected income, budget limits, and overdue payments.',
      items: reminders
          .map(
            (item) => ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(item.title),
              subtitle: Text(
                '${item.type.label} • ${AppDates.short.format(item.dueAt)}',
              ),
              trailing: Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(Money.format(item.amountPaise)),
                  StatusBadge(status: item.status),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeControllerProvider);
    final txns = state.transactions.where(
      (txn) =>
          txn.description.toLowerCase().contains(_query.toLowerCase()) ||
          txn.category.toLowerCase().contains(_query.toLowerCase()),
    );
    final people = state.people.where(
      (person) => person.name.toLowerCase().contains(_query.toLowerCase()),
    );
    return FinancePage(
      title: 'Global search',
      subtitle:
          'Search transactions, people, vendors, accounts, categories, notes, invoices, and loan names.',
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search everything',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        DataPanel(
          title: 'Results',
          child: Column(
            children: [
              ...txns.map(
                (txn) => ListTile(
                  title: Text(txn.description),
                  subtitle: Text(
                    '${txn.category} • ${Money.format(txn.amountPaise)}',
                  ),
                ),
              ),
              ...people.map(
                (person) => ListTile(
                  title: Text(person.name),
                  subtitle: Text(person.phone),
                ),
              ),
              if (_query.isEmpty)
                const ListTile(
                  title: Text('Start typing to filter your finance records.'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PersonalExpensesScreen extends ConsumerWidget {
  const PersonalExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _TransactionModuleScreen(
    title: 'Personal expenses',
    subtitle:
        'Food, travel, shopping, medical, rent, utilities, family, investments, taxes, and custom categories.',
    scope: FinanceScope.personal,
    type: TransactionType.expense,
  );
}

class CompanyExpensesScreen extends ConsumerWidget {
  const CompanyExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _TransactionModuleScreen(
    title: 'Company expenses',
    subtitle:
        'Payroll, vendors, GST, invoices, reimbursables, departments, projects, and due dates.',
    scope: FinanceScope.company,
    type: TransactionType.expense,
  );
}

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => const _TransactionModuleScreen(
    title: 'Income and earnings',
    subtitle:
        'Salary, revenue, client payments, freelance income, investment returns, refunds, grants, and funding.',
    type: TransactionType.income,
  );
}

class _TransactionModuleScreen extends ConsumerWidget {
  const _TransactionModuleScreen({
    required this.title,
    required this.subtitle,
    required this.type,
    this.scope,
  });

  final String title;
  final String subtitle;
  final TransactionType type;
  final FinanceScope? scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final txns = state.transactions
        .where(
          (txn) => txn.type == type && (scope == null || txn.scope == scope),
        )
        .toList();
    final total = txns.fold<int>(0, (sum, txn) => sum + txn.amountPaise);
    return FinancePage(
      title: title,
      subtitle: subtitle,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
      children: [
        ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'Total',
              value: Money.format(total, compact: true),
              icon: Icons.summarize,
            ),
            SummaryCard(
              label: 'Entries',
              value: '${txns.length}',
              icon: Icons.receipt_long,
            ),
            SummaryCard(
              label: 'Pending',
              value:
                  '${txns.where((t) => t.status == TransactionStatus.pending).length}',
              icon: Icons.schedule,
            ),
            SummaryCard(
              label: 'Recurring',
              value: '${txns.where((t) => t.isRecurring).length}',
              icon: Icons.repeat,
            ),
          ],
        ),
        _TransactionsPanel(transactions: txns),
      ],
    );
  }
}

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(financeControllerProvider).recurring;
    return _ListModuleScreen(
      title: 'Recurring transactions',
      subtitle:
          'Subscriptions, rent, payroll, expected income, and bills with next run dates.',
      items: recurring
          .map(
            (item) => ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(item.name),
              subtitle: Text(
                '${item.frequency} • next ${AppDates.short.format(item.nextRunDate)}',
              ),
              trailing: Text(Money.format(item.amountPaise)),
            ),
          )
          .toList(),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _ListModuleScreen(
    title: 'Receipt and document manager',
    subtitle:
        'Invoices, bills, loan documents, proofs, attachments, and export-ready records.',
    items: [
      ListTile(
        leading: Icon(Icons.receipt),
        title: Text('AWS-IN-7751.pdf'),
        subtitle: Text('GST invoice • cloud infrastructure'),
      ),
      ListTile(
        leading: Icon(Icons.home_work),
        title: Text('Home loan sanction letter.pdf'),
        subtitle: Text('Loan document'),
      ),
      ListTile(
        leading: Icon(Icons.image),
        title: Text('team-dinner-receipt.jpg'),
        subtitle: Text('Personal expense receipt'),
      ),
    ],
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(financeControllerProvider).profile;
    return _ListModuleScreen(
      title: 'Profile',
      subtitle:
          'Founder identity, company, locale, currency, and access settings.',
      items: [
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(profile.name),
          subtitle: Text(profile.email),
        ),
        ListTile(
          leading: const Icon(Icons.business),
          title: Text(profile.companyName),
          subtitle: const Text('Primary business workspace'),
        ),
        ListTile(
          leading: const Icon(Icons.currency_rupee),
          title: Text(profile.primaryCurrency),
          subtitle: const Text('Indian number format enabled'),
        ),
        const Divider(height: 32),
        const _DeleteAccountTile(),
      ],
    );
  }
}

/// In-app account deletion. Google Play requires this path to exist inside the
/// app, alongside the public page at /delete-account.
class _DeleteAccountTile extends ConsumerStatefulWidget {
  const _DeleteAccountTile();

  @override
  ConsumerState<_DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends ConsumerState<_DeleteAccountTile> {
  AccountDeletionStatus _status = AccountDeletionStatus.none;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppConfig.hasApi) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      final status = await ref
          .read(apiFinanceStoreProvider)
          .readDeletionStatus();
      if (mounted) setState(() => _status = status);
    } on DioException {
      // Leave the tile actionable; the request itself will surface errors.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_busy) {
      return const ListTile(
        leading: Icon(Icons.delete_forever),
        title: Text('Delete account'),
        subtitle: Text('Checking status...'),
      );
    }

    if (_status.pending) {
      final purgeAt = _status.scheduledPurgeAt;
      return ListTile(
        leading: Icon(Icons.timer_outlined, color: theme.colorScheme.error),
        title: const Text('Account deletion scheduled'),
        subtitle: Text(
          purgeAt == null
              ? 'Your data will be erased after the grace period.'
              : 'All your data is erased on ${AppDates.short.format(purgeAt)}. '
                    'You can still cancel until then.',
        ),
        trailing: OutlinedButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        isThreeLine: true,
      );
    }

    return ListTile(
      leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
      title: const Text('Delete account'),
      subtitle: const Text(
        'Permanently erase your account and all finance data after a '
        '30 day grace period.',
      ),
      trailing: OutlinedButton(
        onPressed: _confirm,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
        ),
        child: const Text('Delete'),
      ),
      isThreeLine: true,
    );
  }

  Future<void> _confirm() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete your MONEX account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently erases your profile, accounts, categories, '
                'loans and every transaction after 30 days. You can cancel '
                'during that period by signing in again.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep my account'),
            ),
            FilledButton(
              onPressed: controller.text.trim().toUpperCase() == 'DELETE'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final status = await ref
          .read(apiFinanceStoreProvider)
          .requestAccountDeletion();
      if (!mounted) return;
      setState(() => _status = status);
      _notify('Account deletion scheduled. Sign in before then to cancel.');
    } on DioException catch (error) {
      if (!mounted) return;
      _notify('Could not schedule deletion: ${_reason(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      final status = await ref
          .read(apiFinanceStoreProvider)
          .cancelAccountDeletion();
      if (!mounted) return;
      setState(() => _status = status);
      _notify('Account deletion cancelled');
    } on DioException catch (error) {
      if (!mounted) return;
      _notify('Could not cancel deletion: ${_reason(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _reason(DioException error) =>
      (error.response?.data is Map &&
          (error.response!.data as Map)['error'] != null)
      ? (error.response!.data as Map)['error'].toString()
      : 'network error';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ListModuleScreen(
      title: 'Settings',
      subtitle:
          'Security, privacy, theme, role-based access, session timeout, backup, and localization.',
      items: [
        const _AppLockTile(),
        const _SmsCaptureTile(),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Theme'),
          subtitle: const Text('System, light, and dark mode supported'),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Production backend'),
          subtitle: const Text('Secure session with hosted MONEX API'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          subtitle: const Text('End this device session'),
          trailing: OutlinedButton(
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}

/// Fingerprint / device-credential lock, backed by [appLockControllerProvider].
class _AppLockTile extends ConsumerWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockControllerProvider);
    final controller = ref.read(appLockControllerProvider.notifier);
    final usable = controller.isSupported && lock.available;

    return SwitchListTile(
      value: lock.enabled,
      onChanged: usable
          ? (value) async {
              final error = await controller.setEnabled(value);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              }
            }
          : null,
      title: const Text('Fingerprint or screen lock'),
      subtitle: Text(
        !controller.isSupported
            ? 'Available on Android and iOS builds'
            : !lock.available
            ? 'Set up a fingerprint or screen lock on this device first'
            : lock.hasBiometrics
            ? 'Ask for your fingerprint every time MONEX opens'
            : 'Ask for your device PIN every time MONEX opens',
      ),
      secondary: const Icon(Icons.fingerprint),
    );
  }
}

/// Mirror of the toggle on the Bank Imports screen, kept here so security and
/// privacy settings live in one place.
class _SmsCaptureTile extends ConsumerWidget {
  const _SmsCaptureTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(smsImportControllerProvider);
    final controller = ref.read(smsImportControllerProvider.notifier);

    return SwitchListTile(
      value: importState.autoCaptureEnabled,
      onChanged: controller.isSupported
          ? (value) => controller.setAutoCapture(value)
          : null,
      title: const Text('Automatic bank SMS import'),
      subtitle: Text(
        controller.isSupported
            ? 'Read bank SMS on this device and queue them for approval'
            : 'Available on Android only',
      ),
      secondary: const Icon(Icons.sms_outlined),
    );
  }
}

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});
  @override
  Widget build(BuildContext context) => const _ListModuleScreen(
    title: 'Data backup and export',
    subtitle:
        'Backup, restore, PDF, CSV, Excel-compatible exports, and print-friendly web layouts.',
    items: [
      ListTile(
        leading: Icon(Icons.cloud_upload),
        title: Text('Backup hosted finance workspace'),
        subtitle: Text('Encrypted archive workflow ready'),
      ),
      ListTile(
        leading: Icon(Icons.file_download),
        title: Text('Export reports'),
        subtitle: Text('PDF, CSV, and Excel-compatible formats'),
      ),
      ListTile(
        leading: Icon(Icons.restore),
        title: Text('Restore from backup'),
        subtitle: Text('Validation and conflict-resolution checkpoint'),
      ),
    ],
  );
}

class _TransactionsPanel extends StatelessWidget {
  const _TransactionsPanel({required this.transactions});
  final Iterable<dynamic> transactions;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      title: 'Records',
      child: Column(
        children: transactions
            .map(
              (txn) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ModuleTransactionRow(transaction: txn),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ListModuleScreen extends StatelessWidget {
  const _ListModuleScreen({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return FinancePage(
      title: title,
      subtitle: subtitle,
      children: [
        DataPanel(
          title: title,
          child: ListView.separated(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: items[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleTransactionRow extends StatelessWidget {
  const _ModuleTransactionRow({required this.transaction});

  final dynamic transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final type = transaction.type as TransactionType;
    final debit =
        type == TransactionType.expense ||
        type == TransactionType.emiPayment ||
        type == TransactionType.moneyLent ||
        type == TransactionType.repayment;
    final accent = debit ? colors.expense : colors.income;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: .12),
          child: Icon(AppIcons.transaction(type), color: accent, size: 20),
        ),
        title: Text(
          transaction.description as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${transaction.category} • ${AppDates.short.format(transaction.date as DateTime)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          Money.format(transaction.amountPaise as int),
          style: AppTypography.money(
            Theme.of(context).textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogScrollContent extends StatelessWidget {
  const _DialogScrollContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 64).clamp(280.0, 520.0).toDouble();
    final maxHeight = (size.height - 220).clamp(240.0, 560.0).toDouble();

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.money(
              Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyApiError(Object error, {required String fallback}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'];
      final missing = data['missingEnv'];
      if (message is String && missing is List) {
        return '$message: ${missing.join(', ')}';
      }
      if (message is String && message.isNotEmpty) return message;
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Cannot reach MONEX backend. Check internet and server status.';
    }
  }

  return fallback;
}
