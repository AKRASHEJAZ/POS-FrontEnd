import 'package:web_end/models/paginated_list_result.dart';
import 'package:web_end/models/user_filters.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/api/paginated_api_helper.dart';

class UserService {
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiService.request(
        endpoint: currentUserEndpoint,
        method: HttpMethod.post,
        authenticated: true,
      );

      final code = response['code'] as int? ?? 0;
      if (code == 200 && response['data'] != null) {
        return UserModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PaginatedListResult<UserModel>> getAllUsers({
    UserFilters filters = const UserFilters(),
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: getAllUsersEndpoint,
        method: HttpMethod.post,
        body: filters.toJson(),
        authenticated: true,
      );

      return PaginatedApiHelper.parse<UserModel>(
        response: response,
        fromJson: UserModel.fromJson,
        page: filters.page,
        pageSize: filters.pageSize,
        emptyHints: const ['no users'],
        fallbackError: 'Unable to load users. Please try again.',
      );
    } catch (_) {
      return PaginatedListResult.failure(
        'Unable to load users. Please try again.',
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
  }

  Future<CreateUserResult> createUser({
    required String name,
    required String email,
    required String password,
    required int roleId,
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: addUserEndpoint,
        method: HttpMethod.post,
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'roleId': roleId,
        },
        authenticated: true,
      );

      final code = response['code'] as int? ?? 0;
      final message = response['message'] as String? ?? 'Failed to create user';

      if (code == 201 || code == 200) {
        return CreateUserResult.success(message);
      }

      return CreateUserResult.failure(message);
    } catch (_) {
      return CreateUserResult.failure('Unable to create user. Please try again.');
    }
  }

  Future<UserMutationResult> updateUser({
    required int id,
    required String name,
    required String email,
    required int roleId,
    required bool isActive,
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: updateUserEndpoint(id),
        method: HttpMethod.put,
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'roleId': roleId,
          'isActive': isActive,
        },
        authenticated: true,
      );

      final code = response['code'] as int? ?? 0;
      final message = response['message'] as String? ?? 'Failed to update user';

      if (code == 200) {
        return UserMutationResult.success(message);
      }

      return UserMutationResult.failure(message);
    } catch (_) {
      return UserMutationResult.failure('Unable to update user. Please try again.');
    }
  }

  Future<UserMutationResult> deleteUser(int id) async {
    try {
      final response = await ApiService.request(
        endpoint: deleteUserEndpoint(id),
        method: HttpMethod.delete,
        authenticated: true,
      );

      final code = response['code'] as int? ?? 0;
      final message = response['message'] as String? ?? 'Failed to delete user';

      if (code == 200) {
        return UserMutationResult.success(message);
      }

      return UserMutationResult.failure(message);
    } catch (_) {
      return UserMutationResult.failure('Unable to delete user. Please try again.');
    }
  }
}

class UserMutationResult {
  final bool isSuccess;
  final String message;

  const UserMutationResult._({required this.isSuccess, required this.message});

  factory UserMutationResult.success(String message) =>
      UserMutationResult._(isSuccess: true, message: message);

  factory UserMutationResult.failure(String message) =>
      UserMutationResult._(isSuccess: false, message: message);
}

class CreateUserResult {
  final bool isSuccess;
  final String message;

  const CreateUserResult._({required this.isSuccess, required this.message});

  factory CreateUserResult.success(String message) =>
      CreateUserResult._(isSuccess: true, message: message);

  factory CreateUserResult.failure(String message) =>
      CreateUserResult._(isSuccess: false, message: message);
}
