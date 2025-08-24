import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pc.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PCListProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  
  List<PC> _pcs = [];
  bool _isLoading = false;
  String? _error;
  PC? _selectedPC;

  PCListProvider(this._apiService) : _authService = AuthService(FlutterSecureStorage());

  // Getters
  List<PC> get pcs => _pcs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PC? get selectedPC => _selectedPC;
  
  List<PC> get onlinePCs => _pcs.where((pc) => pc.isOnline).toList();
  List<PC> get availablePCs => _pcs.where((pc) => pc.isAvailable).toList();

  // Load PCs from API
  Future<void> loadPCs() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final headers = await _authService.getAuthHeaders();
      final pcList = await _apiService.getPCs(headers: headers);
      
      _pcs = pcList;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _pcs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh PCs (reload from API)
  Future<void> refreshPCs() async {
    await loadPCs();
  }

  // Add new PC
  Future<bool> addPC({
    required String name,
    required String description,
    required PCPlatform platform,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final headers = await _authService.getAuthHeaders();
      final newPC = await _apiService.addPC(
        name: name,
        description: description,
        platform: platform,
        headers: headers,
      );
      
      _pcs.add(newPC);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update PC
  Future<bool> updatePC({
    required String pcId,
    String? name,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final headers = await _authService.getAuthHeaders();
      final updatedPC = await _apiService.updatePC(
        pcId: pcId,
        name: name,
        description: description,
        headers: headers,
      );
      
      final index = _pcs.indexWhere((pc) => pc.id == pcId);
      if (index != -1) {
        _pcs[index] = updatedPC;
      }
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete PC
  Future<bool> deletePC(String pcId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final headers = await _authService.getAuthHeaders();
      await _apiService.deletePC(pcId, headers: headers);
      
      _pcs.removeWhere((pc) => pc.id == pcId);
      if (_selectedPC?.id == pcId) {
        _selectedPC = null;
      }
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request connection to PC
  Future<Map<String, dynamic>?> requestConnection(String pcId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final headers = await _authService.getAuthHeaders();
      final connectionData = await _apiService.requestConnection(pcId, headers: headers);
      
      _error = null;
      return connectionData;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select PC
  void selectPC(PC pc) {
    _selectedPC = pc;
    notifyListeners();
  }

  // Clear selected PC
  void clearSelectedPC() {
    _selectedPC = null;
    notifyListeners();
  }

  // Get PC by ID
  PC? getPCById(String pcId) {
    try {
      return _pcs.firstWhere((pc) => pc.id == pcId);
    } catch (e) {
      return null;
    }
  }

  // Update PC status (for real-time updates)
  void updatePCStatus(String pcId, PCStatus status) {
    final index = _pcs.indexWhere((pc) => pc.id == pcId);
    if (index != -1) {
      final updatedPC = _pcs[index].copyWith(status: status);
      _pcs[index] = updatedPC;
      
      // Update selected PC if it's the same one
      if (_selectedPC?.id == pcId) {
        _selectedPC = updatedPC;
      }
      
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get PCs by platform
  List<PC> getPCsByPlatform(PCPlatform platform) {
    return _pcs.where((pc) => pc.platform == platform).toList();
  }

  // Get PCs by status
  List<PC> getPCsByStatus(PCStatus status) {
    return _pcs.where((pc) => pc.status == status).toList();
  }

  // Search PCs by name
  List<PC> searchPCs(String query) {
    if (query.isEmpty) return _pcs;
    
    final lowercaseQuery = query.toLowerCase();
    return _pcs.where((pc) => 
      pc.name.toLowerCase().contains(lowercaseQuery) ||
      pc.description.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
