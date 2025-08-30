import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 User Validation Test...');
  
  try {
    // Test login
    print('1. Getting user info...');
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
      final user = data['user'];
      final token = data['token'];
      
      print('   ✅ Login successful!');
      print('   User ID: ${user['id']}');
      print('   User Email: ${user['email']}');
      print('   User Role: ${user['role']}');
      
      // Decode JWT to get the sub (user ID)
      final parts = token.split('.');
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final jwtUserId = payload['sub'];
      
      print('   JWT User ID (sub): $jwtUserId');
      print('   User IDs match: ${user['id'] == jwtUserId}');
      
      // Test profile endpoint (should work with token)
      print('2. Testing profile endpoint...');
      final profileResponse = await http.get(
        Uri.parse('http://localhost:3000/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('   Profile response: ${profileResponse.statusCode}');
      print('   Profile body: ${profileResponse.body}');
      
      // Test streamers endpoint again
      print('3. Testing streamers endpoint...');
      final streamersResponse = await http.get(
        Uri.parse('http://localhost:3000/streamers/my-pcs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('   Streamers response: ${streamersResponse.statusCode}');
      print('   Streamers body: ${streamersResponse.body}');
      
    } else {
      print('   ❌ Login failed: ${loginResponse.body}');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}

