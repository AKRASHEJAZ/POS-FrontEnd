import 'package:web_end/models/paginated_result.dart';

class PaginatedListResult<T> {
  final bool isSuccess;
  final String message;
  final PaginatedResult<T> data;

  const PaginatedListResult._({
    required this.isSuccess,
    required this.message,
    required this.data,
  });

  factory PaginatedListResult.success(PaginatedResult<T> data) =>
      PaginatedListResult._(
        isSuccess: true,
        message: '',
        data: data,
      );

  factory PaginatedListResult.failure(
    String message, {
    required int page,
    required int pageSize,
  }) =>
      PaginatedListResult._(
        isSuccess: false,
        message: message,
        data: PaginatedResult.empty(page: page, pageSize: pageSize),
      );
}
