class InvoiceLine {
  final int? id;
  final String sku;
  final String name;
  final double quantity;
  final double price;
  final double discount;
  final double taxRate; // default 0.15 for 15% VAT
  final double taxAmount;
  final double totalAmount;

  InvoiceLine({
    this.id,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    this.taxRate = 0.15,
    required this.taxAmount,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
    };
  }

  factory InvoiceLine.fromMap(Map<String, dynamic> map) {
    return InvoiceLine(
      id: map['id'] as int?,
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num? ?? 1.0).toDouble(),
      price: (map['price'] as num? ?? 0.0).toDouble(),
      discount: (map['discount'] as num? ?? 0.0).toDouble(),
      taxRate: (map['tax_rate'] as num? ?? 0.15).toDouble(),
      taxAmount: (map['tax_amount'] as num? ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] as num? ?? 0.0).toDouble(),
    );
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final int? contactId;
  final String date;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentType; // CASH, BANK, CREDITOR
  final int? warehouseId;
  final List<InvoiceLine> lines;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.contactId,
    required this.date,
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentType,
    this.warehouseId,
    this.lines = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'contact_id': contactId,
      'invoice_date': date,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_type': paymentType,
      'warehouse_id': warehouseId,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceLine> lines = const []}) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] ?? '',
      contactId: map['contact_id'] as int?,
      date: map['invoice_date'] ?? '',
      subtotal: (map['subtotal'] as num? ?? 0.0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0.0).toDouble(),
      taxAmount: (map['tax_amount'] as num? ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] as num? ?? 0.0).toDouble(),
      paymentType: map['payment_type'] ?? 'CASH',
      warehouseId: map['warehouse_id'] as int?,
      lines: lines,
    );
  }
}
