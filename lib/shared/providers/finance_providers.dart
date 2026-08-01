import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import '../../core/storage/api_auth_store.dart';
import '../../core/storage/api_finance_store.dart';
import '../../core/storage/local_finance_store.dart';
import '../../core/storage/secure_session_store.dart';
import '../models/enums.dart';
import '../models/finance_models.dart';
import '../models/imported_bank_message.dart';

final localFinanceStoreProvider = Provider((ref) => LocalFinanceStore());
final secureSessionStoreProvider = Provider((ref) => SecureSessionStore());
final apiAuthStoreProvider = Provider(
  (ref) => ApiAuthStore(ref.watch(secureSessionStoreProvider)),
);
final apiFinanceStoreProvider = Provider(
  (ref) => ApiFinanceStore(ref.watch(secureSessionStoreProvider)),
);

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, bool>(SessionController.new);

final financeControllerProvider =
    NotifierProvider<FinanceController, FinanceState>(FinanceController.new);

class SessionController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.read(secureSessionStoreProvider).readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(apiAuthStoreProvider)
          .login(email: email, password: password);
      ref.invalidate(financeControllerProvider);
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(apiAuthStoreProvider)
          .register(
            name: name,
            email: email,
            password: password,
            companyName: companyName,
          );
      ref.invalidate(financeControllerProvider);
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(secureSessionStoreProvider).clear();
    ref.invalidate(financeControllerProvider);
    state = const AsyncValue.data(false);
  }
}

class FinanceState {
  const FinanceState({
    required this.profile,
    required this.business,
    required this.accounts,
    required this.transactions,
    required this.categories,
    required this.people,
    required this.vendors,
    required this.loans,
    required this.payables,
    required this.receivables,
    required this.budgets,
    required this.recurring,
    required this.reminders,
    this.isHydrated = false,
    this.lastMessage,
  });

  final UserProfile profile;
  final Business business;
  final List<Account> accounts;
  final List<FinanceTransaction> transactions;
  final List<TransactionCategory> categories;
  final List<Person> people;
  final List<Vendor> vendors;
  final List<Loan> loans;
  final List<Payable> payables;
  final List<Receivable> receivables;
  final List<Budget> budgets;
  final List<RecurringTransaction> recurring;
  final List<Reminder> reminders;
  final bool isHydrated;
  final String? lastMessage;

  FinanceState copyWith({
    UserProfile? profile,
    Business? business,
    List<Account>? accounts,
    List<FinanceTransaction>? transactions,
    List<TransactionCategory>? categories,
    List<Loan>? loans,
    bool? isHydrated,
    String? lastMessage,
  }) {
    return FinanceState(
      profile: profile ?? this.profile,
      business: business ?? this.business,
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      people: people,
      vendors: vendors,
      loans: loans ?? this.loans,
      payables: payables,
      receivables: receivables,
      budgets: budgets,
      recurring: recurring,
      reminders: reminders,
      isHydrated: isHydrated ?? this.isHydrated,
      lastMessage: lastMessage,
    );
  }
}

class FinanceController extends Notifier<FinanceState> {
  final _uuid = const Uuid();

  static const _emptyProfile = UserProfile(
    id: 'current-user',
    name: 'Founder',
    email: '',
    phone: '',
    primaryCurrency: 'INR',
    companyName: '',
  );

  static const _emptyBusiness = Business(
    id: 'current-business',
    name: 'MONEX Workspace',
    gstin: '',
    financialYearStartMonth: 4,
  );

  @override
  FinanceState build() {
    const initial = FinanceState(
      profile: _emptyProfile,
      business: _emptyBusiness,
      accounts: [],
      transactions: [],
      categories: [],
      people: [],
      vendors: [],
      loans: [],
      payables: [],
      receivables: [],
      budgets: [],
      recurring: [],
      reminders: [],
    );

    Future.microtask(_hydrate);
    return initial;
  }

  Future<void> _hydrate() async {
    if (AppConfig.hasApi) {
      try {
        final remote = await ref.read(apiFinanceStoreProvider).readWorkspace();
        state = state.copyWith(
          profile: remote.profile,
          business: Business(
            id: 'current-business',
            name: remote.profile.companyName.isEmpty
                ? 'MONEX Workspace'
                : remote.profile.companyName,
            gstin: '',
            financialYearStartMonth: 4,
          ),
          accounts: remote.accounts,
          categories: remote.categories,
          loans: remote.loans,
          transactions: remote.transactions,
          isHydrated: true,
          lastMessage: 'Remote database connected',
        );
        return;
      } catch (_) {
        state = state.copyWith(
          isHydrated: true,
          lastMessage:
              'Unable to connect to MONEX backend. Check your connection or sign in again.',
        );
        return;
      }
    }

    if (!AppConfig.allowLocalData) {
      state = state.copyWith(
        isHydrated: true,
        lastMessage: 'Backend mode required',
      );
      return;
    }

    final persisted = await ref
        .read(localFinanceStoreProvider)
        .readTransactions();
    if (persisted != null && persisted.isNotEmpty) {
      state = state.copyWith(
        transactions: persisted,
        isHydrated: true,
        lastMessage: 'Local data restored',
      );
    } else {
      state = state.copyWith(isHydrated: true);
    }
  }

  Future<void> addTransaction({
    required TransactionType type,
    required FinanceScope scope,
    required int amountPaise,
    required String category,
    required String accountId,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.upi,
    String? toAccountId,
    String? subcategory,
    String? vendorName,
    String? invoiceNumber,
    int? gstPaise,
    DateTime? dueDate,
    String? personId,
    bool isRecurring = false,
    bool isReimbursable = false,
    bool paidPersonally = false,
    TransactionStatus status = TransactionStatus.paid,
  }) async {
    final transaction = FinanceTransaction(
      id: _uuid.v4(),
      type: type,
      scope: scope,
      amountPaise: amountPaise,
      category: category,
      subcategory: subcategory,
      accountId: accountId,
      toAccountId: toAccountId,
      paymentMethod: paymentMethod,
      date: date,
      description: description,
      vendorName: vendorName,
      invoiceNumber: invoiceNumber,
      gstPaise: gstPaise,
      dueDate: dueDate,
      personId: personId,
      businessName: scope == FinanceScope.company ? state.business.name : null,
      isRecurring: isRecurring,
      isReimbursable: isReimbursable,
      paidPersonally: paidPersonally,
      status: status,
    );

    final savedTransaction = AppConfig.hasApi
        ? await ref.read(apiFinanceStoreProvider).createTransaction(transaction)
        : transaction;

    final transactions = [savedTransaction, ...state.transactions];
    state = state.copyWith(
      transactions: transactions,
      accounts: _applyTransactionToAccounts(savedTransaction, state.accounts),
      lastMessage: 'Transaction saved',
    );
    if (AppConfig.allowLocalData) {
      await ref.read(localFinanceStoreProvider).saveTransactions(transactions);
    }
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required FinanceScope scope,
    required int balancePaise,
    String? institution,
    int? creditLimitPaise,
    String? accountNumber,
  }) async {
    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      scope: scope,
      balancePaise: balancePaise,
      availableBalancePaise: balancePaise,
      creditLimitPaise: creditLimitPaise,
      institution: institution,
      accountNumber: accountNumber,
    );
    final savedAccount = AppConfig.hasApi
        ? await ref.read(apiFinanceStoreProvider).createAccount(account)
        : account;
    state = state.copyWith(
      accounts: [savedAccount, ...state.accounts],
      lastMessage: 'Account added',
    );
  }

  Future<void> addCategory({
    required String name,
    required FinanceScope scope,
    required TransactionType type,
    List<String> subcategories = const [],
  }) async {
    final category = TransactionCategory(
      id: _uuid.v4(),
      name: name,
      scope: scope,
      type: type,
      subcategories: subcategories,
    );
    final savedCategory = AppConfig.hasApi
        ? await ref.read(apiFinanceStoreProvider).createCategory(category)
        : category;
    state = state.copyWith(
      categories: [savedCategory, ...state.categories],
      lastMessage: 'Category added',
    );
  }

  Future<void> addLoan({
    required String name,
    required LoanType type,
    required String lenderName,
    required int principalPaise,
    required double interestRate,
    required DateTime startDate,
    required int tenureMonths,
    required int emiPaise,
    required int emiDueDay,
    int paidEmiCount = 0,
    String notes = '',
  }) async {
    final loan = Loan(
      id: _uuid.v4(),
      name: name,
      type: type,
      lenderName: lenderName,
      principalPaise: principalPaise,
      interestRate: interestRate,
      startDate: startDate,
      tenureMonths: tenureMonths,
      emiPaise: emiPaise,
      emiDueDay: emiDueDay,
      paidEmiCount: paidEmiCount,
      notes: notes,
    );
    final savedLoan = AppConfig.hasApi
        ? await ref.read(apiFinanceStoreProvider).createLoan(loan)
        : loan;
    state = state.copyWith(
      loans: [savedLoan, ...state.loans],
      lastMessage: 'Loan added',
    );
  }

  Future<void> addImportedBankMessage({
    required ImportedBankMessage message,
    required String category,
    required String accountId,
    required String description,
    String? receiptName,
  }) async {
    await addTransaction(
      type: message.transactionType,
      scope: FinanceScope.personal,
      amountPaise: message.amountPaise,
      category: category,
      accountId: accountId,
      date: message.date,
      description: description,
      paymentMethod: PaymentMethod.bankTransfer,
      status: TransactionStatus.paid,
    );
  }

  Future<void> clearLocalRecords() async {
    if (!AppConfig.allowLocalData) {
      state = state.copyWith(lastMessage: 'Local data is disabled');
      return;
    }
    await ref.read(localFinanceStoreProvider).clear();
    state = state.copyWith(
      transactions: const [],
      accounts: const [],
      categories: const [],
      loans: const [],
      lastMessage: 'Local records cleared',
    );
  }

  List<Account> _applyTransactionToAccounts(
    FinanceTransaction txn,
    List<Account> accounts,
  ) {
    return accounts.map((account) {
      if (account.id == txn.accountId) {
        return account.copyWith(
          balancePaise: account.balancePaise + _accountDelta(txn, source: true),
          outstandingPaise:
              account.outstandingPaise +
              (account.type == AccountType.creditCard &&
                      txn.type == TransactionType.expense
                  ? txn.amountPaise
                  : 0),
        );
      }
      if (account.id == txn.toAccountId) {
        return account.copyWith(
          balancePaise:
              account.balancePaise + _accountDelta(txn, source: false),
        );
      }
      return account;
    }).toList();
  }

  int _accountDelta(FinanceTransaction txn, {required bool source}) {
    switch (txn.type) {
      case TransactionType.income:
      case TransactionType.moneyBorrowed:
      case TransactionType.receivableCollection:
        return source ? txn.amountPaise : 0;
      case TransactionType.expense:
      case TransactionType.emiPayment:
      case TransactionType.moneyLent:
      case TransactionType.repayment:
      case TransactionType.loan:
        return source ? -txn.amountPaise : 0;
      case TransactionType.transfer:
        return source ? -txn.amountPaise : txn.amountPaise;
    }
  }
}

final dashboardMetricsProvider = Provider((ref) {
  final state = ref.watch(financeControllerProvider);
  return DashboardMetrics.fromState(state);
});

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalBalancePaise,
    required this.personalExpensesPaise,
    required this.companyExpensesPaise,
    required this.totalIncomePaise,
    required this.netCashFlowPaise,
    required this.owePaise,
    required this.owedToMePaise,
    required this.outstandingLoansPaise,
    required this.overdueCount,
    required this.expectedReceivablesPaise,
  });

  final int totalBalancePaise;
  final int personalExpensesPaise;
  final int companyExpensesPaise;
  final int totalIncomePaise;
  final int netCashFlowPaise;
  final int owePaise;
  final int owedToMePaise;
  final int outstandingLoansPaise;
  final int overdueCount;
  final int expectedReceivablesPaise;

  factory DashboardMetrics.fromState(FinanceState state) {
    final expenses = state.transactions.where(
      (txn) => txn.type == TransactionType.expense,
    );
    final income = state.transactions.where(
      (txn) => txn.type == TransactionType.income,
    );
    final personalExpenses = expenses
        .where((txn) => txn.scope == FinanceScope.personal)
        .fold<int>(0, (sum, txn) => sum + txn.amountPaise);
    final companyExpenses = expenses
        .where((txn) => txn.scope == FinanceScope.company)
        .fold<int>(0, (sum, txn) => sum + txn.amountPaise);
    final totalIncome = income.fold<int>(
      0,
      (sum, txn) => sum + txn.amountPaise,
    );
    final owe = state.payables.fold<int>(
      0,
      (sum, item) => sum + item.remainingPaise,
    );
    final owed = state.receivables.fold<int>(
      0,
      (sum, item) => sum + item.remainingPaise,
    );
    final outstandingLoans = state.loans.fold<int>(
      0,
      (sum, loan) => sum + loan.remainingPrincipalEstimatePaise,
    );
    final overdueCount = [
      ...state.payables.map((item) => item.status),
      ...state.receivables.map((item) => item.status),
      ...state.reminders.map((item) => item.status),
    ].where((status) => status == TransactionStatus.overdue).length;

    return DashboardMetrics(
      totalBalancePaise: state.accounts.fold<int>(
        0,
        (sum, account) => sum + account.balancePaise,
      ),
      personalExpensesPaise: personalExpenses,
      companyExpensesPaise: companyExpenses,
      totalIncomePaise: totalIncome,
      netCashFlowPaise: totalIncome - personalExpenses - companyExpenses,
      owePaise: owe,
      owedToMePaise: owed,
      outstandingLoansPaise: outstandingLoans,
      overdueCount: overdueCount,
      expectedReceivablesPaise: state.transactions
          .where(
            (txn) =>
                txn.type == TransactionType.income &&
                txn.status == TransactionStatus.pending,
          )
          .fold<int>(0, (sum, txn) => sum + txn.amountPaise),
    );
  }
}
