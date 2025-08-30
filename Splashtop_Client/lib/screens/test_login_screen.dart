import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({super.key});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String _status = 'Ready';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _status = 'Testing login...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      print('🔐 TEST: Starting login test...');
      print('📧 Email: ${_emailController.text}');
      print('🔑 Password: ${_passwordController.text}');
      
      final result = await authProvider.login(_emailController.text, _passwordController.text);
      
      print('✅ TEST: Login result: $result');
      print('🔍 TEST: AuthProvider state after login:');
      print('   - isAuthenticated: ${authProvider.isAuthenticated}');
      print('   - user: ${authProvider.user}');
      print('   - isLoading: ${authProvider.isLoading}');
      
      if (mounted) {
        setState(() {
          _status = 'Login successful! isAuthenticated: ${authProvider.isAuthenticated}';
        });
      }
      
    } catch (e) {
      print('❌ TEST: Login error: $e');
      if (mounted) {
        setState(() {
          _status = 'Login failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testRegister() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _status = 'Testing registration...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      print('🔐 TEST: Starting registration test...');
      
      final result = await authProvider.register(
        _emailController.text, 
        _passwordController.text,
        'Test',
        'User',
      );
      
      print('✅ TEST: Registration result: $result');
      print('🔍 TEST: AuthProvider state after registration:');
      print('   - isAuthenticated: ${authProvider.isAuthenticated}');
      print('   - user: ${authProvider.user}');
      print('   - isLoading: ${authProvider.isLoading}');
      
      if (mounted) {
        setState(() {
          _status = 'Registration successful! isAuthenticated: ${authProvider.isAuthenticated}';
        });
      }
      
    } catch (e) {
      print('❌ TEST: Registration error: $e');
      if (mounted) {
        setState(() {
          _status = 'Registration failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkAuthState() {
    final authProvider = context.read<AuthProvider>();
    print('🔍 TEST: Current AuthProvider state:');
    print('   - isAuthenticated: ${authProvider.isAuthenticated}');
    print('   - user: ${authProvider.user}');
    print('   - isLoading: ${authProvider.isLoading}');
    
    setState(() {
      _status = 'Current state - isAuthenticated: ${authProvider.isAuthenticated}, user: ${authProvider.user?.email ?? 'null'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Login'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Test Login'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Register'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _checkAuthState,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Check Auth State'),
            ),
            
            const SizedBox(height: 24),
            
            // Consumer to show real-time auth state
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: authProvider.isAuthenticated ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: authProvider.isAuthenticated ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real-time Auth State:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: authProvider.isAuthenticated ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('isAuthenticated: ${authProvider.isAuthenticated}'),
                      Text('isLoading: ${authProvider.isLoading}'),
                      Text('user: ${authProvider.user?.email ?? 'null'}'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
