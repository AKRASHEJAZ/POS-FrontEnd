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
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final purchaseQuantity = json['purchasedQuantity'] ??
        json['purchaseAmount'] ??
        json['quantity'];

    final id = json['id'];
    final productId = json['productId'] ?? product?['id'];

    return InventoryBatchModel(
      id: id is int ? id : int.parse(id.toString()),
      productId: productId is int
          ? productId
          : int.tryParse(productId?.toString() ?? '') ?? 0,
      batchCode: json['batchCode'] as String?,
      purchasePrice: _toDouble(json['purchasePrice']),
      purchaseAmount: _toDouble(purchaseQuantity),
      sellingPrice: _toDouble(json['sellingPrice']),
      mfgDate: json['mfgDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      productName: product?['name'] as String?,
    );
  }
}
