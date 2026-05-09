import 'api_client.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = await _client.post('auth/login', {
      'email': email,
      'password': password,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final body = await _client.post('auth/register', {
      'email': email,
      'password': password,
    });
    return body['data'] as Map<String, dynamic>;
  }

  /// `GET /profile` — requires Bearer token.
  Future<Map<String, dynamic>> fetchProfile() async {
    final body = await _client.get('profile');
    return body['data'] as Map<String, dynamic>;
  }
}
