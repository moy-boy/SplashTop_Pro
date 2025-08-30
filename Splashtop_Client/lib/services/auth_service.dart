import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  AuthService() {
    _initSecureStorage();
    _initPrefs();
  }

  void _initSecureStorage() {
    // Configure secure storage for Linux
    if (Platform.isLinux) {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        lOptions: LinuxOptions(),
      );
    } else {
      _secureStorage = const FlutterSecureStorage();
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String?> getToken() async {
    try {
      // Try secure storage first
      return await _secureStorage.read(key: StorageKeys.authToken);
    } catch (e) {
      print('⚠️ Secure storage failed, using SharedPreferences: $e');
      // Fallback to SharedPreferences
      return _prefs?.getString(StorageKeys.authToken);
    }
  }

  Future<void> saveToken(String token) async {
    try {
      // Try secure storage first
      await _secureStorage.write(key: StorageKeys.authToken, value: token);
    } catch (e) {
      print('⚠️ Secure storage failed, using SharedPreferences: $e');
      // Fallback to SharedPreferences
      await _prefs?.setString(StorageKeys.authToken, token);
    }
  }

  Future<void> saveUser(User user) async {
    final userData = jsonEncode(user.toJson());
    try {
      // Try secure storage first
      await _secureStorage.write(key: StorageKeys.userData, value: userData);
    } catch (e) {
      print('⚠️ Secure storage failed, using SharedPreferences: $e');
      // Fallback to SharedPreferences
      await _prefs?.setString(StorageKeys.userData, userData);
    }
  }

  Future<User?> getUser() async {
    String? userData;
    try {
      // Try secure storage first
      userData = await _secureStorage.read(key: StorageKeys.userData);
    } catch (e) {
      print('⚠️ Secure storage failed, using SharedPreferences: $e');
      // Fallback to SharedPreferences
      userData = _prefs?.getString(StorageKeys.userData);
    }
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> clearAuth() async {
    try {
      await _secureStorage.delete(key: StorageKeys.authToken);
      await _secureStorage.delete(key: StorageKeys.userData);
    } catch (e) {
      print('⚠️ Secure storage clear failed: $e');
    }
    
    // Also clear SharedPreferences
    await _prefs?.remove(StorageKeys.authToken);
    await _prefs?.remove(StorageKeys.userData);
  }

  // Helper method to make authenticated API calls
  Future<http.Response> _makeAuthenticatedRequest(
    String url, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(Uri.parse(url), headers: headers);
      case 'POST':
        return await http.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(Uri.parse(url), headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 AuthService.login() - Making API call to: ${ApiEndpoints.login}');
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 AuthService.login() - Response status: ${response.statusCode}');
      print('📡 AuthService.login() - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('📡 AuthService.login() - Parsed data: $data');
        
        final user = User.fromJson(data['user']);
        final token = data['token'];

        print('📡 AuthService.login() - User: $user');
        print('📡 AuthService.login() - Token: $token');

        // Try to save token and user, but don't fail if secure storage fails
        try {
          await saveToken(token);
          await saveUser(user);
          print('📡 AuthService.login() - Success! Returning success response');
        } catch (storageError) {
          print('📡 AuthService.login() - Storage failed but continuing: $storageError');
          // Continue even if storage fails - the authentication was successful
        }

        return {
          'success': true,
          'user': user,
          'token': token,
        };
      } else {
        final error = jsonDecode(response.body);
        print('📡 AuthService.login() - Error response: $error');
        return {
          'success': false,
          'error': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('📡 AuthService.login() - Exception: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'];

        // Try to save token and user, but don't fail if secure storage fails
        try {
          await saveToken(token);
          await saveUser(user);
        } catch (storageError) {
          print('📡 AuthService.register() - Storage failed but continuing: $storageError');
          // Continue even if storage fails - the registration was successful
        }

        return {
          'success': true,
          'user': user,
          'token': token,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Method to test if the current token is valid
  Future<bool> isTokenValid() async {
    try {
      final response = await _makeAuthenticatedRequest(ApiEndpoints.profile);
      return response.statusCode == 200;
    } catch (e) {
      print('Token validation failed: $e');
      return false;
    }
  }

  // Method to refresh authentication if needed
  Future<bool> refreshAuthentication() async {
    try {
      // Try to validate current token
      if (await isTokenValid()) {
        return true;
      }

      // If token is invalid, try to login again with stored credentials
      final user = await getUser();
      if (user != null) {
        // For now, we'll just clear the invalid token
        // In a real app, you might want to implement refresh token logic
        await clearAuth();
        return false;
      }
      return false;
    } catch (e) {
      print('Authentication refresh failed: $e');
      return false;
    }
  }
}

class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
