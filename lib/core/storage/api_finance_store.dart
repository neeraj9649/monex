import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../shared/models/finance_models.dart';
import 'secure_session_store.dart';

class ApiFinanceStore {
  ApiFinanceStore(this._sessionStore)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final SecureSessionStore _sessionStore;
  final Dio _dio;

  Future<RemoteWorkspace> readWorkspace() async {
    final results = await Future.wait([
      readAccounts(),
      readCategories(),
      readLoans(),
      readTransactions(),
    ]);
    return RemoteWorkspace(
      accounts: results[0] as List<Account>,
      categories: results[1] as List<TransactionCategory>,
      loans: results[2] as List<Loan>,
      transactions: results[3] as List<FinanceTransaction>,
    );
  }

  Future<List<Account>> readAccounts() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/accounts',
      options: await _authOptions(),
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => Account.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Account> createAccount(Account account) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/accounts',
      data: account.toJson(),
      options: await _authOptions(),
    );
    return Account.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<List<TransactionCategory>> readCategories() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/categories',
      options: await _authOptions(),
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map(
          (item) => TransactionCategory.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<TransactionCategory> createCategory(
    TransactionCategory category,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/categories',
      data: category.toJson(),
      options: await _authOptions(),
    );
    return TransactionCategory.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<List<Loan>> readLoans() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/loans',
      options: await _authOptions(),
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => Loan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Loan> createLoan(Loan loan) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/loans',
      data: loan.toJson(),
      options: await _authOptions(),
    );
    return Loan.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<List<FinanceTransaction>> readTransactions() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/transactions',
      options: await _authOptions(),
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map(
          (item) => FinanceTransaction.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<FinanceTransaction> createTransaction(
    FinanceTransaction transaction,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/transactions',
      data: transaction.toJson(),
      options: await _authOptions(),
    );
    return FinanceTransaction.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<Options> _authOptions() async {
    final token = await _sessionStore.readToken();
    return Options(
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }
}

class RemoteWorkspace {
  const RemoteWorkspace({
    required this.accounts,
    required this.categories,
    required this.loans,
    required this.transactions,
  });

  final List<Account> accounts;
  final List<TransactionCategory> categories;
  final List<Loan> loans;
  final List<FinanceTransaction> transactions;
}
