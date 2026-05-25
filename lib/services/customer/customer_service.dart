import 'package:web_end/models/customer_filters.dart';
import 'package:web_end/models/customer_model.dart';
import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class CustomerMutationResult {
  final bool isSuccess;
  final String message;
  final CustomerModel? customer;

  const CustomerMutationResult._({
    required this.isSuccess,
    required this.message,
    this.customer,
  });

  factory CustomerMutationResult.success(
    String message, {
    CustomerModel? customer,
  }) =>
      CustomerMutationResult._(
        isSuccess: true,
        message: message,
        customer: customer,
      );

  factory CustomerMutationResult.failure(String message) =>
      CustomerMutationResult._(isSuccess: false, message: message);
}

class CustomerService {
  Future<PaginatedListResult<CustomerModel>> getCustomers({
    CustomerFilters filters = const CustomerFilters(),
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: customerGetEndpoint,
        method: HttpMethod.post,
        body: filters.toJson(),
        authenticated: true,
      );

      return PaginatedApiHelper.parse<CustomerModel>(
        response: response,
        fromJson: CustomerModel.fromJson,
        page: filters.page,
        pageSize: filters.pageSize,
        emptyHints: const ['no customers'],
        fallbackError: 'Unable to load customers.',
      );
    } catch (_) {
      return PaginatedListResult.failure(
        'Unable to load customers.',
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
  }

  Future<CustomerMutationResult> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    bool isWalkIn = false,
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: customerAddEndpoint,
        method: HttpMethod.post,
        body: {
          'name': name.trim(),
          'phone': phone?.trim(),
          'email': email?.trim(),
          'address': address?.trim(),
          'isWalkIn': isWalkIn,
        },
        authenticated: true,
      );

      if (response is Map<String, dynamic>) {
        final code = response['code'] as int? ?? 0;
        final message =
            response['message'] as String? ?? 'Failed to add customer';

        if ((code == 200 || code == 201) && response['data'] is Map) {
          final customer = CustomerModel.fromJson(
            Map<String, dynamic>.from(response['data'] as Map),
          );
          return CustomerMutationResult.success(message, customer: customer);
        }

        return CustomerMutationResult.failure(message);
      }

      // Fallback if API returns the DTO directly.
      if (response is Map && response.containsKey('id')) {
        final customer =
            CustomerModel.fromJson(Map<String, dynamic>.from(response));
        return CustomerMutationResult.success('Customer added', customer: customer);
      }

      return CustomerMutationResult.failure('Failed to add customer');
    } catch (_) {
      return CustomerMutationResult.failure('Failed to add customer');
    }
  }
}

