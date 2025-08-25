// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PC _$PCFromJson(Map<String, dynamic> json) => PC(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  platform: $enumDecode(_$PCPlatformEnumMap, json['platform']),
  status: $enumDecode(_$PCStatusEnumMap, json['status']),
  ipAddress: json['ipAddress'] as String?,
  macAddress: json['macAddress'] as String?,
  deviceId: json['deviceId'] as String?,
  userId: json['userId'] as String,
  lastSeen: DateTime.parse(json['lastSeen'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PCToJson(PC instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'platform': _$PCPlatformEnumMap[instance.platform]!,
  'status': _$PCStatusEnumMap[instance.status]!,
  'ipAddress': instance.ipAddress,
  'macAddress': instance.macAddress,
  'deviceId': instance.deviceId,
  'userId': instance.userId,
  'lastSeen': instance.lastSeen.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'metadata': instance.metadata,
};

const _$PCPlatformEnumMap = {
  PCPlatform.windows: 'windows',
  PCPlatform.macos: 'macos',
  PCPlatform.linux: 'linux',
};

const _$PCStatusEnumMap = {
  PCStatus.online: 'online',
  PCStatus.offline: 'offline',
  PCStatus.busy: 'busy',
  PCStatus.sleeping: 'sleeping',
};
