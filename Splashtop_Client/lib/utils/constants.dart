import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF007AFF); // A vibrant blue
  static const Color secondary = Color(0xFF5AC8FA); // A lighter blue
  static const Color accent = Color(0xFFFF2D55); // A red accent
  static const Color background = Color(0xFFF2F2F7); // Light gray background
  static const Color cardBackground = Color(0xFFFFFFFF); // White card background
  static const Color text = Color(0xFF000000); // Black text
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
}

class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3000';
  static const String auth = '/auth';
  static const String users = '/users';
  static const String streamers = '/streamers';
  
  // Auth endpoints
  static const String login = '$baseUrl$auth/login';
  static const String register = '$baseUrl$auth/register';
  static const String profile = '$baseUrl$auth/profile';
  
  // Streamer endpoints
  static const String myPCs = '$baseUrl$streamers/my-pcs';
  static const String registerStreamer = '$baseUrl$streamers/register';
}

class WebRTCConfig {
  static const List<Map<String, dynamic>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];
  
  static const int defaultBitrate = 5000000; // 5 Mbps
  static const int defaultFPS = 30;
  static const int defaultQuality = 80;
}

class AppConfig {
  static const String appName = 'SplashTop Client';
  static const String appVersion = '1.0.0';
  static const String serverUrl = 'ws://localhost:3000';
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration keepAliveInterval = Duration(seconds: 30);
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userData = 'user_data';
  static const String deviceId = 'device_id';
}
