import 'package:web_end/services/ApiService/Api.dart';
import 'package:web_end/services/allApis.dart';
import 'package:web_end/services/storage/token_storage.dart';

class AuthService {
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.request(
        endpoint: loginEndpoint,
        method: HttpMethod.post,
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      final code = response['code'] as int? ?? 0;
      final message = response['message'] as String? ?? 'Something went wrong';

      if (code == 200 && response['data'] != null) {
        final token = response['data'] as String;
        await TokenStorage.saveToken(token);
        return LoginResult.success(message);
      }

      return LoginResult.failure(message);
    } catch (e) {
      return LoginResult.failure('Unable to reach server. Please try again.');
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
  }
}

class LoginResult {
  final bool isSuccess;
  final String message;

  const LoginResult._({required this.isSuccess, required this.message});

  factory LoginResult.success(String message) =>
      LoginResult._(isSuccess: true, message: message);

  factory LoginResult.failure(String message) =>
      LoginResult._(isSuccess: false, message: message);
}
