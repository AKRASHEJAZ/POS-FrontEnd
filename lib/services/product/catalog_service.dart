import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/category_filters.dart';
import 'package:web_end/models/category_model.dart';
import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/models/product_filters.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/models/unit_filters.dart';
import 'package:web_end/models/unit_model.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/ApiService/api_result.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class CatalogMutationResult {
  final bool isSuccess;
  final String message;

  const CatalogMutationResult._({required this.isSuccess, required this.message});

  factory CatalogMutationResult.success([String message = 'Success']) =>
      CatalogMutationResult._(isSuccess: true, message: message);

  factory CatalogMutationResult.failure(String message) =>
      CatalogMutationResult._(isSuccess: false, message: message);
}

class CatalogService {
  String _errorMessage(ApiResult result, String fallback) {
    if (result.body is String && (result.body as String).isNotEmpty) {
      return result.body as String;
    }
    if (result.body is Map) {
      final map = result.body as Map;
      final message = map['message'] ?? map['Message'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  String _successMessage(ApiResult result, [String fallback = 'Success']) {
    if (result.body is String && (result.body as String).isNotEmpty) {
      return result.body as String;
    }
    if (result.body is Map) {
      final map = result.body as Map;
      final message = map['message'] ?? map['Message'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  CatalogMutationResult _mutationFromResult(ApiResult result, String fallbackFail) {
    if (result.isSuccess) {
      return CatalogMutationResult.success(_successMessage(result));
    }
    return CatalogMutationResult.failure(_errorMessage(result, fallbackFail));
  }

  Future<PaginatedListResult<T>> _fetchPaginated<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) fromJson,
    required List<String> emptyHints,
    required String fallbackError,
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: endpoint,
        method: HttpMethod.post,
        body: body,
        authenticated: true,
      );

      return PaginatedApiHelper.parse<T>(
        response: response,
        fromJson: fromJson,
        page: body['page'] as int? ?? 1,
        pageSize: body['pageSize'] as int? ?? kDefaultPageSize,
        emptyHints: emptyHints,
        fallbackError: fallbackError,
      );
    } catch (_) {
      return PaginatedListResult.failure(
        fallbackError,
        page: body['page'] as int? ?? 1,
        pageSize: body['pageSize'] as int? ?? kDefaultPageSize,
      );
    }
  }

  // ——— Categories ———

  Future<PaginatedListResult<CategoryModel>> getCategoriesPaginated({
    CategoryFilters filters = const CategoryFilters(),
  }) {
    return _fetchPaginated(
      endpoint: categoryGetEndpoint,
      body: filters.toJson(),
      fromJson: CategoryModel.fromJson,
      emptyHints: const ['no categories'],
      fallbackError: 'Unable to load categories.',
    );
  }

  /// Loads up to [kPickerPageSize] categories for dropdowns (not the full table).
  Future<List<CategoryModel>> getCategoriesForPicker({String? name}) async {
    final result = await getCategoriesPaginated(
      filters: CategoryFilters(
        name: name,
        page: 1,
        pageSize: kPickerPageSize,
      ),
    );
    return result.isSuccess ? result.data.items : [];
  }

  Future<CatalogMutationResult> addCategory(String name) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: categoryAddEndpoint,
        method: HttpMethod.post,
        body: {'name': name.trim()},
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to add category');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to add category');
    }
  }

  Future<CatalogMutationResult> updateCategory(int id, String name) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: categoryUpdateEndpoint(id),
        method: HttpMethod.put,
        body: {'name': name.trim()},
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to update category');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to update category');
    }
  }

  Future<CatalogMutationResult> deleteCategory(int id) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: categoryDeleteEndpoint(id),
        method: HttpMethod.delete,
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to delete category');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to delete category');
    }
  }

  // ——— Units ———

  Future<PaginatedListResult<UnitModel>> getUnitsPaginated({
    UnitFilters filters = const UnitFilters(),
  }) {
    return _fetchPaginated(
      endpoint: unitGetEndpoint,
      body: filters.toJson(),
      fromJson: UnitModel.fromJson,
      emptyHints: const ['no units'],
      fallbackError: 'Unable to load units.',
    );
  }

  Future<List<UnitModel>> getUnitsForPicker({String? name}) async {
    final result = await getUnitsPaginated(
      filters: UnitFilters(
        name: name,
        page: 1,
        pageSize: kPickerPageSize,
      ),
    );
    return result.isSuccess ? result.data.items : [];
  }

  Future<CatalogMutationResult> addUnit(String name, String symbol) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: unitAddEndpoint,
        method: HttpMethod.post,
        body: {'name': name.trim(), 'symbol': symbol.trim()},
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to add unit');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to add unit');
    }
  }

  Future<CatalogMutationResult> updateUnit(int id, String name, String symbol) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: unitUpdateEndpoint(id),
        method: HttpMethod.put,
        body: {'name': name.trim(), 'symbol': symbol.trim()},
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to update unit');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to update unit');
    }
  }

  Future<CatalogMutationResult> deleteUnit(int id) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: unitDeleteEndpoint(id),
        method: HttpMethod.delete,
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to delete unit');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to delete unit');
    }
  }

  // ——— Products ———

  Future<PaginatedListResult<ProductModel>> getProductsPaginated({
    ProductFilters filters = const ProductFilters(),
  }) {
    return _fetchPaginated(
      endpoint: productGetEndpoint,
      body: filters.toJson(),
      fromJson: ProductModel.fromJson,
      emptyHints: const ['no products'],
      fallbackError: 'Unable to load products.',
    );
  }

  Future<CatalogMutationResult> addProduct({
    required String name,
    required int categoryId,
    required int unitId,
    String? internalCode,
    bool isActive = true,
    bool isSellable = true,
    bool isPurchasable = true,
    bool doesExpire = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'categoryId': categoryId,
        'unitId': unitId,
        'isActive': isActive,
        'isSellable': isSellable,
        'isPurchasable': isPurchasable,
        'doesExpire': doesExpire,
      };
      final code = internalCode?.trim();
      if (code != null && code.isNotEmpty) {
        body['internalCode'] = code;
      }

      final result = await ApiService.requestWithStatus(
        endpoint: productAddEndpoint,
        method: HttpMethod.post,
        body: body,
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to add product');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to add product');
    }
  }

  Future<CatalogMutationResult> updateProduct({
    required int id,
    required String name,
    required int categoryId,
    required int unitId,
    String? internalCode,
    required bool isActive,
    required bool isSellable,
    required bool isPurchasable,
    required bool doesExpire,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'categoryId': categoryId,
        'unitId': unitId,
        'isActive': isActive,
        'isSellable': isSellable,
        'isPurchasable': isPurchasable,
        'doesExpire': doesExpire,
      };
      final code = internalCode?.trim();
      if (code != null && code.isNotEmpty) {
        body['internalCode'] = code;
      }

      final result = await ApiService.requestWithStatus(
        endpoint: productUpdateEndpoint(id),
        method: HttpMethod.put,
        body: body,
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to update product');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to update product');
    }
  }

  Future<CatalogMutationResult> deleteProduct(int id) async {
    try {
      final result = await ApiService.requestWithStatus(
        endpoint: productDeleteEndpoint(id),
        method: HttpMethod.delete,
        authenticated: true,
      );
      return _mutationFromResult(result, 'Failed to delete product');
    } catch (_) {
      return CatalogMutationResult.failure('Failed to delete product');
    }
  }
}
