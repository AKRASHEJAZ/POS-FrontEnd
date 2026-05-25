import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/models/paginated_result.dart';

class PaginatedApiHelper {
  static bool isEmptyListMessage(String message, List<String> hints) {
    final lower = message.toLowerCase();
    for (final hint in hints) {
      if (lower.contains(hint.toLowerCase())) return true;
    }
    return false;
  }

  static PaginatedListResult<T> parse<T>({
    required dynamic response,
    required T Function(Map<String, dynamic>) fromJson,
    required int page,
    required int pageSize,
    required List<String> emptyHints,
    String fallbackError = 'Unable to load data.',
  }) {
    if (response is! Map) {
      return PaginatedListResult.failure(
        fallbackError,
        page: page,
        pageSize: pageSize,
      );
    }

    final map = Map<String, dynamic>.from(response);
    final code = map['code'] as int? ?? 0;
    final message = map['message'] as String? ?? fallbackError;
    final data = map['data'];

    if (code == 200 && data is Map) {
      return PaginatedListResult.success(
        PaginatedResult.fromJson(
          Map<String, dynamic>.from(data),
          fromJson,
        ),
      );
    }

    if (code == 404 || isEmptyListMessage(message, emptyHints)) {
      return PaginatedListResult.success(
        PaginatedResult.empty(page: page, pageSize: pageSize),
      );
    }

    return PaginatedListResult.failure(
      message.isNotEmpty ? message : fallbackError,
      page: page,
      pageSize: pageSize,
    );
  }
}
