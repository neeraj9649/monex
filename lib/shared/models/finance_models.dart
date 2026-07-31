import 'enums.dart';

typedef JsonMap = Map<String, dynamic>;

class AuditFields {
  AuditFields({
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.createdBy = 'current-user',
    this.status = 'active',
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String createdBy;
  final String status;
  final String? notes;

  JsonMap toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
    'createdBy': createdBy,
    'status': status,
    'notes': notes,
  };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.primaryCurrency,
    required this.companyName,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String primaryCurrency;
  final String companyName;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'primaryCurrency': primaryCurrency,
    'companyName': companyName,
  };

  static UserProfile fromJson(JsonMap json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String? ?? '',
    primaryCurrency: json['primaryCurrency'] as String? ?? 'INR',
    companyName: json['companyName'] as String? ?? '',
  );
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.gstin,
    required this.financialYearStartMonth,
  });

  final String id;
  final String name;
  final String gstin;
  final int financialYearStartMonth;
}

class Attachment {
  const Attachment({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
  });

  final String id;
  final String name;
  final String type;
  final String url;
}

class Tag {
  const Tag({required this.id, required this.name});
  final String id;
  final String name;
}

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.scope,
    required this.type,
    this.subcategories = const [],
    this.icon = 'category',
  });

  final String id;
  final String name;
  final FinanceScope scope;
  final TransactionType type;
  final List<String> subcategories;
  final String icon;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'scope': scope.name,
    'type': type.name,
    'subcategories': subcategories,
    'icon': icon,
  };

  static TransactionCategory fromJson(JsonMap json) => TransactionCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    scope: FinanceScope.values.byName(json['scope'] as String),
    type: TransactionType.values.byName(json['type'] as String),
    subcategories: List<String>.from(
      json['subcategories'] as List? ?? const [],
    ),
    icon: json['icon'] as String? ?? 'category',
  );
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.scope,
    required this.balancePaise,
    this.availableBalancePaise,
    this.creditLimitPaise,
    this.outstandingPaise = 0,
    this.institution,
  });

  final String id;
  final String name;
  final AccountType type;
  final FinanceScope scope;
  final int balancePaise;
  final int? availableBalancePaise;
  final int? creditLimitPaise;
  final int outstandingPaise;
  final String? institution;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'scope': scope.name,
    'balancePaise': balancePaise,
    'availableBalancePaise': availableBalancePaise,
    'creditLimitPaise': creditLimitPaise,
    'outstandingPaise': outstandingPaise,
    'institution': institution,
  };

  static Account fromJson(JsonMap json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AccountType.values.byName(json['type'] as String),
    scope: FinanceScope.values.byName(json['scope'] as String),
    balancePaise: json['balancePaise'] as int,
    availableBalancePaise: json['availableBalancePaise'] as int?,
    creditLimitPaise: json['creditLimitPaise'] as int?,
    outstandingPaise: json['outstandingPaise'] as int? ?? 0,
    institution: json['institution'] as String?,
  );

  Account copyWith({int? balancePaise, int? outstandingPaise}) => Account(
    id: id,
    name: name,
    type: type,
    scope: scope,
    balancePaise: balancePaise ?? this.balancePaise,
    availableBalancePaise: availableBalancePaise,
    creditLimitPaise: creditLimitPaise,
    outstandingPaise: outstandingPaise ?? this.outstandingPaise,
    institution: institution,
  );
}

class FinanceTransaction {
  FinanceTransaction({
    required this.id,
    required this.type,
    required this.scope,
    required this.amountPaise,
    required this.category,
    required this.accountId,
    required this.date,
    required this.description,
    this.subcategory,
    this.paymentMethod = PaymentMethod.upi,
    this.toAccountId,
    this.tags = const [],
    this.location,
    this.isRecurring = false,
    this.status = TransactionStatus.paid,
    this.businessName,
    this.vendorName,
    this.invoiceNumber,
    this.gstPaise,
    this.isReimbursable = false,
    this.paidPersonally = false,
    this.dueDate,
    this.projectOrDepartment,
    this.personId,
    this.attachments = const [],
    AuditFields? audit,
  }) : audit = audit ?? AuditFields();

  final String id;
  final TransactionType type;
  final FinanceScope scope;
  final int amountPaise;
  final String category;
  final String? subcategory;
  final PaymentMethod paymentMethod;
  final String accountId;
  final String? toAccountId;
  final DateTime date;
  final String description;
  final List<String> tags;
  final String? location;
  final bool isRecurring;
  final TransactionStatus status;
  final String? businessName;
  final String? vendorName;
  final String? invoiceNumber;
  final int? gstPaise;
  final bool isReimbursable;
  final bool paidPersonally;
  final DateTime? dueDate;
  final String? projectOrDepartment;
  final String? personId;
  final List<Attachment> attachments;
  final AuditFields audit;

  JsonMap toJson() => {
    'id': id,
    'type': type.name,
    'scope': scope.name,
    'amountPaise': amountPaise,
    'category': category,
    'subcategory': subcategory,
    'paymentMethod': paymentMethod.name,
    'accountId': accountId,
    'toAccountId': toAccountId,
    'date': date.toIso8601String(),
    'description': description,
    'tags': tags,
    'location': location,
    'isRecurring': isRecurring,
    'status': status.name,
    'businessName': businessName,
    'vendorName': vendorName,
    'invoiceNumber': invoiceNumber,
    'gstPaise': gstPaise,
    'isReimbursable': isReimbursable,
    'paidPersonally': paidPersonally,
    'dueDate': dueDate?.toIso8601String(),
    'projectOrDepartment': projectOrDepartment,
    'personId': personId,
    'audit': audit.toJson(),
  };

  static FinanceTransaction fromJson(JsonMap json) => FinanceTransaction(
    id: json['id'] as String,
    type: TransactionType.values.byName(json['type'] as String),
    scope: FinanceScope.values.byName(json['scope'] as String),
    amountPaise: json['amountPaise'] as int,
    category: json['category'] as String,
    subcategory: json['subcategory'] as String?,
    paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
    accountId: json['accountId'] as String,
    toAccountId: json['toAccountId'] as String?,
    date: DateTime.parse(json['date'] as String),
    description: json['description'] as String,
    tags: List<String>.from(json['tags'] as List? ?? const []),
    location: json['location'] as String?,
    isRecurring: json['isRecurring'] as bool? ?? false,
    status: TransactionStatus.values.byName(json['status'] as String),
    businessName: json['businessName'] as String?,
    vendorName: json['vendorName'] as String?,
    invoiceNumber: json['invoiceNumber'] as String?,
    gstPaise: json['gstPaise'] as int?,
    isReimbursable: json['isReimbursable'] as bool? ?? false,
    paidPersonally: json['paidPersonally'] as bool? ?? false,
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    projectOrDepartment: json['projectOrDepartment'] as String?,
    personId: json['personId'] as String?,
  );
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String relationship;
}

class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.gstin,
    required this.contact,
  });

  final String id;
  final String name;
  final String gstin;
  final String contact;
}

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.type,
    required this.lenderName,
    required this.principalPaise,
    required this.interestRate,
    required this.startDate,
    required this.tenureMonths,
    required this.emiPaise,
    required this.emiDueDay,
    required this.paidEmiCount,
    required this.notes,
  });

  final String id;
  final String name;
  final LoanType type;
  final String lenderName;
  final int principalPaise;
  final double interestRate;
  final DateTime startDate;
  final int tenureMonths;
  final int emiPaise;
  final int emiDueDay;
  final int paidEmiCount;
  final String notes;

  int get remainingEmiCount => tenureMonths - paidEmiCount;
  int get totalPayablePaise => emiPaise * tenureMonths;
  int get totalInterestPaise => totalPayablePaise - principalPaise;
  int get paidPaise => emiPaise * paidEmiCount;
  int get remainingPrincipalEstimatePaise =>
      (principalPaise - paidPaise).clamp(0, principalPaise);
  double get completion => tenureMonths == 0 ? 0 : paidEmiCount / tenureMonths;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'lenderName': lenderName,
    'principalPaise': principalPaise,
    'interestRate': interestRate,
    'startDate': startDate.toIso8601String(),
    'tenureMonths': tenureMonths,
    'emiPaise': emiPaise,
    'emiDueDay': emiDueDay,
    'paidEmiCount': paidEmiCount,
    'notes': notes,
  };

  static Loan fromJson(JsonMap json) => Loan(
    id: json['id'] as String,
    name: json['name'] as String,
    type: LoanType.values.byName(json['type'] as String),
    lenderName: json['lenderName'] as String,
    principalPaise: json['principalPaise'] as int,
    interestRate: (json['interestRate'] as num).toDouble(),
    startDate: DateTime.parse(json['startDate'] as String),
    tenureMonths: json['tenureMonths'] as int,
    emiPaise: json['emiPaise'] as int,
    emiDueDay: json['emiDueDay'] as int,
    paidEmiCount: json['paidEmiCount'] as int? ?? 0,
    notes: json['notes'] as String? ?? '',
  );
}

class Payment {
  const Payment({
    required this.id,
    required this.amountPaise,
    required this.date,
    required this.method,
    required this.notes,
  });

  final String id;
  final int amountPaise;
  final DateTime date;
  final PaymentMethod method;
  final String notes;
}

class Payable {
  const Payable({
    required this.id,
    required this.personId,
    required this.amountBorrowedPaise,
    required this.amountReturnedPaise,
    required this.borrowedDate,
    required this.expectedReturnDate,
    required this.notes,
    this.payments = const [],
  });

  final String id;
  final String personId;
  final int amountBorrowedPaise;
  final int amountReturnedPaise;
  final DateTime borrowedDate;
  final DateTime expectedReturnDate;
  final String notes;
  final List<Payment> payments;

  int get remainingPaise => amountBorrowedPaise - amountReturnedPaise;
  TransactionStatus get status {
    if (remainingPaise <= 0) {
      return TransactionStatus.settled;
    }
    if (amountReturnedPaise > 0) {
      return TransactionStatus.partial;
    }
    if (DateTime.now().isAfter(expectedReturnDate)) {
      return TransactionStatus.overdue;
    }
    return TransactionStatus.pending;
  }
}

class Receivable {
  const Receivable({
    required this.id,
    required this.personId,
    required this.amountGivenPaise,
    required this.amountReceivedPaise,
    required this.givenDate,
    required this.expectedReturnDate,
    required this.notes,
    this.payments = const [],
  });

  final String id;
  final String personId;
  final int amountGivenPaise;
  final int amountReceivedPaise;
  final DateTime givenDate;
  final DateTime expectedReturnDate;
  final String notes;
  final List<Payment> payments;

  int get remainingPaise => amountGivenPaise - amountReceivedPaise;
  TransactionStatus get status {
    if (remainingPaise <= 0) {
      return TransactionStatus.settled;
    }
    if (amountReceivedPaise > 0) {
      return TransactionStatus.partial;
    }
    if (DateTime.now().isAfter(expectedReturnDate)) {
      return TransactionStatus.overdue;
    }
    return TransactionStatus.pending;
  }
}

class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.scope,
    required this.category,
    required this.period,
    required this.amountPaise,
    required this.usedPaise,
  });

  final String id;
  final String name;
  final FinanceScope scope;
  final String category;
  final String period;
  final int amountPaise;
  final int usedPaise;

  int get remainingPaise => amountPaise - usedPaise;
  double get consumed => amountPaise == 0 ? 0 : usedPaise / amountPaise;
}

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.amountPaise,
    required this.frequency,
    required this.nextRunDate,
    required this.transactionType,
  });

  final String id;
  final String name;
  final int amountPaise;
  final String frequency;
  final DateTime nextRunDate;
  final TransactionType transactionType;
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.dueAt,
    required this.amountPaise,
    required this.status,
  });

  final String id;
  final String title;
  final ReminderType type;
  final DateTime dueAt;
  final int amountPaise;
  final TransactionStatus status;
}
