// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PC _$PCFromJson(Map<String, dynamic> json) => PC(
  id: json['id'] as String,
  name: json['name'] as String,
  deviceId: json['deviceId'] as String,
  platform: $enumDecode(_$PCPlatformEnumMap, json['platform']),
  status: $enumDecode(_$PCStatusEnumMap, json['status']),
  ipAddress: json['ipAddress'] as String?,
  lastSeen: json['lastSeen'] == null
      ? null
      : DateTime.parse(json['lastSeen'] as String),
  version: json['version'] as String?,
  capabilities: json['capabilities'] as Map<String, dynamic>?,
  userId: json['userId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PCToJson(PC instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'deviceId': instance.deviceId,
  'platform': _$PCPlatformEnumMap[instance.platform]!,
  'status': _$PCStatusEnumMap[instance.status]!,
  'ipAddress': instance.ipAddress,
  'lastSeen': instance.lastSeen?.toIso8601String(),
  'version': instance.version,
  'capabilities': instance.capabilities,
  'userId': instance.userId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$PCPlatformEnumMap = {
  PCPlatform.windows: 'windows',
  PCPlatform.macos: 'macos',
  PCPlatform.linux: 'linux',
};

const _$PCStatusEnumMap = {
  PCStatus.offline: 'offline',
  PCStatus.online: 'online',
  PCStatus.streaming: 'streaming',
};
