import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/models/return_filters.dart';
import 'package:web_end/models/return_view_model.dart';
import 'package:web_end/models/sale_models.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/ApiService/api_result.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class ReturnCreateResult {
  final bool isSuccess;
  final String message;

  const ReturnCreateResult._({
    required this.isSuccess,
    required this.message,
  });

  factory ReturnCreateResult.success([String message = 'Return recorded']) =>
      ReturnCreateResult._(isSuccess: true, message: message);

  factory ReturnCreateResult.failure(String message) =>
      ReturnCreateResult._(isSuccess: false, message: message);
}

class ReturnService {
  String _messageFrom(ApiResult result, String fallback) {
    final body = result.body;
    if (body is String && body.isNotEmpty) return body;
    if (body is Map) {
      final message = body['message'] ?? body['Message'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  Future<ReturnCreateResult> createReturn(AddReturnDto dto) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: returnCreateEndpoint,
        method: HttpMethod.post,
        body: dto.toJson(),
        authenticated: true,
      );

      if (result.statusCode == 401) {
        return ReturnCreateResult.failure('Unauthorized. Please sign in again.');
      }

      if (result.isSuccess) {
        return ReturnCreateResult.success(
          _messageFrom(result, 'Return recorded'),
        );
      }

      return ReturnCreateResult.failure(
        _messageFrom(result, 'Failed to record return'),
      );
    } catch (_) {
      return ReturnCreateResult.failure('Failed to record return');
    }
  }

  Future<PaginatedListResult<ReturnModel>> getReturns({
    ReturnFilters filters = const ReturnFilters(),
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: returnGetEndpoint,
        method: HttpMethod.post,
        body: filters.toJson(),
        authenticated: true,
      );

      return PaginatedApiHelper.parse<ReturnModel>(
        response: response,
        fromJson: ReturnModel.fromJson,
        page: filters.page,
        pageSize: filters.pageSize,
        emptyHints: const ['no return record found', 'no return', 'no damage'],
        fallbackError: 'Unable to load return records.',
      );
    } catch (_) {
      return PaginatedListResult.failure(
        'Unable to load return records.',
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
  }
}
