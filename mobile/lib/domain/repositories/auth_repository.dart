import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({required String email, required String password});
  Future<void> logout();
  Future<bool> hasStoredSession();

  /// If a JWT exists: validates it with the server (`GET /profile`) and returns the user.
  /// On **401** clears storage. On other failures (e.g. offline) returns cached user if any.
  Future<UserModel?> restoreSession();
}
