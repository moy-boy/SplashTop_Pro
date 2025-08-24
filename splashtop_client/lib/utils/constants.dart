import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF1976D2);
  static const Color accent = Color(0xFF64B5F6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

class ApiEndpoints {
  // Replace with your actual backend server URL
  static const String baseUrl = 'http://localhost:3000/api';
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String pcs = '/pcs';
  static const String streamer = '/streamer';
  static const String signaling = '/signaling';
}

class WebRTCConfig {
  static const Map<String, dynamic> iceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      // Add your TURN server configuration here
      // {
      //   'urls': 'turn:your-turn-server.com:3478',
      //   'username': 'username',
      //   'credential': 'password',
      // },
    ],
  };
  
  static const Map<String, dynamic> mediaConstraints = {
    'audio': false,
    'video': {
      'mandatory': {
        'minWidth': '640',
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    },
  };
}

class AppConfig {
  static const String appName = 'SplashTop Client';
  static const String appVersion = '1.0.0';
  static const int connectionTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String lastLoginTime = 'last_login_time';
  static const String deviceId = 'device_id';
}
