import 'package:flutter/foundation.dart';

import '../../core/constants/user_roles.dart';
import '../../core/debug/app_debug_log.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repository}) : _repository = repository {
    _restore();
  }

  final AuthRepository _repository;

  UserModel? _user;
  bool _initializing = true;
  bool _submitting = false;
  String? _error;

  UserModel? get user => _user;
  bool get initializing => _initializing;
  bool get submitting => _submitting;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == UserRoles.admin;

  Future<void> _restore() async {
    appDebugLog('Auth', 'restoreSession.start');
    try {
      _user = await _repository.restoreSession();
      appDebugLog(
        'Auth',
        'restoreSession.done',
        'authenticated=${_user != null}',
      );
    } catch (e, st) {
      appDebugError('Auth', e, st, 'restoreSession');
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    appDebugLog('Auth', 'login.start');
    try {
      _user = await _repository.login(email: email, password: password);
      appDebugLog('Auth', 'login.success', 'userId=${_user?.id}');
      return true;
    } on ApiException catch (e) {
      appDebugLog('Auth', 'login.api_error', '${e.code}: ${e.message}');
      _error = e.message;
      return false;
    } catch (e, st) {
      appDebugError('Auth', e, st, 'login');
      _error = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Returns true if registration succeeded (user must log in separately).
  Future<bool> register(String email, String password) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    appDebugLog('Auth', 'register.start');
    try {
      await _repository.register(email: email, password: password);
      appDebugLog('Auth', 'register.success');
      return true;
    } on ApiException catch (e) {
      appDebugLog('Auth', 'register.api_error', '${e.code}: ${e.message}');
      _error = e.message;
      return false;
    } catch (e, st) {
      appDebugError('Auth', e, st, 'register');
      _error = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    appDebugLog('Auth', 'logout');
    await _repository.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
