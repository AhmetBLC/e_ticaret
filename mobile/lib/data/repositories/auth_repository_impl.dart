import '../../core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/session_storage.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required SessionStorage sessionStorage,
  })  : _remote = remote,
        _session = sessionStorage;

  final AuthRemoteDatasource _remote;
  final SessionStorage _session;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final data = await _remote.login(email: email, password: password);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('No token in login response');
    }
    await _session.writeToken(token);
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw ApiException('Sunucudan kullanıcı verisi alınamadı');
    }
    final user = UserModel.fromJson(userJson);
    await _session.cacheUser(user);
    return user;
  }

  @override
  Future<UserModel> register({required String email, required String password}) async {
    final data = await _remote.register(email: email, password: password);
    final userJson = data['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  @override
  Future<void> logout() => _session.clearAll();

  @override
  Future<bool> hasStoredSession() async {
    final t = await _session.readToken();
    return t != null && t.isNotEmpty;
  }

  @override
  Future<UserModel?> restoreSession() async {
    if (!await hasStoredSession()) {
      return null;
    }
    try {
      final data = await _remote.fetchProfile();
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw ApiException('Profil verisi alınamadı');
      }
      final user = UserModel.fromJson(userJson);
      await _session.cacheUser(user);
      return user;
    } on ApiException catch (e) {
      final unauthorized =
          e.statusCode == 401 || e.code == 'UNAUTHORIZED';
      if (unauthorized) {
        await _session.clearAll();
        return null;
      }
      return _session.readCachedUser();
    }
  }
}
