class ProductStockModel {
  final int id;
  final String name;
  final String? category;
  final String? unit;
  final double purchasedAmount;
  final double soldAmount;
  final double damagedAmount;
  final double returnedAmount;
  final double availableStock;

  const ProductStockModel({
    required this.id,
    required this.name,
    this.category,
    this.unit,
    required this.purchasedAmount,
    required this.soldAmount,
    required this.damagedAmount,
    required this.returnedAmount,
    required this.availableStock,
  });

  factory ProductStockModel.fromJson(Map<String, dynamic> json) {
    return ProductStockModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      category: (json['category'] ?? json['Category']) as String?,
      unit: (json['unit'] ?? json['Unit']) as String?,
      purchasedAmount: toDouble(json['purchasedAmount'] ?? json['PurchasedAmount']),
      soldAmount: toDouble(json['soldAmount'] ?? json['SoldAmount']),
      damagedAmount: toDouble(json['damagedAmount'] ?? json['DamagedAmount']),
      returnedAmount: toDouble(json['returnedAmount'] ?? json['ReturnedAmount']),
      availableStock: toDouble(json['availableStock'] ?? json['AvailableStock']),
    );
  }

  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
