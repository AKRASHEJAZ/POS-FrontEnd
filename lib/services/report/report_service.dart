import 'package:web_end/models/count_data_model.dart';
import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/models/paginated_result.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/allApis.dart';

class ReportService {
  /// GET /api/report/GetCount — summary counts
  Future<({bool isSuccess, String message, CountDataModel? data})>
      getCountData() async {
    try {
      final response = await ApiService.request(
        endpoint: reportGetCountEndpoint,
        method: HttpMethod.get,
        authenticated: true,
      );

      if (response is Map<String, dynamic>) {
        final code = response['code'] as int? ?? 0;
        final message = response['message'] as String? ?? 'Unknown error';
        if (code == 200 && response['data'] != null) {
          return (
            isSuccess: true,
            message: message,
            data: CountDataModel.fromJson(
              response['data'] as Map<String, dynamic>,
            ),
          );
        }
        return (isSuccess: false, message: message, data: null);
      }
      return (isSuccess: false, message: 'Unexpected response', data: null);
    } catch (_) {
      return (isSuccess: false, message: 'Unable to load report.', data: null);
    }
  }

  /// POST /api/report/GetExpiredProducts — paginated expired batches with stock
  Future<PaginatedResult<InventoryBatchModel>> getExpiredProducts({
    required DateTime beforeDate,
    List<int> productIds = const [],
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final body = <String, dynamic>{
        'date': beforeDate.toIso8601String(),
        'productIds': productIds,
        'page': page,
        'pageSize': pageSize,
      };

      final response = await ApiService.request(
        endpoint: reportGetExpiredEndpoint,
        method: HttpMethod.post,
        body: body,
        authenticated: true,
      );

      if (response is Map<String, dynamic>) {
        final code = response['code'] as int? ?? 0;

        if (code == 200 && response['data'] != null) {
          final dataMap = response['data'] as Map<String, dynamic>;
          return PaginatedResult.fromJson(
            dataMap,
            InventoryBatchModel.fromJson,
          );
        }

        return PaginatedResult.empty(page: page, pageSize: pageSize);
      }

      return PaginatedResult.empty(page: page, pageSize: pageSize);
    } catch (_) {
      return PaginatedResult.empty(page: page, pageSize: pageSize);
    }
  }
}
