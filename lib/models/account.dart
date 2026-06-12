class Account {
  final String accountCode;
  final String nameAr;
  final String nameEn;
  final String accountType; // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
  final bool isDebitNormal; // true/false
  final double balance;
  final String? parentCode;
  final int level;

  Account({
    required this.accountCode,
    required this.nameAr,
    required this.nameEn,
    required this.accountType,
    required this.isDebitNormal,
    this.balance = 0.0,
    this.parentCode,
    this.level = 1,
  });

  // Convert Account to Map for SQLite database insertion
  Map<String, dynamic> toMap() {
    return {
      'account_code': accountCode,
      'name_ar': nameAr,
      'name_en': nameEn,
      'account_type': accountType,
      'is_debit_normal': isDebitNormal ? 1 : 0,
      'balance': balance,
      'parent_code': parentCode,
      'level_depth': level,
    };
  }

  // Create an Account object from a Database Map row
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      accountCode: map['account_code'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] ?? '',
      accountType: map['account_type'] as String,
      isDebitNormal: (map['is_debit_normal'] as int) == 1,
      balance: (map['balance'] as num).toDouble(),
      parentCode: map['parent_code'] as String?,
      level: map['level_depth'] as int? ?? 1,
    );
  }

  // Create a copy with modified fields
  Account copyWith({
    String? accountCode,
    String? nameAr,
    String? nameEn,
    String? accountType,
    bool? isDebitNormal,
    double? balance,
    String? parentCode,
    int? level,
  }) {
    return Account(
      accountCode: accountCode ?? this.accountCode,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      accountType: accountType ?? this.accountType,
      isDebitNormal: isDebitNormal ?? this.isDebitNormal,
      balance: balance ?? this.balance,
      parentCode: parentCode ?? this.parentCode,
      level: level ?? this.level,
    );
  }
}
