import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pc.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class PCListProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  List<PC> _pcs = [];
  bool _isLoading = false;
  String? _error;

  List<PC> get pcs => _pcs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPCs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.myPCs),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _pcs = data.map((json) => PC.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load computers');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PC> searchPCs(String query) {
    if (query.isEmpty) return _pcs;
    
    return _pcs.where((pc) =>
      pc.name.toLowerCase().contains(query.toLowerCase()) ||
      (pc.ipAddress?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  Future<bool> addPC({
    required String name,
    required String deviceId,
    required PCPlatform platform,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.registerStreamer),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'deviceId': deviceId,
          'platform': platform.name,
        }),
      );

      if (response.statusCode == 201) {
        final pc = PC.fromJson(jsonDecode(response.body));
        _pcs.add(pc);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to add computer');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePC(String pcId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.streamers}/$pcId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _pcs.removeWhere((pc) => pc.id == pcId);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete computer');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
