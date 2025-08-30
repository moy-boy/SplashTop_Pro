import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        _user = await _authService.getUser();
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      
      if (result['success']) {
        _user = result['user'];
        _isAuthenticated = true;
        return true;
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String firstName, String lastName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.register(email, password, firstName, lastName);
      
      if (result['success']) {
        _user = result['user'];
        _isAuthenticated = true;
        return true;
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.clearAuth();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
