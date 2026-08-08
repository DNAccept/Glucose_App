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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    mgDl,
    glucoseClass,
    confidence,
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
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }
}

class ReadingRow extends DataClass implements Insertable<ReadingRow> {
  final int id;
  final DateTime timestamp;
  final double mgDl;

  /// 0 = low, 1 = normal, 2 = high — matches [GlucoseClass.wireValue].
  final int glucoseClass;
  final int confidence;
  const ReadingRow({
    required this.id,
    required this.timestamp,
    required this.mgDl,
    required this.glucoseClass,
    required this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['mg_dl'] = Variable<double>(mgDl);
    map['glucose_class'] = Variable<int>(glucoseClass);
    map['confidence'] = Variable<int>(confidence);
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      mgDl: Value(mgDl),
      glucoseClass: Value(glucoseClass),
      confidence: Value(confidence),
    );
  }

  factory ReadingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRow(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      mgDl: serializer.fromJson<double>(json['mgDl']),
      glucoseClass: serializer.fromJson<int>(json['glucoseClass']),
      confidence: serializer.fromJson<int>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'mgDl': serializer.toJson<double>(mgDl),
      'glucoseClass': serializer.toJson<int>(glucoseClass),
      'confidence': serializer.toJson<int>(confidence),
    };
  }

  ReadingRow copyWith({
    int? id,
    DateTime? timestamp,
    double? mgDl,
    int? glucoseClass,
    int? confidence,
  }) => ReadingRow(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    mgDl: mgDl ?? this.mgDl,
    glucoseClass: glucoseClass ?? this.glucoseClass,
    confidence: confidence ?? this.confidence,
  );
  ReadingRow copyWithCompanion(ReadingsCompanion data) {
    return ReadingRow(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      mgDl: data.mgDl.present ? data.mgDl.value : this.mgDl,
      glucoseClass: data.glucoseClass.present
          ? data.glucoseClass.value
          : this.glucoseClass,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRow(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('mgDl: $mgDl, ')
          ..write('glucoseClass: $glucoseClass, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, mgDl, glucoseClass, confidence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRow &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.mgDl == this.mgDl &&
          other.glucoseClass == this.glucoseClass &&
          other.confidence == this.confidence);
}

class ReadingsCompanion extends UpdateCompanion<ReadingRow> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<double> mgDl;
  final Value<int> glucoseClass;
  final Value<int> confidence;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.mgDl = const Value.absent(),
    this.glucoseClass = const Value.absent(),
    this.confidence = const Value.absent(),
  });
  ReadingsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required double mgDl,
    required int glucoseClass,
    required int confidence,
  }) : timestamp = Value(timestamp),
       mgDl = Value(mgDl),
       glucoseClass = Value(glucoseClass),
       confidence = Value(confidence);
  static Insertable<ReadingRow> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? mgDl,
    Expression<int>? glucoseClass,
    Expression<int>? confidence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (mgDl != null) 'mg_dl': mgDl,
      if (glucoseClass != null) 'glucose_class': glucoseClass,
      if (confidence != null) 'confidence': confidence,
    });
  }

  ReadingsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<double>? mgDl,
    Value<int>? glucoseClass,
    Value<int>? confidence,
  }) {
    return ReadingsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mgDl: mgDl ?? this.mgDl,
      glucoseClass: glucoseClass ?? this.glucoseClass,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('mgDl: $mgDl, ')
          ..write('glucoseClass: $glucoseClass, ')
          ..write('confidence: $confidence')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    referenceValueMgDl,
    referenceClass,
    deviceMgDl,
    deviceClass,
    deviceConfidence,
    timestamp,
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
    );
  }

  @override
  $ReferenceReadingsTable createAlias(String alias) {
    return $ReferenceReadingsTable(attachedDatabase, alias);
  }
}

class ReferenceRow extends DataClass implements Insertable<ReferenceRow> {
  final int id;
  final int referenceValueMgDl;
  final int referenceClass;
  final double? deviceMgDl;
  final int? deviceClass;
  final int? deviceConfidence;
  final DateTime timestamp;
  const ReferenceRow({
    required this.id,
    required this.referenceValueMgDl,
    required this.referenceClass,
    this.deviceMgDl,
    this.deviceClass,
    this.deviceConfidence,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    return map;
  }

  ReferenceReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReferenceReadingsCompanion(
      id: Value(id),
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
    );
  }

  factory ReferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceRow(
      id: serializer.fromJson<int>(json['id']),
      referenceValueMgDl: serializer.fromJson<int>(json['referenceValueMgDl']),
      referenceClass: serializer.fromJson<int>(json['referenceClass']),
      deviceMgDl: serializer.fromJson<double?>(json['deviceMgDl']),
      deviceClass: serializer.fromJson<int?>(json['deviceClass']),
      deviceConfidence: serializer.fromJson<int?>(json['deviceConfidence']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'referenceValueMgDl': serializer.toJson<int>(referenceValueMgDl),
      'referenceClass': serializer.toJson<int>(referenceClass),
      'deviceMgDl': serializer.toJson<double?>(deviceMgDl),
      'deviceClass': serializer.toJson<int?>(deviceClass),
      'deviceConfidence': serializer.toJson<int?>(deviceConfidence),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ReferenceRow copyWith({
    int? id,
    int? referenceValueMgDl,
    int? referenceClass,
    Value<double?> deviceMgDl = const Value.absent(),
    Value<int?> deviceClass = const Value.absent(),
    Value<int?> deviceConfidence = const Value.absent(),
    DateTime? timestamp,
  }) => ReferenceRow(
    id: id ?? this.id,
    referenceValueMgDl: referenceValueMgDl ?? this.referenceValueMgDl,
    referenceClass: referenceClass ?? this.referenceClass,
    deviceMgDl: deviceMgDl.present ? deviceMgDl.value : this.deviceMgDl,
    deviceClass: deviceClass.present ? deviceClass.value : this.deviceClass,
    deviceConfidence: deviceConfidence.present
        ? deviceConfidence.value
        : this.deviceConfidence,
    timestamp: timestamp ?? this.timestamp,
  );
  ReferenceRow copyWithCompanion(ReferenceReadingsCompanion data) {
    return ReferenceRow(
      id: data.id.present ? data.id.value : this.id,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceRow(')
          ..write('id: $id, ')
          ..write('referenceValueMgDl: $referenceValueMgDl, ')
          ..write('referenceClass: $referenceClass, ')
          ..write('deviceMgDl: $deviceMgDl, ')
          ..write('deviceClass: $deviceClass, ')
          ..write('deviceConfidence: $deviceConfidence, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    referenceValueMgDl,
    referenceClass,
    deviceMgDl,
    deviceClass,
    deviceConfidence,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceRow &&
          other.id == this.id &&
          other.referenceValueMgDl == this.referenceValueMgDl &&
          other.referenceClass == this.referenceClass &&
          other.deviceMgDl == this.deviceMgDl &&
          other.deviceClass == this.deviceClass &&
          other.deviceConfidence == this.deviceConfidence &&
          other.timestamp == this.timestamp);
}

class ReferenceReadingsCompanion extends UpdateCompanion<ReferenceRow> {
  final Value<int> id;
  final Value<int> referenceValueMgDl;
  final Value<int> referenceClass;
  final Value<double?> deviceMgDl;
  final Value<int?> deviceClass;
  final Value<int?> deviceConfidence;
  final Value<DateTime> timestamp;
  const ReferenceReadingsCompanion({
    this.id = const Value.absent(),
    this.referenceValueMgDl = const Value.absent(),
    this.referenceClass = const Value.absent(),
    this.deviceMgDl = const Value.absent(),
    this.deviceClass = const Value.absent(),
    this.deviceConfidence = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ReferenceReadingsCompanion.insert({
    this.id = const Value.absent(),
    required int referenceValueMgDl,
    required int referenceClass,
    this.deviceMgDl = const Value.absent(),
    this.deviceClass = const Value.absent(),
    this.deviceConfidence = const Value.absent(),
    required DateTime timestamp,
  }) : referenceValueMgDl = Value(referenceValueMgDl),
       referenceClass = Value(referenceClass),
       timestamp = Value(timestamp);
  static Insertable<ReferenceRow> custom({
    Expression<int>? id,
    Expression<int>? referenceValueMgDl,
    Expression<int>? referenceClass,
    Expression<double>? deviceMgDl,
    Expression<int>? deviceClass,
    Expression<int>? deviceConfidence,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (referenceValueMgDl != null)
        'reference_value_mg_dl': referenceValueMgDl,
      if (referenceClass != null) 'reference_class': referenceClass,
      if (deviceMgDl != null) 'device_mg_dl': deviceMgDl,
      if (deviceClass != null) 'device_class': deviceClass,
      if (deviceConfidence != null) 'device_confidence': deviceConfidence,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ReferenceReadingsCompanion copyWith({
    Value<int>? id,
    Value<int>? referenceValueMgDl,
    Value<int>? referenceClass,
    Value<double?>? deviceMgDl,
    Value<int?>? deviceClass,
    Value<int?>? deviceConfidence,
    Value<DateTime>? timestamp,
  }) {
    return ReferenceReadingsCompanion(
      id: id ?? this.id,
      referenceValueMgDl: referenceValueMgDl ?? this.referenceValueMgDl,
      referenceClass: referenceClass ?? this.referenceClass,
      deviceMgDl: deviceMgDl ?? this.deviceMgDl,
      deviceClass: deviceClass ?? this.deviceClass,
      deviceConfidence: deviceConfidence ?? this.deviceConfidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceReadingsCompanion(')
          ..write('id: $id, ')
          ..write('referenceValueMgDl: $referenceValueMgDl, ')
          ..write('referenceClass: $referenceClass, ')
          ..write('deviceMgDl: $deviceMgDl, ')
          ..write('deviceClass: $deviceClass, ')
          ..write('deviceConfidence: $deviceConfidence, ')
          ..write('timestamp: $timestamp')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    passwordHash,
    passwordSalt,
    createdAt,
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
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final int id;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final DateTime createdAt;
  const UserRow({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['password_salt'] = Variable<String>(passwordSalt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      passwordHash: Value(passwordHash),
      passwordSalt: Value(passwordSalt),
      createdAt: Value(createdAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      passwordSalt: serializer.fromJson<String>(json['passwordSalt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'passwordSalt': serializer.toJson<String>(passwordSalt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserRow copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    DateTime? createdAt,
  }) => UserRow(
    id: id ?? this.id,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    createdAt: createdAt ?? this.createdAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSalt: data.passwordSalt.present
          ? data.passwordSalt.value
          : this.passwordSalt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, passwordHash, passwordSalt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.passwordSalt == this.passwordSalt &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String> passwordSalt;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSalt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String passwordHash,
    required String passwordSalt,
    required DateTime createdAt,
  }) : username = Value(username),
       passwordHash = Value(passwordHash),
       passwordSalt = Value(passwordSalt),
       createdAt = Value(createdAt);
  static Insertable<UserRow> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? passwordSalt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? passwordHash,
    Value<String>? passwordSalt,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('createdAt: $createdAt')
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
      required DateTime timestamp,
      required double mgDl,
      required int glucoseClass,
      required int confidence,
    });
typedef $$ReadingsTableUpdateCompanionBuilder =
    ReadingsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<double> mgDl,
      Value<int> glucoseClass,
      Value<int> confidence,
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
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> mgDl = const Value.absent(),
                Value<int> glucoseClass = const Value.absent(),
                Value<int> confidence = const Value.absent(),
              }) => ReadingsCompanion(
                id: id,
                timestamp: timestamp,
                mgDl: mgDl,
                glucoseClass: glucoseClass,
                confidence: confidence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required double mgDl,
                required int glucoseClass,
                required int confidence,
              }) => ReadingsCompanion.insert(
                id: id,
                timestamp: timestamp,
                mgDl: mgDl,
                glucoseClass: glucoseClass,
                confidence: confidence,
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
      required int referenceValueMgDl,
      required int referenceClass,
      Value<double?> deviceMgDl,
      Value<int?> deviceClass,
      Value<int?> deviceConfidence,
      required DateTime timestamp,
    });
typedef $$ReferenceReadingsTableUpdateCompanionBuilder =
    ReferenceReadingsCompanion Function({
      Value<int> id,
      Value<int> referenceValueMgDl,
      Value<int> referenceClass,
      Value<double?> deviceMgDl,
      Value<int?> deviceClass,
      Value<int?> deviceConfidence,
      Value<DateTime> timestamp,
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
                Value<int> referenceValueMgDl = const Value.absent(),
                Value<int> referenceClass = const Value.absent(),
                Value<double?> deviceMgDl = const Value.absent(),
                Value<int?> deviceClass = const Value.absent(),
                Value<int?> deviceConfidence = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => ReferenceReadingsCompanion(
                id: id,
                referenceValueMgDl: referenceValueMgDl,
                referenceClass: referenceClass,
                deviceMgDl: deviceMgDl,
                deviceClass: deviceClass,
                deviceConfidence: deviceConfidence,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int referenceValueMgDl,
                required int referenceClass,
                Value<double?> deviceMgDl = const Value.absent(),
                Value<int?> deviceClass = const Value.absent(),
                Value<int?> deviceConfidence = const Value.absent(),
                required DateTime timestamp,
              }) => ReferenceReadingsCompanion.insert(
                id: id,
                referenceValueMgDl: referenceValueMgDl,
                referenceClass: referenceClass,
                deviceMgDl: deviceMgDl,
                deviceClass: deviceClass,
                deviceConfidence: deviceConfidence,
                timestamp: timestamp,
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
      required String username,
      required String passwordHash,
      required String passwordSalt,
      required DateTime createdAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> username,
      Value<String> passwordHash,
      Value<String> passwordSalt,
      Value<DateTime> createdAt,
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
                Value<String> username = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> passwordSalt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                required String passwordHash,
                required String passwordSalt,
                required DateTime createdAt,
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                createdAt: createdAt,
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
