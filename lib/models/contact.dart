class Contact {
  final int? id;
  final String name;
  final String type; // CLIENT, SUPPLIER
  final String? phone;
  final String? email;
  final String? taxNumber;
  final double openingBalance;
  final double currentBalance;

  Contact({
    this.id,
    required this.name,
    required this.type,
    this.phone,
    this.email,
    this.taxNumber,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'email': email,
      'tax_number': taxNumber,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      type: map['type'] ?? 'CLIENT',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      taxNumber: map['tax_number'] as String?,
      openingBalance: (map['opening_balance'] ?? 0.0) as double,
      currentBalance: (map['current_balance'] ?? 0.0) as double,
    );
  }
}
