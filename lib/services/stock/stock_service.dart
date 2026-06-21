import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/models/product_stock_model.dart';
import 'package:web_end/models/stock_filters.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class StockMutationResult {
  final bool isSuccess;
  final String message;
  final InventoryBatchModel? batch;

  const StockMutationResult._({
    required this.isSuccess,
    required this.message,
    this.batch,
  });

  factory StockMutationResult.success(
    String message, {
    InventoryBatchModel? batch,
  }) =>
      StockMutationResult._(
        isSuccess: true,
        message: message,
        batch: batch,
      );

  factory StockMutationResult.failure(String message) =>
      StockMutationResult._(isSuccess: false, message: message);
}

class StockService {
  Future<PaginatedListResult<InventoryBatchModel>> getBatches({
    StockFilters filters = const StockFilters(),
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: stockGetEndpoint,
        method: HttpMethod.post,
        body: filters.toJson(),
        authenticated: true,
      );

      return PaginatedApiHelper.parse<InventoryBatchModel>(
        response: response,
        fromJson: InventoryBatchModel.fromJson,
        page: filters.page,
        pageSize: filters.pageSize,
        emptyHints: const ['no batches'],
        fallbackError: 'Unable to load stock.',
      );
    } catch (_) {
      return PaginatedListResult.failure(
        'Unable to load stock.',
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
  }

  /// Returns a flat list of per-product stock totals.
  /// Sends one request with a large pageSize so all products come back
  /// in a single call; local filtering/pagination is done on the FE.
  Future<({bool isSuccess, String message, List<ProductStockModel> data})>
  getProductStock() async {
    try {
      final response = await ApiService.request(
        endpoint: productStockGetEndpoint,
        method: HttpMethod.post,
        body: {'page': 1, 'pageSize': 1000},
        authenticated: true,
      );

      if (response is Map<String, dynamic>) {
        final code = response['code'] as int? ?? 0;
        final message = response['message'] as String? ?? 'Unknown error';

        if (code == 200 && response['data'] != null) {
          final rawList = response['data'] as List<dynamic>;
          final items = rawList
              .map((e) => ProductStockModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return (isSuccess: true, message: message, data: items);
        }

        return (isSuccess: false, message: message, data: <ProductStockModel>[]);
      }

      return (isSuccess: false, message: 'Unexpected response', data: <ProductStockModel>[]);
    } catch (_) {
      return (
        isSuccess: false,
        message: 'Unable to load product stock.',
        data: <ProductStockModel>[],
      );
    }
  }

  Future<StockMutationResult> addBatch({
    required int productId,
    required double purchasePrice,
    required double sellingPrice,
    required double purchasedQuantity,
    DateTime? mfgDate,
    DateTime? expiryDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'productId': productId,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'purchasedQuantity': purchasedQuantity,
      };

      if (mfgDate != null) {
        body['mfgDate'] = _dateOnly(mfgDate);
      }
      if (expiryDate != null) {
        body['expiryDate'] = _dateOnly(expiryDate);
      }

      final response = await ApiService.request(
        endpoint: stockAddEndpoint,
        method: HttpMethod.post,
        body: body,
        authenticated: true,
      );

      if (response is Map<String, dynamic>) {
        final code = response['code'] as int? ?? 0;
        final message =
            response['message'] as String? ?? 'Failed to add stock batch';

        if (code == 200 && response['data'] != null) {
          final dataMap = response['data'] as Map<String, dynamic>;
          final batch = InventoryBatchModel.fromJson(dataMap);
          final batchCode = batch.batchCode;
          final msg = batchCode != null && batchCode.isNotEmpty
              ? 'Stock batch added ($batchCode)'
              : message;
          return StockMutationResult.success(msg, batch: batch);
        }

        if (message.isNotEmpty) {
          return StockMutationResult.failure(message);
        }
      }

      // Fallback if API returns the DTO directly on success.
      if (response is Map && response.containsKey('id')) {
        final batch = InventoryBatchModel.fromJson(
          Map<String, dynamic>.from(response),
        );
        final batchCode = batch.batchCode;
        final msg = batchCode != null && batchCode.isNotEmpty
            ? 'Stock batch added ($batchCode)'
            : 'Stock batch added';
        return StockMutationResult.success(msg, batch: batch);
      }

      return StockMutationResult.failure('Failed to add stock batch');
    } catch (_) {
      return StockMutationResult.failure('Failed to add stock batch');
    }
  }

  String _dateOnly(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
