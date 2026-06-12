class InventoryItem {
  final int? id;
  final String sku;
  final String name;
  final double salePrice;
  final double purchasePrice;
  final double quantityInStock;
  final int? warehouseId;

  InventoryItem({
    this.id,
    required this.sku,
    required this.name,
    required this.salePrice,
    required this.purchasePrice,
    this.quantityInStock = 0.0,
    this.warehouseId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'name': name,
      'sale_price': salePrice,
      'purchase_price': purchasePrice,
      'quantity_in_stock': quantityInStock,
      'warehouse_id': warehouseId,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      salePrice: (map['sale_price'] as num? ?? 0.0).toDouble(),
      purchasePrice: (map['purchase_price'] as num? ?? 0.0).toDouble(),
      quantityInStock: (map['quantity_in_stock'] as num? ?? 0.0).toDouble(),
      warehouseId: map['warehouse_id'] as int?,
    );
  }
}
