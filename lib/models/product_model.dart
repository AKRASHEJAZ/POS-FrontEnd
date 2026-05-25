class ProductModel {
  final int id;
  final String name;
  final int categoryId;
  final int unitId;
  final String? internalCode;
  final bool isActive;
  final bool isSellable;
  final bool isPurchasable;
  final bool doesExpire;
  final String? categoryName;
  final String? unitName;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unitId,
    this.internalCode,
    this.isActive = true,
    this.isSellable = true,
    this.isPurchasable = true,
    this.doesExpire = false,
    this.categoryName,
    this.unitName,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final unit = json['unit'] as Map<String, dynamic>?;

    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as int? ?? category?['id'] as int? ?? 0,
      unitId: json['unitId'] as int? ?? unit?['id'] as int? ?? 0,
      internalCode: json['internalCode'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isSellable: json['isSellable'] as bool? ?? true,
      isPurchasable: json['isPurchasable'] as bool? ?? true,
      doesExpire: json['doesExpire'] as bool? ?? false,
      categoryName: category?['name'] as String?,
      unitName: unit?['name'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
