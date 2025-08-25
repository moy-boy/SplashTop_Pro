import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'pc.g.dart';

enum PCStatus {
  @JsonValue('online')
  online,
  @JsonValue('offline')
  offline,
  @JsonValue('busy')
  busy,
  @JsonValue('sleeping')
  sleeping,
}

enum PCPlatform {
  @JsonValue('windows')
  windows,
  @JsonValue('macos')
  macos,
  @JsonValue('linux')
  linux,
}

@JsonSerializable()
class PC {
  final String id;
  final String name;
  final String description;
  final PCPlatform platform;
  final PCStatus status;
  final String? ipAddress;
  final String? macAddress;
  final String? deviceId;
  final String userId;
  final DateTime lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  PC({
    required this.id,
    required this.name,
    required this.description,
    required this.platform,
    required this.status,
    this.ipAddress,
    this.macAddress,
    this.deviceId,
    required this.userId,
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory PC.fromJson(Map<String, dynamic> json) => _$PCFromJson(json);
  Map<String, dynamic> toJson() => _$PCToJson(this);

  PC copyWith({
    String? id,
    String? name,
    String? description,
    PCPlatform? platform,
    PCStatus? status,
    String? ipAddress,
    String? macAddress,
    String? deviceId,
    String? userId,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PC(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isOnline => status == PCStatus.online;
  bool get isAvailable => status == PCStatus.online || status == PCStatus.busy;

  String get platformIcon => platform.platformIcon;
  String get statusText => status.statusText;
  Color get statusColor => status.statusColor;

  @override
  String toString() {
    return 'PC(id: $id, name: $name, platform: $platform, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PC && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension methods for enums
extension PCPlatformExtension on PCPlatform {
  String get platformIcon {
    switch (this) {
      case PCPlatform.windows:
        return '🪟';
      case PCPlatform.macos:
        return '🍎';
      case PCPlatform.linux:
        return '🐧';
    }
  }
}

extension PCStatusExtension on PCStatus {
  String get statusText {
    switch (this) {
      case PCStatus.online:
        return 'Online';
      case PCStatus.offline:
        return 'Offline';
      case PCStatus.busy:
        return 'Busy';
      case PCStatus.sleeping:
        return 'Sleeping';
    }
  }

  Color get statusColor {
    switch (this) {
      case PCStatus.online:
        return Colors.green;
      case PCStatus.offline:
        return Colors.grey;
      case PCStatus.busy:
        return Colors.orange;
      case PCStatus.sleeping:
        return Colors.blue;
    }
  }
}
