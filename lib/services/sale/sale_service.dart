import 'package:web_end/models/sale_models.dart';
import 'package:web_end/models/sale_filters.dart';
import 'package:web_end/models/sale_view_model.dart';
import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/ApiService/api_result.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class SaleCreateResult {
  final bool isSuccess;
  final String message;
  final dynamic data;

  const SaleCreateResult._({required this.isSuccess, required this.message, this.data});

  factory SaleCreateResult.success({String message = 'Sale created', dynamic data}) =>
      SaleCreateResult._(isSuccess: true, message: message, data: data);

  factory SaleCreateResult.failure(String message) =>
      SaleCreateResult._(isSuccess: false, message: message);
}

class SaleService {
  String _messageFrom(ApiResult result, String fallback) {
    final body = result.body;
    if (body is String && body.isNotEmpty) return body;
    if (body is Map) {
      final message = body['message'] ?? body['Message'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  Future<SaleCreateResult> createSale(AddSaleDto dto) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: saleCreateEndpoint,
        method: HttpMethod.post,
        body: dto.toJson(),
        authenticated: true,
      );

      if (result.statusCode == 401) {
        return SaleCreateResult.failure('Unauthorized. Please sign in again.');
      }

      if (result.isSuccess) {
        dynamic responseData;
        if (result.body is Map) {
          responseData = result.body['data'];
        }
        return SaleCreateResult.success(
          message: _messageFrom(result, 'Sale created'),
          data: responseData,
        );
      }

      return SaleCreateResult.failure(
        _messageFrom(result, 'Failed to create sale'),
      );
    } catch (_) {
      return SaleCreateResult.failure('Failed to create sale');
    }
  }

  Future<PaginatedListResult<SaleModel>> getSales({
    SaleFilters filters = const SaleFilters(),
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: saleGetEndpoint,
        method: HttpMethod.post,
        body: filters.toJson(),
        authenticated: true,
      );

      return PaginatedApiHelper.parse<SaleModel>(
        response: response,
        fromJson: SaleModel.fromJson,
        page: filters.page,
        pageSize: filters.pageSize,
        emptyHints: const ['no sale found', 'no sale'],
        fallbackError: 'Unable to load sales.',
      );
    } catch (_) {
      return PaginatedListResult.failure(
        'Unable to load sales.',
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
  }
}
