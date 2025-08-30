import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 JWT Token Analysis...');
  
  try {
    // Test login
    print('1. Getting JWT token...');
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
      print('   ✅ Token received: ${token.substring(0, 20)}...');
      
      // Decode JWT token (without verification)
      final parts = token.split('.');
      if (parts.length == 3) {
        final header = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))));
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        
        print('   JWT Header: $header');
        print('   JWT Payload: $payload');
        
        // Check if token is expired
        final exp = payload['exp'];
        final iat = payload['iat'];
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        print('   Token issued at: ${DateTime.fromMillisecondsSinceEpoch(iat * 1000)}');
        print('   Token expires at: ${DateTime.fromMillisecondsSinceEpoch(exp * 1000)}');
        print('   Current time: ${DateTime.fromMillisecondsSinceEpoch(now * 1000)}');
        print('   Token expired: ${now > exp}');
        
        // Test with different header format
        print('2. Testing different Authorization header formats...');
        
        // Test 1: Bearer token
        final test1 = await http.get(
          Uri.parse('http://localhost:3000/streamers/my-pcs'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        print('   Test 1 (Bearer): ${test1.statusCode} - ${test1.body}');
        
        // Test 2: Token only
        final test2 = await http.get(
          Uri.parse('http://localhost:3000/streamers/my-pcs'),
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json',
          },
        );
        print('   Test 2 (Token only): ${test2.statusCode} - ${test2.body}');
        
        // Test 3: No Authorization header
        final test3 = await http.get(
          Uri.parse('http://localhost:3000/streamers/my-pcs'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        print('   Test 3 (No Auth): ${test3.statusCode} - ${test3.body}');
        
      } else {
        print('   ❌ Invalid JWT token format');
      }
      
    } else {
      print('   ❌ Login failed: ${loginResponse.body}');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}

