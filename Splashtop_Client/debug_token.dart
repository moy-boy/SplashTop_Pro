import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  print('🔍 Debugging Token Storage...');
  
  // Initialize storage
  final secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    lOptions: LinuxOptions(),
  );
  final prefs = await SharedPreferences.getInstance();
  
  // Test login and token storage
  print('1. Testing login...');
  final loginResponse = await http.post(
    Uri.parse('http://localhost:3000/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'test@example.com',
      'password': 'password123',
    }),
  );
  
  if (loginResponse.statusCode == 201) {
    final data = jsonDecode(loginResponse.body);
    final token = data['token'];
    print('   ✅ Login successful');
    print('   Token: ${token.substring(0, 20)}...');
    
    // Test secure storage
    print('2. Testing secure storage...');
    try {
      await secureStorage.write(key: 'auth_token', value: token);
      final storedToken = await secureStorage.read(key: 'auth_token');
      print('   Secure storage: ${storedToken != null ? '✅' : '❌'}');
      if (storedToken != null) {
        print('   Stored token: ${storedToken.substring(0, 20)}...');
      }
    } catch (e) {
      print('   Secure storage failed: $e');
    }
    
    // Test SharedPreferences
    print('3. Testing SharedPreferences...');
    await prefs.setString('auth_token', token);
    final prefsToken = prefs.getString('auth_token');
    print('   SharedPreferences: ${prefsToken != null ? '✅' : '❌'}');
    if (prefsToken != null) {
      print('   Stored token: ${prefsToken.substring(0, 20)}...');
    }
    
    // Test API call with token
    print('4. Testing API call with token...');
    final apiResponse = await http.get(
      Uri.parse('http://localhost:3000/streamers/my-pcs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('   API response: ${apiResponse.statusCode}');
    print('   API body: ${apiResponse.body}');
    
  } else {
    print('   ❌ Login failed: ${loginResponse.body}');
  }
}

