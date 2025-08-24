import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/pc.dart';
import '../utils/constants.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': data != null ? toJsonT(data!) : null,
      'statusCode': statusCode,
    };
  }
}

class ApiService {
  final http.Client _httpClient;
  final String _baseUrl;

  ApiService({String? baseUrl}) 
    : _httpClient = http.Client(),
      _baseUrl = baseUrl ?? ApiEndpoints.baseUrl;

  // Get list of user's PCs
  Future<List<PC>> getPCs({Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl${ApiEndpoints.pcs}'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> pcList = data['data'];
          return pcList.map((json) => PC.fromJson(json)).toList();
        }
      }
      
      throw ApiException('Failed to fetch PCs: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get specific PC details
  Future<PC> getPC(String pcId, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl${ApiEndpoints.pcs}/$pcId'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PC.fromJson(data['data']);
        }
      }
      
      throw ApiException('Failed to fetch PC: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Add new PC
  Future<PC> addPC({
    required String name,
    required String description,
    required PCPlatform platform,
    Map<String, String>? headers,
  }) async {
    try {
      final pcData = {
        'name': name,
        'description': description,
        'platform': platform.name,
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl${ApiEndpoints.pcs}'),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(pcData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PC.fromJson(data['data']);
        }
      }
      
      throw ApiException('Failed to add PC: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Update PC
  Future<PC> updatePC({
    required String pcId,
    String? name,
    String? description,
    Map<String, String>? headers,
  }) async {
    try {
      final pcData = <String, dynamic>{};
      if (name != null) pcData['name'] = name;
      if (description != null) pcData['description'] = description;

      final response = await _httpClient.put(
        Uri.parse('$_baseUrl${ApiEndpoints.pcs}/$pcId'),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(pcData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PC.fromJson(data['data']);
        }
      }
      
      throw ApiException('Failed to update PC: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Delete PC
  Future<void> deletePC(String pcId, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl${ApiEndpoints.pcs}/$pcId'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to delete PC: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Request connection to PC
  Future<Map<String, dynamic>> requestConnection(String pcId, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl${ApiEndpoints.pcs}/$pcId/connect'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      
      throw ApiException('Failed to request connection: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get signaling data for WebRTC
  Future<Map<String, dynamic>> getSignalingData(String sessionId, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl${ApiEndpoints.signaling}/$sessionId'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      
      throw ApiException('Failed to get signaling data: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Send signaling data for WebRTC
  Future<void> sendSignalingData(String sessionId, Map<String, dynamic> signalingData, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl${ApiEndpoints.signaling}/$sessionId'),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(signalingData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException('Failed to send signaling data: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile({Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      
      throw ApiException('Failed to get user profile: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      
      throw ApiException('Failed to update user profile: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}
