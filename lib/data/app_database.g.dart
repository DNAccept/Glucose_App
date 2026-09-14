// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReadingsTable extends Readings
    with TableInfo<$ReadingsTable, ReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => generateUuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mgDlMeta = const VerificationMeta('mgDl');
  @override
  late final GeneratedColumn<double> mgDl = GeneratedColumn<double>(
    'mg_dl',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _glucoseClassMeta = const VerificationMeta(
    'glucoseClass',
  );
  @override
  late final GeneratedColumn<int> glucoseClass = GeneratedColumn<int>(
    'glucose_class',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<int> confidence = GeneratedColumn<int>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pendingSync),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    userId,
    timestamp,
    mgDl,
    glucoseClass,
    confidence,
    syncStatus,
    lastModified,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('mg_dl')) {
      context.handle(
        _mgDlMeta,
        mgDl.isAcceptableOrUnknown(data['mg_dl']!, _mgDlMeta),
      );
    } else if (isInserting) {
      context.missing(_mgDlMeta);
    }
    if (data.containsKey('glucose_class')) {
      context.handle(
        _glucoseClassMeta,
        glucoseClass.isAcceptableOrUnknown(
          data['glucose_class']!,
          _glucoseClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_glucoseClassMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      mgDl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mg_dl'],
      )!,
      glucoseClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}glucose_class'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confidence'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }
}

class ReadingRow extends DataClass implements Insertable<ReadingRow> {
  final int id;
  final String uuid;
  final int? userId;
  final DateTime timestamp;
  final double mgDl;

  /// 0 = low, 1 = normal, 2 = high — matches [GlucoseClass.wireValue].
  final int glucoseClass;
  final int confidence;
  final int syncStatus;
  final DateTime lastModified;
  final bool isDeleted;
  const ReadingRow({
    required this.id,
    required this.uuid,
    this.userId,
    required this.timestamp,
    required this.mgDl,
    required this.glucoseClass,
    required this.confidence,
    required this.syncStatus,
    required this.lastModified,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['mg_dl'] = Variable<double>(mgDl);
    map['glucose_class'] = Variable<int>(glucoseClass);
    map['confidence'] = Variable<int>(confidence);
    map['sync_status'] = Variable<int>(syncStatus);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      timestamp: Value(timestamp),
      mgDl: Value(mgDl),
      glucoseClass: Value(glucoseClass),
      confidence: Value(confidence),
      syncStatus: Value(syncStatus),
      lastModified: Value(lastModified),
      isDeleted: Value(isDeleted),
    );
  }

  factory ReadingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      userId: serializer.fromJson<int?>(json['userId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      mgDl: serializer.fromJson<double>(json['mgDl']),
      glucoseClass: serializer.fromJson<int>(json['glucoseClass']),
      confidence: serializer.fromJson<int>(json['confidence']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'userId': serializer.toJson<int?>(userId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'mgDl': serializer.toJson<double>(mgDl),
      'glucoseClass': serializer.toJson<int>(glucoseClass),
      'confidence': serializer.toJson<int>(confidence),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ReadingRow copyWith({
    int? id,
    String? uuid,
    Value<int?> userId = const Value.absent(),
    DateTime? timestamp,
    double? mgDl,
    int? glucoseClass,
    int? confidence,
    int? syncStatus,
    DateTime? lastModified,
    bool? isDeleted,
  }) => ReadingRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    userId: userId.present ? userId.value : this.userId,
    timestamp: timestamp ?? this.timestamp,
    mgDl: mgDl ?? this.mgDl,
    glucoseClass: glucoseClass ?? this.glucoseClass,
    confidence: confidence ?? this.confidence,
    syncStatus: syncStatus ?? this.syncStatus,
    lastModified: lastModified ?? this.lastModified,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ReadingRow copyWithCompanion(ReadingsCompanion data) {
    return ReadingRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      userId: data.userId.present ? data.userId.value : this.userId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      mgDl: data.mgDl.present ? data.mgDl.value : this.mgDl,
      glucoseClass: data.glucoseClass.present
          ? data.glucoseClass.value
          : this.glucoseClass,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('userId: $userId, ')
          ..write('timestamp: $timestamp, ')
          ..write('mgDl: $mgDl, ')
          ..write('glucoseClass: $glucoseClass, ')
          ..write('confidence: $confidence, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastModified: $lastModified, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    userId,
    timestamp,
    mgDl,
    glucoseClass,
    confidence,
    syncStatus,
    lastModified,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.userId == this.userId &&
          other.timestamp == this.timestamp &&
          other.mgDl == this.mgDl &&
          other.glucoseClass == this.glucoseClass &&
          other.confidence == this.confidence &&
          other.syncStatus == this.syncStatus &&
          other.lastModified == this.lastModified &&
          other.isDeleted == this.isDeleted);
}

class ReadingsCompanion extends UpdateCompanion<ReadingRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int?> userId;
  final Value<DateTime> timestamp;
  final Value<double> mgDl;
  final Value<int> glucoseClass;
  final Value<int> confidence;
  final Value<int> syncStatus;
  final Value<DateTime> lastModified;
  final Value<bool> isDeleted;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.userId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.mgDl = const Value.absent(),
    this.glucoseClass = const Value.absent(),
    this.confidence = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ReadingsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.userId = const Value.absent(),
    required DateTime timestamp,
    required double mgDl,
    required int glucoseClass,
    required int confidence,
    this.syncStatus = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : timestamp = Value(timestamp),
       mgDl = Value(mgDl),
       glucoseClass = Value(glucoseClass),
       confidence = Value(confidence);
  static Insertable<ReadingRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? userId,
    Expression<DateTime>? timestamp,
    Expression<double>? mgDl,
    Expression<int>? glucoseClass,
    Expression<int>? confidence,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastModified,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (userId != null) 'user_id': userId,
      if (timestamp != null) 'timestamp': timestamp,
      if (mgDl != null) 'mg_dl': mgDl,
      if (glucoseClass != null) 'glucose_class': glucoseClass,
      if (confidence != null) 'confidence': confidence,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastModified != null) 'last_modified': lastModified,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ReadingsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int?>? userId,
    Value<DateTime>? timestamp,
    Value<double>? mgDl,
    Value<int>? glucoseClass,
    Value<int>? confidence,
    Value<int>? syncStatus,
    Value<DateTime>? lastModified,
    Value<bool>? isDeleted,
  }) {
    return ReadingsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      mgDl: mgDl ?? this.mgDl,
      glucoseClass: glucoseClass ?? this.glucoseClass,
      confidence: confidence ?? this.confidence,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (mgDl.present) {
      map['mg_dl'] = Variable<double>(mgDl.value);
    }
    if (glucoseClass.present) {
      map['glucose_class'] = Variable<int>(glucoseClass.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<int>(confidence.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('userId: $userId, ')
          ..write('timestamp: $timestamp, ')
          ..write('mgDl: $mgDl, ')
          ..write('glucoseClass: $glucoseClass, ')
          ..write('confidence: $confidence, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastModified: $lastModified, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $ReferenceReadingsTable extends ReferenceReadings
    with TableInfo<$ReferenceReadingsTable, ReferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => generateUuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceValueMgDlMeta =
      const VerificationMeta('referenceValueMgDl');
  @override
  late final GeneratedColumn<int> referenceValueMgDl = GeneratedColumn<int>(
    'reference_value_mg_dl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceClassMeta = const VerificationMeta(
    'referenceClass',
  );
  @override
  late final GeneratedColumn<int> referenceClass = GeneratedColumn<int>(
    'reference_class',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceMgDlMeta = const VerificationMeta(
    'deviceMgDl',
  );
  @override
  late final GeneratedColumn<double> deviceMgDl = GeneratedColumn<double>(
    'device_mg_dl',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceClassMeta = const VerificationMeta(
    'deviceClass',
  );
  @override
  late final GeneratedColumn<int> deviceClass = GeneratedColumn<int>(
    'device_class',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceConfidenceMeta = const VerificationMeta(
    'deviceConfidence',
  );
  @override
  late final GeneratedColumn<int> deviceConfidence = GeneratedColumn<int>(
    'device_confidence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pendingSync),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    userId,
    referenceValueMgDl,
    referenceClass,
    deviceMgDl,
    deviceClass,
    deviceConfidence,
    timestamp,
    syncStatus,
    lastModified,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('reference_value_mg_dl')) {
      context.handle(
        _referenceValueMgDlMeta,
        referenceValueMgDl.isAcceptableOrUnknown(
          data['reference_value_mg_dl']!,
          _referenceValueMgDlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceValueMgDlMeta);
    }
    if (data.containsKey('reference_class')) {
      context.handle(
        _referenceClassMeta,
        referenceClass.isAcceptableOrUnknown(
          data['reference_class']!,
          _referenceClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceClassMeta);
    }
    if (data.containsKey('device_mg_dl')) {
      context.handle(
        _deviceMgDlMeta,
        deviceMgDl.isAcceptableOrUnknown(
          data['device_mg_dl']!,
          _deviceMgDlMeta,
        ),
      );
    }
    if (data.containsKey('device_class')) {
      context.handle(
        _deviceClassMeta,
        deviceClass.isAcceptableOrUnknown(
          data['device_class']!,
          _deviceClassMeta,
        ),
      );
    }
    if (data.containsKey('device_confidence')) {
      context.handle(
        _deviceConfidenceMeta,
        deviceConfidence.isAcceptableOrUnknown(
          data['device_confidence']!,
          _deviceConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      referenceValueMgDl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_value_mg_dl'],
      )!,
      referenceClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_class'],
      )!,
      deviceMgDl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}device_mg_dl'],
      ),
      deviceClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_class'],
      ),
      deviceConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_confidence'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ReferenceReadingsTable createAlias(String alias) {
    return $ReferenceReadingsTable(attachedDatabase, alias);
  }
}

class ReferenceRow extends DataClass implements Insertable<ReferenceRow> {
  final int id;
  final String uuid;
  final int? userId;
  final int referenceValueMgDl;
  final int referenceClass;
  final double? deviceMgDl;
  final int? deviceClass;
  final int? deviceConfidence;
  final DateTime timestamp;
  final int syncStatus;
  final DateTime lastModified;
  final bool isDeleted;
  const ReferenceRow({
    required this.id,
    required this.uuid,
    this.userId,
    required this.referenceValueMgDl,
    required this.referenceClass,
    this.deviceMgDl,
    this.deviceClass,
    this.deviceConfidence,
    required this.timestamp,
    required this.syncStatus,
    required this.lastModified,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['reference_value_mg_dl'] = Variable<int>(referenceValueMgDl);
    map['reference_class'] = Variable<int>(referenceClass);
    if (!nullToAbsent || deviceMgDl != null) {
      map['device_mg_dl'] = Variable<double>(deviceMgDl);
    }
    if (!nullToAbsent || deviceClass != null) {
      map['device_class'] = Variable<int>(deviceClass);
    }
    if (!nullToAbsent || deviceConfidence != null) {
      map['device_confidence'] = Variable<int>(deviceConfidence);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['sync_status'] = Variable<int>(syncStatus);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ReferenceReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReferenceReadingsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      referenceValueMgDl: Value(referenceValueMgDl),
      referenceClass: Value(referenceClass),
      deviceMgDl: deviceMgDl == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceMgDl),
      deviceClass: deviceClass == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceClass),
      deviceConfidence: deviceConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceConfidence),
      timestamp: Value(timestamp),
      syncStatus: Value(syncStatus),
      lastModified: Value(lastModified),
      isDeleted: Value(isDeleted),
    );
  }

  factory ReferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      userId: serializer.fromJson<int?>(json['userId']),
      referenceValueMgDl: serializer.fromJson<int>(json['referenceValueMgDl']),
      referenceClass: serializer.fromJson<int>(json['referenceClass']),
      deviceMgDl: serializer.fromJson<double?>(json['deviceMgDl']),
      deviceClass: serializer.fromJson<int?>(json['deviceClass']),
      deviceConfidence: serializer.fromJson<int?>(json['deviceConfidence']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'userId': serializer.toJson<int?>(userId),
      'referenceValueMgDl': serializer.toJson<int>(referenceValueMgDl),
      'referenceClass': serializer.toJson<int>(referenceClass),
      'deviceMgDl': serializer.toJson<double?>(deviceMgDl),
      'deviceClass': serializer.toJson<int?>(deviceClass),
      'deviceConfidence': serializer.toJson<int?>(deviceConfidence),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ReferenceRow copyWith({
    int? id,
    String? uuid,
    Value<int?> userId = const Value.absent(),
    int? referenceValueMgDl,
    int? referenceClass,
    Value<double?> deviceMgDl = const Value.absent(),
    Value<int?> deviceClass = const Value.absent(),
    Value<int?> deviceConfidence = const Value.absent(),
    DateTime? timestamp,
    int? syncStatus,
    DateTime? lastModified,
    bool? isDeleted,
  }) => ReferenceRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    userId: userId.present ? userId.value : this.userId,
    referenceValueMgDl: referenceValueMgDl ?? this.referenceValueMgDl,
    referenceClass: referenceClass ?? this.referenceClass,
    deviceMgDl: deviceMgDl.present ? deviceMgDl.value : this.deviceMgDl,
    deviceClass: deviceClass.present ? deviceClass.value : this.deviceClass,
    deviceConfidence: deviceConfidence.present
        ? deviceConfidence.value
        : this.deviceConfidence,
    timestamp: timestamp ?? this.timestamp,
    syncStatus: syncStatus ?? this.syncStatus,
    lastModified: lastModified ?? this.lastModified,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ReferenceRow copyWithCompanion(ReferenceReadingsCompanion data) {
    return ReferenceRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      userId: data.userId.present ? data.userId.value : this.userId,
      referenceValueMgDl: data.referenceValueMgDl.present
          ? data.referenceValueMgDl.value
          : this.referenceValueMgDl,
      referenceClass: data.referenceClass.present
          ? data.referenceClass.value
          : this.referenceClass,
      deviceMgDl: data.deviceMgDl.present
          ? data.deviceMgDl.value
          : this.deviceMgDl,
      deviceClass: data.deviceClass.present
          ? data.deviceClass.value
          : this.deviceClass,
      deviceConfidence: data.deviceConfidence.present
          ? data.deviceConfidence.value
          : this.deviceConfidence,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('userId: $userId, ')
          ..write('referenceValueMgDl: $referenceValueMgDl, ')
          ..write('referenceClass: $referenceClass, ')
          ..write('deviceMgDl: $deviceMgDl, ')
          ..write('deviceClass: $deviceClass, ')
          ..write('deviceConfidence: $deviceConfidence, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastModified: $lastModified, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    userId,
    referenceValueMgDl,
    referenceClass,
    deviceMgDl,
    deviceClass,
    deviceConfidence,
    timestamp,
    syncStatus,
    lastModified,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.userId == this.userId &&
          other.referenceValueMgDl == this.referenceValueMgDl &&
          other.referenceClass == this.referenceClass &&
          other.deviceMgDl == this.deviceMgDl &&
          other.deviceClass == this.deviceClass &&
          other.deviceConfidence == this.deviceConfidence &&
          other.timestamp == this.timestamp &&
          other.syncStatus == this.syncStatus &&
          other.lastModified == this.lastModified &&
          other.isDeleted == this.isDeleted);
}

class ReferenceReadingsCompanion extends UpdateCompanion<ReferenceRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int?> userId;
  final Value<int> referenceValueMgDl;
  final Value<int> referenceClass;
  final Value<double?> deviceMgDl;
  final Value<int?> deviceClass;
  final Value<int?> deviceConfidence;
  final Value<DateTime> timestamp;
  final Value<int> syncStatus;
  final Value<DateTime> lastModified;
  final Value<bool> isDeleted;
  const ReferenceReadingsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.userId = const Value.absent(),
    this.referenceValueMgDl = const Value.absent(),
    this.referenceClass = const Value.absent(),
    this.deviceMgDl = const Value.absent(),
    this.deviceClass = const Value.absent(),
    this.deviceConfidence = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ReferenceReadingsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.userId = const Value.absent(),
    required int referenceValueMgDl,
    required int referenceClass,
    this.deviceMgDl = const Value.absent(),
    this.deviceClass = const Value.absent(),
    this.deviceConfidence = const Value.absent(),
    required DateTime timestamp,
    this.syncStatus = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : referenceValueMgDl = Value(referenceValueMgDl),
       referenceClass = Value(referenceClass),
       timestamp = Value(timestamp);
  static Insertable<ReferenceRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? userId,
    Expression<int>? referenceValueMgDl,
    Expression<int>? referenceClass,
    Expression<double>? deviceMgDl,
    Expression<int>? deviceClass,
    Expression<int>? deviceConfidence,
    Expression<DateTime>? timestamp,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastModified,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (userId != null) 'user_id': userId,
      if (referenceValueMgDl != null)
        'reference_value_mg_dl': referenceValueMgDl,
      if (referenceClass != null) 'reference_class': referenceClass,
      if (deviceMgDl != null) 'device_mg_dl': deviceMgDl,
      if (deviceClass != null) 'device_class': deviceClass,
      if (deviceConfidence != null) 'device_confidence': deviceConfidence,
      if (timestamp != null) 'timestamp': timestamp,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastModified != null) 'last_modified': lastModified,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ReferenceReadingsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int?>? userId,
    Value<int>? referenceValueMgDl,
    Value<int>? referenceClass,
    Value<double?>? deviceMgDl,
    Value<int?>? deviceClass,
    Value<int?>? deviceConfidence,
    Value<DateTime>? timestamp,
    Value<int>? syncStatus,
    Value<DateTime>? lastModified,
    Value<bool>? isDeleted,
  }) {
    return ReferenceReadingsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      referenceValueMgDl: referenceValueMgDl ?? this.referenceValueMgDl,
      referenceClass: referenceClass ?? this.referenceClass,
      deviceMgDl: deviceMgDl ?? this.deviceMgDl,
      deviceClass: deviceClass ?? this.deviceClass,
      deviceConfidence: deviceConfidence ?? this.deviceConfidence,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (referenceValueMgDl.present) {
      map['reference_value_mg_dl'] = Variable<int>(referenceValueMgDl.value);
    }
    if (referenceClass.present) {
      map['reference_class'] = Variable<int>(referenceClass.value);
    }
    if (deviceMgDl.present) {
      map['device_mg_dl'] = Variable<double>(deviceMgDl.value);
    }
    if (deviceClass.present) {
      map['device_class'] = Variable<int>(deviceClass.value);
    }
    if (deviceConfidence.present) {
      map['device_confidence'] = Variable<int>(deviceConfidence.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceReadingsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('userId: $userId, ')
          ..write('referenceValueMgDl: $referenceValueMgDl, ')
          ..write('referenceClass: $referenceClass, ')
          ..write('deviceMgDl: $deviceMgDl, ')
          ..write('deviceClass: $deviceClass, ')
          ..write('deviceConfidence: $deviceConfidence, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastModified: $lastModified, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordSaltMeta = const VerificationMeta(
    'passwordSalt',
  );
  @override
  late final GeneratedColumn<String> passwordSalt = GeneratedColumn<String>(
    'password_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pendingSync),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    username,
    passwordHash,
    passwordSalt,
    createdAt,
    syncStatus,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('password_salt')) {
      context.handle(
        _passwordSaltMeta,
        passwordSalt.isAcceptableOrUnknown(
          data['password_salt']!,
          _passwordSaltMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordSaltMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      passwordSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_salt'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final int id;
  final int? remoteId;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final DateTime createdAt;
  final int syncStatus;
  final DateTime? lastSyncedAt;
  const UserRow({
    required this.id,
    this.remoteId,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
    required this.syncStatus,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['password_salt'] = Variable<String>(passwordSalt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      username: Value(username),
      passwordHash: Value(passwordHash),
      passwordSalt: Value(passwordSalt),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      passwordSalt: serializer.fromJson<String>(json['passwordSalt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<int?>(remoteId),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'passwordSalt': serializer.toJson<String>(passwordSalt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  UserRow copyWith({
    int? id,
    Value<int?> remoteId = const Value.absent(),
    String? username,
    String? passwordHash,
    String? passwordSalt,
    DateTime? createdAt,
    int? syncStatus,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => UserRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSalt: data.passwordSalt.present
          ? data.passwordSalt.value
          : this.passwordSalt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    username,
    passwordHash,
    passwordSalt,
    createdAt,
    syncStatus,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.passwordSalt == this.passwordSalt &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<int> id;
  final Value<int?> remoteId;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String> passwordSalt;
  final Value<DateTime> createdAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSalt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String username,
    required String passwordHash,
    required String passwordSalt,
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  }) : username = Value(username),
       passwordHash = Value(passwordHash),
       passwordSalt = Value(passwordSalt),
       createdAt = Value(createdAt);
  static Insertable<UserRow> custom({
    Expression<int>? id,
    Expression<int>? remoteId,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? passwordSalt,
    Expression<DateTime>? createdAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<int?>? remoteId,
    Value<String>? username,
    Value<String>? passwordHash,
    Value<String>? passwordSalt,
    Value<DateTime>? createdAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncedAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (passwordSalt.present) {
      map['password_salt'] = Variable<String>(passwordSalt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $ReferenceReadingsTable referenceReadings =
      $ReferenceReadingsTable(this);
  late final $UsersTable users = $UsersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readings,
    referenceReadings,
    users,
  ];
}

typedef $$ReadingsTableCreateCompanionBuilder =
    ReadingsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int?> userId,
      required DateTime timestamp,
      required double mgDl,
      required int glucoseClass,
      required int confidence,
      Value<int> syncStatus,
      Value<DateTime> lastModified,
      Value<bool> isDeleted,
    });
typedef $$ReadingsTableUpdateCompanionBuilder =
    ReadingsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int?> userId,
      Value<DateTime> timestamp,
      Value<double> mgDl,
      Value<int> glucoseClass,
      Value<int> confidence,
      Value<int> syncStatus,
      Value<DateTime> lastModified,
      Value<bool> isDeleted,
    });

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mgDl => $composableBuilder(
    column: $table.mgDl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get glucoseClass => $composableBuilder(
    column: $table.glucoseClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mgDl => $composableBuilder(
    column: $table.mgDl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get glucoseClass => $composableBuilder(
    column: $table.glucoseClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get mgDl =>
      $composableBuilder(column: $table.mgDl, builder: (column) => column);

  GeneratedColumn<int> get glucoseClass => $composableBuilder(
    column: $table.glucoseClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingsTable,
          ReadingRow,
          $$ReadingsTableFilterComposer,
          $$ReadingsTableOrderingComposer,
          $$ReadingsTableAnnotationComposer,
          $$ReadingsTableCreateCompanionBuilder,
          $$ReadingsTableUpdateCompanionBuilder,
          (
            ReadingRow,
            BaseReferences<_$AppDatabase, $ReadingsTable, ReadingRow>,
          ),
          ReadingRow,
          PrefetchHooks Function()
        > {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> mgDl = const Value.absent(),
                Value<int> glucoseClass = const Value.absent(),
                Value<int> confidence = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => ReadingsCompanion(
                id: id,
                uuid: uuid,
                userId: userId,
                timestamp: timestamp,
                mgDl: mgDl,
                glucoseClass: glucoseClass,
                confidence: confidence,
                syncStatus: syncStatus,
                lastModified: lastModified,
                isDeleted: isDeleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                required DateTime timestamp,
                required double mgDl,
                required int glucoseClass,
                required int confidence,
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => ReadingsCompanion.insert(
                id: id,
                uuid: uuid,
                userId: userId,
                timestamp: timestamp,
                mgDl: mgDl,
                glucoseClass: glucoseClass,
                confidence: confidence,
                syncStatus: syncStatus,
                lastModified: lastModified,
                isDeleted: isDeleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingsTable,
      ReadingRow,
      $$ReadingsTableFilterComposer,
      $$ReadingsTableOrderingComposer,
      $$ReadingsTableAnnotationComposer,
      $$ReadingsTableCreateCompanionBuilder,
      $$ReadingsTableUpdateCompanionBuilder,
      (ReadingRow, BaseReferences<_$AppDatabase, $ReadingsTable, ReadingRow>),
      ReadingRow,
      PrefetchHooks Function()
    >;
typedef $$ReferenceReadingsTableCreateCompanionBuilder =
    ReferenceReadingsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int?> userId,
      required int referenceValueMgDl,
      required int referenceClass,
      Value<double?> deviceMgDl,
      Value<int?> deviceClass,
      Value<int?> deviceConfidence,
      required DateTime timestamp,
      Value<int> syncStatus,
      Value<DateTime> lastModified,
      Value<bool> isDeleted,
    });
typedef $$ReferenceReadingsTableUpdateCompanionBuilder =
    ReferenceReadingsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int?> userId,
      Value<int> referenceValueMgDl,
      Value<int> referenceClass,
      Value<double?> deviceMgDl,
      Value<int?> deviceClass,
      Value<int?> deviceConfidence,
      Value<DateTime> timestamp,
      Value<int> syncStatus,
      Value<DateTime> lastModified,
      Value<bool> isDeleted,
    });

class $$ReferenceReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReferenceReadingsTable> {
  $$ReferenceReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceValueMgDl => $composableBuilder(
    column: $table.referenceValueMgDl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceClass => $composableBuilder(
    column: $table.referenceClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deviceMgDl => $composableBuilder(
    column: $table.deviceMgDl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceClass => $composableBuilder(
    column: $table.deviceClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceConfidence => $composableBuilder(
    column: $table.deviceConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReferenceReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReferenceReadingsTable> {
  $$ReferenceReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceValueMgDl => $composableBuilder(
    column: $table.referenceValueMgDl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceClass => $composableBuilder(
    column: $table.referenceClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deviceMgDl => $composableBuilder(
    column: $table.deviceMgDl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceClass => $composableBuilder(
    column: $table.deviceClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceConfidence => $composableBuilder(
    column: $table.deviceConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReferenceReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReferenceReadingsTable> {
  $$ReferenceReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get referenceValueMgDl => $composableBuilder(
    column: $table.referenceValueMgDl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get referenceClass => $composableBuilder(
    column: $table.referenceClass,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deviceMgDl => $composableBuilder(
    column: $table.deviceMgDl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deviceClass => $composableBuilder(
    column: $table.deviceClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deviceConfidence => $composableBuilder(
    column: $table.deviceConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ReferenceReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReferenceReadingsTable,
          ReferenceRow,
          $$ReferenceReadingsTableFilterComposer,
          $$ReferenceReadingsTableOrderingComposer,
          $$ReferenceReadingsTableAnnotationComposer,
          $$ReferenceReadingsTableCreateCompanionBuilder,
          $$ReferenceReadingsTableUpdateCompanionBuilder,
          (
            ReferenceRow,
            BaseReferences<
              _$AppDatabase,
              $ReferenceReadingsTable,
              ReferenceRow
            >,
          ),
          ReferenceRow,
          PrefetchHooks Function()
        > {
  $$ReferenceReadingsTableTableManager(
    _$AppDatabase db,
    $ReferenceReadingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferenceReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferenceReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferenceReadingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int> referenceValueMgDl = const Value.absent(),
                Value<int> referenceClass = const Value.absent(),
                Value<double?> deviceMgDl = const Value.absent(),
                Value<int?> deviceClass = const Value.absent(),
                Value<int?> deviceConfidence = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => ReferenceReadingsCompanion(
                id: id,
                uuid: uuid,
                userId: userId,
                referenceValueMgDl: referenceValueMgDl,
                referenceClass: referenceClass,
                deviceMgDl: deviceMgDl,
                deviceClass: deviceClass,
                deviceConfidence: deviceConfidence,
                timestamp: timestamp,
                syncStatus: syncStatus,
                lastModified: lastModified,
                isDeleted: isDeleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                required int referenceValueMgDl,
                required int referenceClass,
                Value<double?> deviceMgDl = const Value.absent(),
                Value<int?> deviceClass = const Value.absent(),
                Value<int?> deviceConfidence = const Value.absent(),
                required DateTime timestamp,
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => ReferenceReadingsCompanion.insert(
                id: id,
                uuid: uuid,
                userId: userId,
                referenceValueMgDl: referenceValueMgDl,
                referenceClass: referenceClass,
                deviceMgDl: deviceMgDl,
                deviceClass: deviceClass,
                deviceConfidence: deviceConfidence,
                timestamp: timestamp,
                syncStatus: syncStatus,
                lastModified: lastModified,
                isDeleted: isDeleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReferenceReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReferenceReadingsTable,
      ReferenceRow,
      $$ReferenceReadingsTableFilterComposer,
      $$ReferenceReadingsTableOrderingComposer,
      $$ReferenceReadingsTableAnnotationComposer,
      $$ReferenceReadingsTableCreateCompanionBuilder,
      $$ReferenceReadingsTableUpdateCompanionBuilder,
      (
        ReferenceRow,
        BaseReferences<_$AppDatabase, $ReferenceReadingsTable, ReferenceRow>,
      ),
      ReferenceRow,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int?> remoteId,
      required String username,
      required String passwordHash,
      required String passwordSalt,
      required DateTime createdAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncedAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int?> remoteId,
      Value<String> username,
      Value<String> passwordHash,
      Value<String> passwordSalt,
      Value<DateTime> createdAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncedAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
          UserRow,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> passwordSalt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                remoteId: remoteId,
                username: username,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                createdAt: createdAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required String username,
                required String passwordHash,
                required String passwordSalt,
                required DateTime createdAt,
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                remoteId: remoteId,
                username: username,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                createdAt: createdAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
      UserRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$ReferenceReadingsTableTableManager get referenceReadings =>
      $$ReferenceReadingsTableTableManager(_db, _db.referenceReadings);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
}
