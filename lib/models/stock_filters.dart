import 'package:web_end/models/product_model.dart';

class StockFilters {
  final String? batchCode;
  final int? productId;
  final int page;
  final int pageSize;

  const StockFilters({
    this.batchCode,
    this.productId,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (batchCode != null && batchCode!.trim().isNotEmpty) {
      map['batchCode'] = [batchCode!.trim()];
    }
    if (productId != null) {
      map['productId'] = [productId];
    }

    return map;
  }

  factory StockFilters.fromForm({
    required String batchCode,
    ProductModel? product,
    int page = 1,
    int pageSize = 10,
  }) {
    return StockFilters(
      batchCode: batchCode.trim().isEmpty ? null : batchCode.trim(),
      productId: product?.id,
      page: page,
      pageSize: pageSize,
    );
  }
}
