import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 JWT Secret Test...');
  
  try {
    // Test login to get a fresh token
    print('1. Getting fresh JWT token...');
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
      print('   ✅ Fresh token received');
      
      // Test the token immediately
      print('2. Testing token immediately...');
      final testResponse = await http.get(
        Uri.parse('http://localhost:3000/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('   Profile response: ${testResponse.statusCode}');
      print('   Profile body: ${testResponse.body}');
      
      // Test with a different endpoint
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
      
      // Test without Bearer prefix
      print('4. Testing without Bearer prefix...');
      final noBearerResponse = await http.get(
        Uri.parse('http://localhost:3000/auth/profile'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );
      print('   No Bearer response: ${noBearerResponse.statusCode}');
      print('   No Bearer body: ${noBearerResponse.body}');
      
      // Test with different case
      print('5. Testing with different case...');
      final differentCaseResponse = await http.get(
        Uri.parse('http://localhost:3000/auth/profile'),
        headers: {
          'authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('   Different case response: ${differentCaseResponse.statusCode}');
      print('   Different case body: ${differentCaseResponse.body}');
      
    } else {
      print('   ❌ Login failed: ${loginResponse.body}');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}

