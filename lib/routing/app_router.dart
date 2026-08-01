import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/imports/presentation/sms_imports_screen.dart';
import '../features/presentation/module_screens.dart';
import '../features/transactions/presentation/add_transaction_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../shared/providers/finance_providers.dart';
import '../shared/widgets/finance_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublicRoute = {
        '/',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
      }.contains(location);

      if (session.isLoading) return location == '/' ? null : '/';

      final isAuthenticated = session.when(
        data: (value) => value,
        error: (_, _) => false,
        loading: () => false,
      );
      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isPublicRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => FinanceShell(child: child),
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/transactions/:id',
            builder: (context, state) => TransactionDetailScreen(
              transactionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/edit/:id',
            builder: (context, state) => EditTransactionScreen(
              transactionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/add',
            builder: (context, state) => const AddTransactionScreen(),
          ),
          GoRoute(
            path: '/personal-expenses',
            builder: (context, state) => const PersonalExpensesScreen(),
          ),
          GoRoute(
            path: '/company-expenses',
            builder: (context, state) => const CompanyExpensesScreen(),
          ),
          GoRoute(
            path: '/income',
            builder: (context, state) => const IncomeScreen(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/accounts/:id',
            builder: (context, state) =>
                AccountDetailScreen(accountId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/loans',
            builder: (context, state) => const LoansScreen(),
          ),
          GoRoute(
            path: '/loans/add',
            builder: (context, state) => const AddLoanScreen(),
          ),
          GoRoute(
            path: '/loans/:id',
            builder: (context, state) =>
                LoanDetailScreen(loanId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/emi-calendar',
            builder: (context, state) => const EmiCalendarScreen(),
          ),
          GoRoute(
            path: '/people',
            builder: (context, state) => const PeopleScreen(),
          ),
          GoRoute(
            path: '/people/:id',
            builder: (context, state) =>
                PersonLedgerScreen(personId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/payables',
            builder: (context, state) => const PayablesScreen(),
          ),
          GoRoute(
            path: '/receivables',
            builder: (context, state) => const ReceivablesScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/recurring',
            builder: (context, state) => const RecurringTransactionsScreen(),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: '/sms-imports',
            builder: (context, state) => const SmsImportsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/backup',
            builder: (context, state) => const BackupScreen(),
          ),
        ],
      ),
    ],
  );
});
