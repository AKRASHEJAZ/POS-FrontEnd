import 'package:web_end/models/customer_model.dart';
import 'package:web_end/models/user_model.dart';

T? _read<T>(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k)) return json[k] as T?;
  }
  return null;
}

class SaleProductModel {
  final int id;
  final String name;
  final String? internalCode;
  final String? categoryName;
  final String? unitName;
  final String? unitSymbol;

  const SaleProductModel({
    required this.id,
    required this.name,
    this.internalCode,
    this.categoryName,
    this.unitName,
    this.unitSymbol,
  });

  factory SaleProductModel.fromJson(Map<String, dynamic> json) {
    final category = _read<Map<String, dynamic>>(json, ['category', 'Category']);
    final unit = _read<Map<String, dynamic>>(json, ['unit', 'Unit']);
    return SaleProductModel(
      id: (_read<num>(json, ['id', 'Id']) ?? 0).toInt(),
      name: (_read<String>(json, ['name', 'Name']) ?? '').toString(),
      internalCode: _read<String>(json, ['internalCode', 'InternalCode']),
      categoryName: category != null
          ? (category['name'] ?? category['Name'])?.toString()
          : null,
      unitName:
          unit != null ? (unit['name'] ?? unit['Name'])?.toString() : null,
      unitSymbol:
          unit != null ? (unit['symbol'] ?? unit['Symbol'])?.toString() : null,
    );
  }
}

class SaleInventoryBatchModel {
  final int id;
  final String? batchCode;
  final double sellingPrice;
  final double purchasedQuantity;
  final SaleProductModel? product;

  const SaleInventoryBatchModel({
    required this.id,
    this.batchCode,
    required this.sellingPrice,
    required this.purchasedQuantity,
    this.product,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory SaleInventoryBatchModel.fromJson(Map<String, dynamic> json) {
    final productJson = _read<Map<String, dynamic>>(json, ['product', 'Product']);
    return SaleInventoryBatchModel(
      id: (_read<num>(json, ['id', 'Id']) ?? 0).toInt(),
      batchCode: _read<String>(json, ['batchCode', 'BatchCode']),
      sellingPrice: _toDouble(_read<dynamic>(json, ['sellingPrice', 'SellingPrice'])),
      purchasedQuantity:
          _toDouble(_read<dynamic>(json, ['purchasedQuantity', 'PurchasedQuantity'])),
      product: productJson == null ? null : SaleProductModel.fromJson(productJson),
    );
  }
}

class SaleActionModel {
  final int id;
  final int inventoryBatchId;
  final double quantity;
  final String? notes;
  final SaleInventoryBatchModel? inventoryBatch;

  const SaleActionModel({
    required this.id,
    required this.inventoryBatchId,
    required this.quantity,
    this.notes,
    this.inventoryBatch,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory SaleActionModel.fromJson(Map<String, dynamic> json) {
    final batchJson =
        _read<Map<String, dynamic>>(json, ['inventoryBatch', 'InventoryBatch']);
    return SaleActionModel(
      id: (_read<num>(json, ['id', 'Id']) ?? 0).toInt(),
      inventoryBatchId:
          (_read<num>(json, ['inventoryBatchId', 'InventoryBatchId']) ?? 0).toInt(),
      quantity: _toDouble(_read<dynamic>(json, ['quantity', 'Quantity'])),
      notes: _read<String>(json, ['notes', 'Notes']),
      inventoryBatch:
          batchJson == null ? null : SaleInventoryBatchModel.fromJson(batchJson),
    );
  }

  double get lineTotal =>
      (inventoryBatch?.sellingPrice ?? 0) * (quantity);
}

class SaleModel {
  final int id;
  final int? customerId;
  final double totalAmount;
  final DateTime? saleDate;
  final UserModel? createdBy;
  final CustomerModel? customer;
  final List<SaleActionModel> actions;

  const SaleModel({
    required this.id,
    this.customerId,
    required this.totalAmount,
    this.saleDate,
    this.createdBy,
    this.customer,
    this.actions = const [],
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final createdByJson = _read<Map<String, dynamic>>(json, ['createdBy', 'CreatedBy']);
    final customerJson = _read<Map<String, dynamic>>(json, ['customer', 'Customer']);
    final actionsJson = _read<List>(json, ['actions', 'Actions']);
    return SaleModel(
      id: (_read<num>(json, ['id', 'Id']) ?? 0).toInt(),
      customerId: (_read<num>(json, ['customerId', 'CustomerId']))?.toInt(),
      totalAmount: _toDouble(_read<dynamic>(json, ['totalAmount', 'TotalAmount'])),
      saleDate: (_read<dynamic>(json, ['saleDate', 'SaleDate']) != null)
          ? DateTime.tryParse(
              _read<dynamic>(json, ['saleDate', 'SaleDate']).toString(),
            )
          : null,
      createdBy: createdByJson == null ? null : UserModel.fromJson(createdByJson),
      customer: customerJson == null ? null : CustomerModel.fromJson(customerJson),
      actions: actionsJson == null
          ? const []
          : actionsJson
              .whereType<Map>()
              .map((e) => SaleActionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }
}

