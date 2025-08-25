import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import '../models/user.dart';
import '../utils/constants.dart';

part 'auth_service.g.dart';

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
  final int expiresIn;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) => _$RefreshTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenResponseToJson(this);
}

class AuthService {
  final FlutterSecureStorage _storage;
  final http.Client _httpClient;

  AuthService(this._storage) : _httpClient = http.Client();

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: StorageKeys.accessToken);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get current access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  // Get current refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: StorageKeys.userId);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  // Login user
  Future<LoginResponse> login(String email, String password) async {
    try {
      // For development, allow demo credentials
      if (email == 'demo@example.com' && password == 'password123') {
        // Create mock user and tokens for development
        final mockUser = User(
          id: '1',
          email: email,
          name: 'Demo User',
          avatar: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          roles: ['user'],
        );
        
        final mockResponse = LoginResponse(
          user: mockUser,
          accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          expiresIn: 3600, // 1 hour in seconds
        );
        
        // Store tokens and user data
        await _storage.write(key: StorageKeys.accessToken, value: mockResponse.accessToken);
        await _storage.write(key: StorageKeys.refreshToken, value: mockResponse.refreshToken);
        await _storage.write(key: StorageKeys.userId, value: jsonEncode(mockResponse.user.toJson()));
        await _storage.write(key: StorageKeys.userEmail, value: mockResponse.user.email);
        await _storage.write(key: StorageKeys.lastLoginTime, value: DateTime.now().toIso8601String());
        
        return mockResponse;
      }
      
      // For production, use real API
      final request = LoginRequest(email: email, password: password);
      final response = await _httpClient.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.login}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        
        // Store tokens and user data
        await _storage.write(key: StorageKeys.accessToken, value: loginResponse.accessToken);
        await _storage.write(key: StorageKeys.refreshToken, value: loginResponse.refreshToken);
        await _storage.write(key: StorageKeys.userId, value: jsonEncode(loginResponse.user.toJson()));
        await _storage.write(key: StorageKeys.userEmail, value: loginResponse.user.email);
        await _storage.write(key: StorageKeys.lastLoginTime, value: DateTime.now().toIso8601String());
        
        return loginResponse;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // Refresh access token
  Future<RefreshTokenResponse> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw AuthException('No refresh token available');
      }

      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _httpClient.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final refreshResponse = RefreshTokenResponse.fromJson(jsonDecode(response.body));
        
        // Update stored tokens
        await _storage.write(key: StorageKeys.accessToken, value: refreshResponse.accessToken);
        await _storage.write(key: StorageKeys.refreshToken, value: refreshResponse.refreshToken);
        
        return refreshResponse;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['message'] ?? 'Token refresh failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      if (token != null) {
        // Call logout endpoint
        await _httpClient.post(
          Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.logout}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      // Continue with local logout even if server call fails
    } finally {
      // Clear all stored data
      await _storage.deleteAll();
    }
  }

  // Clear all stored data (for logout or session expiry)
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  // Get authenticated HTTP headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Check if token needs refresh
  Future<bool> shouldRefreshToken() async {
    try {
      final lastLoginTime = await _storage.read(key: StorageKeys.lastLoginTime);
      if (lastLoginTime != null) {
        final lastLogin = DateTime.parse(lastLoginTime);
        final now = DateTime.now();
        final difference = now.difference(lastLogin);
        return difference.inMinutes >= AppConfig.tokenRefreshThreshold.inMinutes;
      }
    } catch (e) {
      // If we can't determine, assume we need refresh
    }
    return true;
  }

  void dispose() {
    _httpClient.close();
  }
}

class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
