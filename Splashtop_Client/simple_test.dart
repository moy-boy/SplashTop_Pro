import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Simple Token Test...');
  
  try {
    // Test login
    print('1. Testing login...');
    final loginResponse = await http.post(
      Uri.parse('http://localhost:3000/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test@example.com',
        'password': 'password123',
      }),
    );
    
    print('   Login response: ${loginResponse.statusCode}');
    if (loginResponse.statusCode == 201) {
      final data = jsonDecode(loginResponse.body);
      final token = data['token'];
      print('   ✅ Login successful!');
      print('   Token: ${token.substring(0, 20)}...');
      
      // Test API call with token
      print('2. Testing API call with token...');
      final apiResponse = await http.get(
        Uri.parse('http://localhost:3000/streamers/my-pcs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('   API response: ${apiResponse.statusCode}');
      print('   API body: ${apiResponse.body}');
      
      if (apiResponse.statusCode == 200) {
        print('   ✅ API call successful!');
      } else {
        print('   ❌ API call failed!');
      }
      
    } else {
      print('   ❌ Login failed: ${loginResponse.body}');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}

