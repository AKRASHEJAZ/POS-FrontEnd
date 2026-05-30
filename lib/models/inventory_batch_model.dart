class InventoryBatchStockModel {
  final int batchId;
  final double quantity;
  final double sold;
  final double damaged;
  final double returned;
  final double availableStock;

  const InventoryBatchStockModel({
    required this.batchId,
    required this.quantity,
    required this.sold,
    required this.damaged,
    required this.returned,
    required this.availableStock,
  });

  factory InventoryBatchStockModel.fromJson(Map<String, dynamic> json) {
    final quantity = InventoryBatchModel.toDouble(json['quantity']);
    final sold = InventoryBatchModel.toDouble(json['sold']);
    final damaged = InventoryBatchModel.toDouble(json['damaged']);

    return InventoryBatchStockModel(
      batchId: json['batchId'] is int
          ? json['batchId'] as int
          : int.tryParse(json['batchId']?.toString() ?? '') ?? 0,
      quantity: quantity,
      sold: sold,
      damaged: damaged,
      returned: InventoryBatchModel.toDouble(json['returned']),
      availableStock: json.containsKey('availableStock')
          ? InventoryBatchModel.toDouble(json['availableStock'])
          : quantity - sold - damaged,
    );
  }
}

class InventoryBatchModel {
  final int id;
  final int productId;
  final String? batchCode;
  final double purchasePrice;
  final double purchaseAmount;
  final double sellingPrice;
  final String? mfgDate;
  final String? expiryDate;
  final DateTime? createdAt;
  final String? productName;
  final InventoryBatchStockModel? stocks;

  const InventoryBatchModel({
    required this.id,
    required this.productId,
    this.batchCode,
    required this.purchasePrice,
    required this.purchaseAmount,
    required this.sellingPrice,
    this.mfgDate,
    this.expiryDate,
    this.createdAt,
    this.productName,
    this.stocks,
  });

  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double get availableStock => stocks?.availableStock ?? purchaseAmount;

  bool get hasAvailableStock => availableStock > 0;

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final stocksJson = json['stocks'] ?? json['Stocks'];
    final purchaseQuantity =
        json['purchasedQuantity'] ?? json['purchaseAmount'] ?? json['quantity'];

    final id = json['id'];
    final productId = json['productId'] ?? product?['id'];

    return InventoryBatchModel(
      id: id is int ? id : int.parse(id.toString()),
      productId: productId is int
          ? productId
          : int.tryParse(productId?.toString() ?? '') ?? 0,
      batchCode: json['batchCode'] as String?,
      purchasePrice: toDouble(json['purchasePrice']),
      purchaseAmount: toDouble(purchaseQuantity),
      sellingPrice: toDouble(json['sellingPrice']),
      mfgDate: json['mfgDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      productName: product?['name'] as String?,
      stocks: stocksJson is Map<String, dynamic>
          ? InventoryBatchStockModel.fromJson(stocksJson)
          : stocksJson is Map
          ? InventoryBatchStockModel.fromJson(
              Map<String, dynamic>.from(stocksJson),
            )
          : null,
    );
  }
}
