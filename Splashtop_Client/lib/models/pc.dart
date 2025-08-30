import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'pc.g.dart';

enum PCPlatform { windows, macos, linux }
enum PCStatus { offline, online, streaming }

@JsonSerializable()
class PC {
  final String id;
  final String name;
  final String deviceId;
  final PCPlatform platform;
  final PCStatus status;
  final String? ipAddress;
  final DateTime? lastSeen;
  final String? version;
  final Map<String, dynamic>? capabilities;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PC({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.platform,
    required this.status,
    this.ipAddress,
    this.lastSeen,
    this.version,
    this.capabilities,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PC.fromJson(Map<String, dynamic> json) => _$PCFromJson(json);
  Map<String, dynamic> toJson() => _$PCToJson(this);

  String get platformIcon {
    switch (platform) {
      case PCPlatform.windows:
        return '🪟';
      case PCPlatform.macos:
        return '🍎';
      case PCPlatform.linux:
        return '🐧';
    }
  }

  Color get statusColor {
    switch (status) {
      case PCStatus.online:
        return Colors.green;
      case PCStatus.streaming:
        return Colors.blue;
      case PCStatus.offline:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case PCStatus.online:
        return 'Online';
      case PCStatus.streaming:
        return 'Streaming';
      case PCStatus.offline:
        return 'Offline';
    }
  }
}
