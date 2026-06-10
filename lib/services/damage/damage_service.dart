import 'package:web_end/models/damage_filters.dart';
import 'package:web_end/models/damage_view_model.dart';
import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/models/sale_models.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/ApiService/api_result.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class DamageCreateResult {
  final bool isSuccess;
  final String message;

  const DamageCreateResult._({required this.isSuccess, required this.message});

  factory DamageCreateResult.success([String message = 'Damage recorded']) =>
      DamageCreateResult._(isSuccess: true, message: message);

  factory DamageCreateResult.failure(String message) =>
      DamageCreateResult._(isSuccess: false, message: message);
}

class DamageService {
  String _messageFrom(ApiResult result, String fallback) {
    final body = result.body;
    if (body is String && body.isNotEmpty) return body;
    if (body is Map) {
      final message = body['message'] ?? body['Message'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  Future<DamageCreateResult> createDamage(AddDamageDto dto) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: damageCreateEndpoint,
        method: HttpMethod.post,
        body: dto.toJson(),
        authenticated: true,
      );

      if (result.statusCode == 401 || result.statusCode == 403) {
        return DamageCreateResult.failure(
          'Only an authorized admin can record damage.',
        );
      }

      if (result.isSuccess) {
        return DamageCreateResult.success(
          _messageFrom(result, 'Damage recorded'),
        );
      }

      return DamageCreateResult.failure(
        _messageFrom(result, 'Failed to record damage'),
      );
    } catch (_) {
      return DamageCreateResult.failure('Failed to record damage');
    }
  }

  Future<PaginatedListResult<DamageModel>> getDamages({
    DamageFilters filters = const DamageFilters(),
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: damageGetEndpoint,
        method: HttpMethod.post,
        body: filters.toJson(),
        authenticated: true,
      );

      return PaginatedApiHelper.parse<DamageModel>(
        response: response,
        fromJson: DamageModel.fromJson,
        page: filters.page,
        pageSize: filters.pageSize,
        emptyHints: const ['no damage record found', 'no damage'],
        fallbackError: 'Unable to load damage records.',
      );
    } catch (_) {
      return PaginatedListResult.failure(
        'Unable to load damage records.',
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
  }
}
