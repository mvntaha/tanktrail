// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalTripsTable extends LocalTrips
    with TableInfo<$LocalTripsTable, LocalTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driverIdMeta = const VerificationMeta(
    'driverId',
  );
  @override
  late final GeneratedColumn<String> driverId = GeneratedColumn<String>(
    'driver_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driverNameMeta = const VerificationMeta(
    'driverName',
  );
  @override
  late final GeneratedColumn<String> driverName = GeneratedColumn<String>(
    'driver_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startOdoMeta = const VerificationMeta(
    'startOdo',
  );
  @override
  late final GeneratedColumn<int> startOdo = GeneratedColumn<int>(
    'start_odo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLatMeta = const VerificationMeta(
    'startLat',
  );
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
    'start_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLngMeta = const VerificationMeta(
    'startLng',
  );
  @override
  late final GeneratedColumn<double> startLng = GeneratedColumn<double>(
    'start_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAccMeta = const VerificationMeta(
    'startAcc',
  );
  @override
  late final GeneratedColumn<double> startAcc = GeneratedColumn<double>(
    'start_acc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMockMeta = const VerificationMeta(
    'startMock',
  );
  @override
  late final GeneratedColumn<bool> startMock = GeneratedColumn<bool>(
    'start_mock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("start_mock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _endOdoMeta = const VerificationMeta('endOdo');
  @override
  late final GeneratedColumn<int> endOdo = GeneratedColumn<int>(
    'end_odo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLatMeta = const VerificationMeta('endLat');
  @override
  late final GeneratedColumn<double> endLat = GeneratedColumn<double>(
    'end_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLngMeta = const VerificationMeta('endLng');
  @override
  late final GeneratedColumn<double> endLng = GeneratedColumn<double>(
    'end_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAccMeta = const VerificationMeta('endAcc');
  @override
  late final GeneratedColumn<double> endAcc = GeneratedColumn<double>(
    'end_acc',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMockMeta = const VerificationMeta(
    'endMock',
  );
  @override
  late final GeneratedColumn<bool> endMock = GeneratedColumn<bool>(
    'end_mock',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("end_mock" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    driverId,
    driverName,
    status,
    startOdo,
    startedAt,
    startLat,
    startLng,
    startAcc,
    startMock,
    endOdo,
    endedAt,
    endLat,
    endLng,
    endAcc,
    endMock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('driver_id')) {
      context.handle(
        _driverIdMeta,
        driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_driverIdMeta);
    }
    if (data.containsKey('driver_name')) {
      context.handle(
        _driverNameMeta,
        driverName.isAcceptableOrUnknown(data['driver_name']!, _driverNameMeta),
      );
    } else if (isInserting) {
      context.missing(_driverNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('start_odo')) {
      context.handle(
        _startOdoMeta,
        startOdo.isAcceptableOrUnknown(data['start_odo']!, _startOdoMeta),
      );
    } else if (isInserting) {
      context.missing(_startOdoMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('start_lat')) {
      context.handle(
        _startLatMeta,
        startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta),
      );
    } else if (isInserting) {
      context.missing(_startLatMeta);
    }
    if (data.containsKey('start_lng')) {
      context.handle(
        _startLngMeta,
        startLng.isAcceptableOrUnknown(data['start_lng']!, _startLngMeta),
      );
    } else if (isInserting) {
      context.missing(_startLngMeta);
    }
    if (data.containsKey('start_acc')) {
      context.handle(
        _startAccMeta,
        startAcc.isAcceptableOrUnknown(data['start_acc']!, _startAccMeta),
      );
    } else if (isInserting) {
      context.missing(_startAccMeta);
    }
    if (data.containsKey('start_mock')) {
      context.handle(
        _startMockMeta,
        startMock.isAcceptableOrUnknown(data['start_mock']!, _startMockMeta),
      );
    } else if (isInserting) {
      context.missing(_startMockMeta);
    }
    if (data.containsKey('end_odo')) {
      context.handle(
        _endOdoMeta,
        endOdo.isAcceptableOrUnknown(data['end_odo']!, _endOdoMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('end_lat')) {
      context.handle(
        _endLatMeta,
        endLat.isAcceptableOrUnknown(data['end_lat']!, _endLatMeta),
      );
    }
    if (data.containsKey('end_lng')) {
      context.handle(
        _endLngMeta,
        endLng.isAcceptableOrUnknown(data['end_lng']!, _endLngMeta),
      );
    }
    if (data.containsKey('end_acc')) {
      context.handle(
        _endAccMeta,
        endAcc.isAcceptableOrUnknown(data['end_acc']!, _endAccMeta),
      );
    }
    if (data.containsKey('end_mock')) {
      context.handle(
        _endMockMeta,
        endMock.isAcceptableOrUnknown(data['end_mock']!, _endMockMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      driverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_id'],
      )!,
      driverName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startOdo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_odo'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      startLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lat'],
      )!,
      startLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lng'],
      )!,
      startAcc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_acc'],
      )!,
      startMock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}start_mock'],
      )!,
      endOdo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_odo'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      endLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lat'],
      ),
      endLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lng'],
      ),
      endAcc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_acc'],
      ),
      endMock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}end_mock'],
      ),
    );
  }

  @override
  $LocalTripsTable createAlias(String alias) {
    return $LocalTripsTable(attachedDatabase, alias);
  }
}

class LocalTrip extends DataClass implements Insertable<LocalTrip> {
  final String id;
  final String driverId;
  final String driverName;

  /// 'open' until the end reading and photo are saved, then 'closed'.
  final String status;
  final int startOdo;
  final DateTime startedAt;
  final double startLat;
  final double startLng;
  final double startAcc;
  final bool startMock;
  final int? endOdo;
  final DateTime? endedAt;
  final double? endLat;
  final double? endLng;
  final double? endAcc;
  final bool? endMock;
  const LocalTrip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.status,
    required this.startOdo,
    required this.startedAt,
    required this.startLat,
    required this.startLng,
    required this.startAcc,
    required this.startMock,
    this.endOdo,
    this.endedAt,
    this.endLat,
    this.endLng,
    this.endAcc,
    this.endMock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['driver_id'] = Variable<String>(driverId);
    map['driver_name'] = Variable<String>(driverName);
    map['status'] = Variable<String>(status);
    map['start_odo'] = Variable<int>(startOdo);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['start_lat'] = Variable<double>(startLat);
    map['start_lng'] = Variable<double>(startLng);
    map['start_acc'] = Variable<double>(startAcc);
    map['start_mock'] = Variable<bool>(startMock);
    if (!nullToAbsent || endOdo != null) {
      map['end_odo'] = Variable<int>(endOdo);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || endLat != null) {
      map['end_lat'] = Variable<double>(endLat);
    }
    if (!nullToAbsent || endLng != null) {
      map['end_lng'] = Variable<double>(endLng);
    }
    if (!nullToAbsent || endAcc != null) {
      map['end_acc'] = Variable<double>(endAcc);
    }
    if (!nullToAbsent || endMock != null) {
      map['end_mock'] = Variable<bool>(endMock);
    }
    return map;
  }

  LocalTripsCompanion toCompanion(bool nullToAbsent) {
    return LocalTripsCompanion(
      id: Value(id),
      driverId: Value(driverId),
      driverName: Value(driverName),
      status: Value(status),
      startOdo: Value(startOdo),
      startedAt: Value(startedAt),
      startLat: Value(startLat),
      startLng: Value(startLng),
      startAcc: Value(startAcc),
      startMock: Value(startMock),
      endOdo: endOdo == null && nullToAbsent
          ? const Value.absent()
          : Value(endOdo),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      endLat: endLat == null && nullToAbsent
          ? const Value.absent()
          : Value(endLat),
      endLng: endLng == null && nullToAbsent
          ? const Value.absent()
          : Value(endLng),
      endAcc: endAcc == null && nullToAbsent
          ? const Value.absent()
          : Value(endAcc),
      endMock: endMock == null && nullToAbsent
          ? const Value.absent()
          : Value(endMock),
    );
  }

  factory LocalTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrip(
      id: serializer.fromJson<String>(json['id']),
      driverId: serializer.fromJson<String>(json['driverId']),
      driverName: serializer.fromJson<String>(json['driverName']),
      status: serializer.fromJson<String>(json['status']),
      startOdo: serializer.fromJson<int>(json['startOdo']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      startLat: serializer.fromJson<double>(json['startLat']),
      startLng: serializer.fromJson<double>(json['startLng']),
      startAcc: serializer.fromJson<double>(json['startAcc']),
      startMock: serializer.fromJson<bool>(json['startMock']),
      endOdo: serializer.fromJson<int?>(json['endOdo']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      endLat: serializer.fromJson<double?>(json['endLat']),
      endLng: serializer.fromJson<double?>(json['endLng']),
      endAcc: serializer.fromJson<double?>(json['endAcc']),
      endMock: serializer.fromJson<bool?>(json['endMock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'driverId': serializer.toJson<String>(driverId),
      'driverName': serializer.toJson<String>(driverName),
      'status': serializer.toJson<String>(status),
      'startOdo': serializer.toJson<int>(startOdo),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'startLat': serializer.toJson<double>(startLat),
      'startLng': serializer.toJson<double>(startLng),
      'startAcc': serializer.toJson<double>(startAcc),
      'startMock': serializer.toJson<bool>(startMock),
      'endOdo': serializer.toJson<int?>(endOdo),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'endLat': serializer.toJson<double?>(endLat),
      'endLng': serializer.toJson<double?>(endLng),
      'endAcc': serializer.toJson<double?>(endAcc),
      'endMock': serializer.toJson<bool?>(endMock),
    };
  }

  LocalTrip copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? status,
    int? startOdo,
    DateTime? startedAt,
    double? startLat,
    double? startLng,
    double? startAcc,
    bool? startMock,
    Value<int?> endOdo = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<double?> endLat = const Value.absent(),
    Value<double?> endLng = const Value.absent(),
    Value<double?> endAcc = const Value.absent(),
    Value<bool?> endMock = const Value.absent(),
  }) => LocalTrip(
    id: id ?? this.id,
    driverId: driverId ?? this.driverId,
    driverName: driverName ?? this.driverName,
    status: status ?? this.status,
    startOdo: startOdo ?? this.startOdo,
    startedAt: startedAt ?? this.startedAt,
    startLat: startLat ?? this.startLat,
    startLng: startLng ?? this.startLng,
    startAcc: startAcc ?? this.startAcc,
    startMock: startMock ?? this.startMock,
    endOdo: endOdo.present ? endOdo.value : this.endOdo,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    endLat: endLat.present ? endLat.value : this.endLat,
    endLng: endLng.present ? endLng.value : this.endLng,
    endAcc: endAcc.present ? endAcc.value : this.endAcc,
    endMock: endMock.present ? endMock.value : this.endMock,
  );
  LocalTrip copyWithCompanion(LocalTripsCompanion data) {
    return LocalTrip(
      id: data.id.present ? data.id.value : this.id,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      driverName: data.driverName.present
          ? data.driverName.value
          : this.driverName,
      status: data.status.present ? data.status.value : this.status,
      startOdo: data.startOdo.present ? data.startOdo.value : this.startOdo,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLng: data.startLng.present ? data.startLng.value : this.startLng,
      startAcc: data.startAcc.present ? data.startAcc.value : this.startAcc,
      startMock: data.startMock.present ? data.startMock.value : this.startMock,
      endOdo: data.endOdo.present ? data.endOdo.value : this.endOdo,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      endLat: data.endLat.present ? data.endLat.value : this.endLat,
      endLng: data.endLng.present ? data.endLng.value : this.endLng,
      endAcc: data.endAcc.present ? data.endAcc.value : this.endAcc,
      endMock: data.endMock.present ? data.endMock.value : this.endMock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrip(')
          ..write('id: $id, ')
          ..write('driverId: $driverId, ')
          ..write('driverName: $driverName, ')
          ..write('status: $status, ')
          ..write('startOdo: $startOdo, ')
          ..write('startedAt: $startedAt, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('startAcc: $startAcc, ')
          ..write('startMock: $startMock, ')
          ..write('endOdo: $endOdo, ')
          ..write('endedAt: $endedAt, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('endAcc: $endAcc, ')
          ..write('endMock: $endMock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    driverId,
    driverName,
    status,
    startOdo,
    startedAt,
    startLat,
    startLng,
    startAcc,
    startMock,
    endOdo,
    endedAt,
    endLat,
    endLng,
    endAcc,
    endMock,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrip &&
          other.id == this.id &&
          other.driverId == this.driverId &&
          other.driverName == this.driverName &&
          other.status == this.status &&
          other.startOdo == this.startOdo &&
          other.startedAt == this.startedAt &&
          other.startLat == this.startLat &&
          other.startLng == this.startLng &&
          other.startAcc == this.startAcc &&
          other.startMock == this.startMock &&
          other.endOdo == this.endOdo &&
          other.endedAt == this.endedAt &&
          other.endLat == this.endLat &&
          other.endLng == this.endLng &&
          other.endAcc == this.endAcc &&
          other.endMock == this.endMock);
}

class LocalTripsCompanion extends UpdateCompanion<LocalTrip> {
  final Value<String> id;
  final Value<String> driverId;
  final Value<String> driverName;
  final Value<String> status;
  final Value<int> startOdo;
  final Value<DateTime> startedAt;
  final Value<double> startLat;
  final Value<double> startLng;
  final Value<double> startAcc;
  final Value<bool> startMock;
  final Value<int?> endOdo;
  final Value<DateTime?> endedAt;
  final Value<double?> endLat;
  final Value<double?> endLng;
  final Value<double?> endAcc;
  final Value<bool?> endMock;
  final Value<int> rowid;
  const LocalTripsCompanion({
    this.id = const Value.absent(),
    this.driverId = const Value.absent(),
    this.driverName = const Value.absent(),
    this.status = const Value.absent(),
    this.startOdo = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLng = const Value.absent(),
    this.startAcc = const Value.absent(),
    this.startMock = const Value.absent(),
    this.endOdo = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.endAcc = const Value.absent(),
    this.endMock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTripsCompanion.insert({
    required String id,
    required String driverId,
    required String driverName,
    required String status,
    required int startOdo,
    required DateTime startedAt,
    required double startLat,
    required double startLng,
    required double startAcc,
    required bool startMock,
    this.endOdo = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.endAcc = const Value.absent(),
    this.endMock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       driverId = Value(driverId),
       driverName = Value(driverName),
       status = Value(status),
       startOdo = Value(startOdo),
       startedAt = Value(startedAt),
       startLat = Value(startLat),
       startLng = Value(startLng),
       startAcc = Value(startAcc),
       startMock = Value(startMock);
  static Insertable<LocalTrip> custom({
    Expression<String>? id,
    Expression<String>? driverId,
    Expression<String>? driverName,
    Expression<String>? status,
    Expression<int>? startOdo,
    Expression<DateTime>? startedAt,
    Expression<double>? startLat,
    Expression<double>? startLng,
    Expression<double>? startAcc,
    Expression<bool>? startMock,
    Expression<int>? endOdo,
    Expression<DateTime>? endedAt,
    Expression<double>? endLat,
    Expression<double>? endLng,
    Expression<double>? endAcc,
    Expression<bool>? endMock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (driverId != null) 'driver_id': driverId,
      if (driverName != null) 'driver_name': driverName,
      if (status != null) 'status': status,
      if (startOdo != null) 'start_odo': startOdo,
      if (startedAt != null) 'started_at': startedAt,
      if (startLat != null) 'start_lat': startLat,
      if (startLng != null) 'start_lng': startLng,
      if (startAcc != null) 'start_acc': startAcc,
      if (startMock != null) 'start_mock': startMock,
      if (endOdo != null) 'end_odo': endOdo,
      if (endedAt != null) 'ended_at': endedAt,
      if (endLat != null) 'end_lat': endLat,
      if (endLng != null) 'end_lng': endLng,
      if (endAcc != null) 'end_acc': endAcc,
      if (endMock != null) 'end_mock': endMock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTripsCompanion copyWith({
    Value<String>? id,
    Value<String>? driverId,
    Value<String>? driverName,
    Value<String>? status,
    Value<int>? startOdo,
    Value<DateTime>? startedAt,
    Value<double>? startLat,
    Value<double>? startLng,
    Value<double>? startAcc,
    Value<bool>? startMock,
    Value<int?>? endOdo,
    Value<DateTime?>? endedAt,
    Value<double?>? endLat,
    Value<double?>? endLng,
    Value<double?>? endAcc,
    Value<bool?>? endMock,
    Value<int>? rowid,
  }) {
    return LocalTripsCompanion(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
      startOdo: startOdo ?? this.startOdo,
      startedAt: startedAt ?? this.startedAt,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      startAcc: startAcc ?? this.startAcc,
      startMock: startMock ?? this.startMock,
      endOdo: endOdo ?? this.endOdo,
      endedAt: endedAt ?? this.endedAt,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      endAcc: endAcc ?? this.endAcc,
      endMock: endMock ?? this.endMock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (driverId.present) {
      map['driver_id'] = Variable<String>(driverId.value);
    }
    if (driverName.present) {
      map['driver_name'] = Variable<String>(driverName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startOdo.present) {
      map['start_odo'] = Variable<int>(startOdo.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (startLat.present) {
      map['start_lat'] = Variable<double>(startLat.value);
    }
    if (startLng.present) {
      map['start_lng'] = Variable<double>(startLng.value);
    }
    if (startAcc.present) {
      map['start_acc'] = Variable<double>(startAcc.value);
    }
    if (startMock.present) {
      map['start_mock'] = Variable<bool>(startMock.value);
    }
    if (endOdo.present) {
      map['end_odo'] = Variable<int>(endOdo.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (endLat.present) {
      map['end_lat'] = Variable<double>(endLat.value);
    }
    if (endLng.present) {
      map['end_lng'] = Variable<double>(endLng.value);
    }
    if (endAcc.present) {
      map['end_acc'] = Variable<double>(endAcc.value);
    }
    if (endMock.present) {
      map['end_mock'] = Variable<bool>(endMock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripsCompanion(')
          ..write('id: $id, ')
          ..write('driverId: $driverId, ')
          ..write('driverName: $driverName, ')
          ..write('status: $status, ')
          ..write('startOdo: $startOdo, ')
          ..write('startedAt: $startedAt, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('startAcc: $startAcc, ')
          ..write('startMock: $startMock, ')
          ..write('endOdo: $endOdo, ')
          ..write('endedAt: $endedAt, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('endAcc: $endAcc, ')
          ..write('endMock: $endMock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEvidenceTable extends LocalEvidence
    with TableInfo<$LocalEvidenceTable, LocalEvidenceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEvidenceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<String> logId = GeneratedColumn<String>(
    'log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logKindMeta = const VerificationMeta(
    'logKind',
  );
  @override
  late final GeneratedColumn<String> logKind = GeneratedColumn<String>(
    'log_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtDeviceMeta = const VerificationMeta(
    'capturedAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAtDevice =
      GeneratedColumn<DateTime>(
        'captured_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accMeta = const VerificationMeta('acc');
  @override
  late final GeneratedColumn<double> acc = GeneratedColumn<double>(
    'acc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mockMeta = const VerificationMeta('mock');
  @override
  late final GeneratedColumn<bool> mock = GeneratedColumn<bool>(
    'mock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mock" IN (0, 1))',
    ),
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    logId,
    logKind,
    phase,
    type,
    filePath,
    sha256,
    capturedAtDevice,
    lat,
    lng,
    acc,
    mock,
    durationSec,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_evidence';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEvidenceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('log_id')) {
      context.handle(
        _logIdMeta,
        logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta),
      );
    } else if (isInserting) {
      context.missing(_logIdMeta);
    }
    if (data.containsKey('log_kind')) {
      context.handle(
        _logKindMeta,
        logKind.isAcceptableOrUnknown(data['log_kind']!, _logKindMeta),
      );
    } else if (isInserting) {
      context.missing(_logKindMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('captured_at_device')) {
      context.handle(
        _capturedAtDeviceMeta,
        capturedAtDevice.isAcceptableOrUnknown(
          data['captured_at_device']!,
          _capturedAtDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedAtDeviceMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('acc')) {
      context.handle(
        _accMeta,
        acc.isAcceptableOrUnknown(data['acc']!, _accMeta),
      );
    } else if (isInserting) {
      context.missing(_accMeta);
    }
    if (data.containsKey('mock')) {
      context.handle(
        _mockMeta,
        mock.isAcceptableOrUnknown(data['mock']!, _mockMeta),
      );
    } else if (isInserting) {
      context.missing(_mockMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEvidenceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEvidenceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      logId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_id'],
      )!,
      logKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_kind'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      capturedAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at_device'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      acc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}acc'],
      )!,
      mock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mock'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
    );
  }

  @override
  $LocalEvidenceTable createAlias(String alias) {
    return $LocalEvidenceTable(attachedDatabase, alias);
  }
}

class LocalEvidenceData extends DataClass
    implements Insertable<LocalEvidenceData> {
  final String id;

  /// The trip or fuel log this belongs to.
  final String logId;

  /// 'trip' or 'fuel'.
  final String logKind;

  /// 'start' / 'end' for trips, 'fill' for fuel logs.
  final String phase;

  /// 'odometer', 'pump' or 'video'.
  final String type;

  /// Absolute path of the stored file (EXIF already stripped).
  final String filePath;
  final String sha256;
  final DateTime capturedAtDevice;
  final double lat;
  final double lng;
  final double acc;
  final bool mock;
  final int? durationSec;
  const LocalEvidenceData({
    required this.id,
    required this.logId,
    required this.logKind,
    required this.phase,
    required this.type,
    required this.filePath,
    required this.sha256,
    required this.capturedAtDevice,
    required this.lat,
    required this.lng,
    required this.acc,
    required this.mock,
    this.durationSec,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['log_id'] = Variable<String>(logId);
    map['log_kind'] = Variable<String>(logKind);
    map['phase'] = Variable<String>(phase);
    map['type'] = Variable<String>(type);
    map['file_path'] = Variable<String>(filePath);
    map['sha256'] = Variable<String>(sha256);
    map['captured_at_device'] = Variable<DateTime>(capturedAtDevice);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['acc'] = Variable<double>(acc);
    map['mock'] = Variable<bool>(mock);
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    return map;
  }

  LocalEvidenceCompanion toCompanion(bool nullToAbsent) {
    return LocalEvidenceCompanion(
      id: Value(id),
      logId: Value(logId),
      logKind: Value(logKind),
      phase: Value(phase),
      type: Value(type),
      filePath: Value(filePath),
      sha256: Value(sha256),
      capturedAtDevice: Value(capturedAtDevice),
      lat: Value(lat),
      lng: Value(lng),
      acc: Value(acc),
      mock: Value(mock),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
    );
  }

  factory LocalEvidenceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEvidenceData(
      id: serializer.fromJson<String>(json['id']),
      logId: serializer.fromJson<String>(json['logId']),
      logKind: serializer.fromJson<String>(json['logKind']),
      phase: serializer.fromJson<String>(json['phase']),
      type: serializer.fromJson<String>(json['type']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      capturedAtDevice: serializer.fromJson<DateTime>(json['capturedAtDevice']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      acc: serializer.fromJson<double>(json['acc']),
      mock: serializer.fromJson<bool>(json['mock']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'logId': serializer.toJson<String>(logId),
      'logKind': serializer.toJson<String>(logKind),
      'phase': serializer.toJson<String>(phase),
      'type': serializer.toJson<String>(type),
      'filePath': serializer.toJson<String>(filePath),
      'sha256': serializer.toJson<String>(sha256),
      'capturedAtDevice': serializer.toJson<DateTime>(capturedAtDevice),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'acc': serializer.toJson<double>(acc),
      'mock': serializer.toJson<bool>(mock),
      'durationSec': serializer.toJson<int?>(durationSec),
    };
  }

  LocalEvidenceData copyWith({
    String? id,
    String? logId,
    String? logKind,
    String? phase,
    String? type,
    String? filePath,
    String? sha256,
    DateTime? capturedAtDevice,
    double? lat,
    double? lng,
    double? acc,
    bool? mock,
    Value<int?> durationSec = const Value.absent(),
  }) => LocalEvidenceData(
    id: id ?? this.id,
    logId: logId ?? this.logId,
    logKind: logKind ?? this.logKind,
    phase: phase ?? this.phase,
    type: type ?? this.type,
    filePath: filePath ?? this.filePath,
    sha256: sha256 ?? this.sha256,
    capturedAtDevice: capturedAtDevice ?? this.capturedAtDevice,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    acc: acc ?? this.acc,
    mock: mock ?? this.mock,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
  );
  LocalEvidenceData copyWithCompanion(LocalEvidenceCompanion data) {
    return LocalEvidenceData(
      id: data.id.present ? data.id.value : this.id,
      logId: data.logId.present ? data.logId.value : this.logId,
      logKind: data.logKind.present ? data.logKind.value : this.logKind,
      phase: data.phase.present ? data.phase.value : this.phase,
      type: data.type.present ? data.type.value : this.type,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      capturedAtDevice: data.capturedAtDevice.present
          ? data.capturedAtDevice.value
          : this.capturedAtDevice,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      acc: data.acc.present ? data.acc.value : this.acc,
      mock: data.mock.present ? data.mock.value : this.mock,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEvidenceData(')
          ..write('id: $id, ')
          ..write('logId: $logId, ')
          ..write('logKind: $logKind, ')
          ..write('phase: $phase, ')
          ..write('type: $type, ')
          ..write('filePath: $filePath, ')
          ..write('sha256: $sha256, ')
          ..write('capturedAtDevice: $capturedAtDevice, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('acc: $acc, ')
          ..write('mock: $mock, ')
          ..write('durationSec: $durationSec')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    logId,
    logKind,
    phase,
    type,
    filePath,
    sha256,
    capturedAtDevice,
    lat,
    lng,
    acc,
    mock,
    durationSec,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEvidenceData &&
          other.id == this.id &&
          other.logId == this.logId &&
          other.logKind == this.logKind &&
          other.phase == this.phase &&
          other.type == this.type &&
          other.filePath == this.filePath &&
          other.sha256 == this.sha256 &&
          other.capturedAtDevice == this.capturedAtDevice &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.acc == this.acc &&
          other.mock == this.mock &&
          other.durationSec == this.durationSec);
}

class LocalEvidenceCompanion extends UpdateCompanion<LocalEvidenceData> {
  final Value<String> id;
  final Value<String> logId;
  final Value<String> logKind;
  final Value<String> phase;
  final Value<String> type;
  final Value<String> filePath;
  final Value<String> sha256;
  final Value<DateTime> capturedAtDevice;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> acc;
  final Value<bool> mock;
  final Value<int?> durationSec;
  final Value<int> rowid;
  const LocalEvidenceCompanion({
    this.id = const Value.absent(),
    this.logId = const Value.absent(),
    this.logKind = const Value.absent(),
    this.phase = const Value.absent(),
    this.type = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.capturedAtDevice = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.acc = const Value.absent(),
    this.mock = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalEvidenceCompanion.insert({
    required String id,
    required String logId,
    required String logKind,
    required String phase,
    required String type,
    required String filePath,
    required String sha256,
    required DateTime capturedAtDevice,
    required double lat,
    required double lng,
    required double acc,
    required bool mock,
    this.durationSec = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       logId = Value(logId),
       logKind = Value(logKind),
       phase = Value(phase),
       type = Value(type),
       filePath = Value(filePath),
       sha256 = Value(sha256),
       capturedAtDevice = Value(capturedAtDevice),
       lat = Value(lat),
       lng = Value(lng),
       acc = Value(acc),
       mock = Value(mock);
  static Insertable<LocalEvidenceData> custom({
    Expression<String>? id,
    Expression<String>? logId,
    Expression<String>? logKind,
    Expression<String>? phase,
    Expression<String>? type,
    Expression<String>? filePath,
    Expression<String>? sha256,
    Expression<DateTime>? capturedAtDevice,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? acc,
    Expression<bool>? mock,
    Expression<int>? durationSec,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (logId != null) 'log_id': logId,
      if (logKind != null) 'log_kind': logKind,
      if (phase != null) 'phase': phase,
      if (type != null) 'type': type,
      if (filePath != null) 'file_path': filePath,
      if (sha256 != null) 'sha256': sha256,
      if (capturedAtDevice != null) 'captured_at_device': capturedAtDevice,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (acc != null) 'acc': acc,
      if (mock != null) 'mock': mock,
      if (durationSec != null) 'duration_sec': durationSec,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalEvidenceCompanion copyWith({
    Value<String>? id,
    Value<String>? logId,
    Value<String>? logKind,
    Value<String>? phase,
    Value<String>? type,
    Value<String>? filePath,
    Value<String>? sha256,
    Value<DateTime>? capturedAtDevice,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? acc,
    Value<bool>? mock,
    Value<int?>? durationSec,
    Value<int>? rowid,
  }) {
    return LocalEvidenceCompanion(
      id: id ?? this.id,
      logId: logId ?? this.logId,
      logKind: logKind ?? this.logKind,
      phase: phase ?? this.phase,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      sha256: sha256 ?? this.sha256,
      capturedAtDevice: capturedAtDevice ?? this.capturedAtDevice,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      acc: acc ?? this.acc,
      mock: mock ?? this.mock,
      durationSec: durationSec ?? this.durationSec,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (logId.present) {
      map['log_id'] = Variable<String>(logId.value);
    }
    if (logKind.present) {
      map['log_kind'] = Variable<String>(logKind.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (capturedAtDevice.present) {
      map['captured_at_device'] = Variable<DateTime>(capturedAtDevice.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (acc.present) {
      map['acc'] = Variable<double>(acc.value);
    }
    if (mock.present) {
      map['mock'] = Variable<bool>(mock.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEvidenceCompanion(')
          ..write('id: $id, ')
          ..write('logId: $logId, ')
          ..write('logKind: $logKind, ')
          ..write('phase: $phase, ')
          ..write('type: $type, ')
          ..write('filePath: $filePath, ')
          ..write('sha256: $sha256, ')
          ..write('capturedAtDevice: $capturedAtDevice, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('acc: $acc, ')
          ..write('mock: $mock, ')
          ..write('durationSec: $durationSec, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTripsTable localTrips = $LocalTripsTable(this);
  late final $LocalEvidenceTable localEvidence = $LocalEvidenceTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTrips,
    localEvidence,
  ];
}

typedef $$LocalTripsTableCreateCompanionBuilder = LocalTripsCompanion Function({
  required String id,
  required String driverId,
  required String driverName,
  required String status,
  required int startOdo,
  required DateTime startedAt,
  required double startLat,
  required double startLng,
  required double startAcc,
  required bool startMock,
  Value<int?> endOdo,
  Value<DateTime?> endedAt,
  Value<double?> endLat,
  Value<double?> endLng,
  Value<double?> endAcc,
  Value<bool?> endMock,
  Value<int> rowid,
});
typedef $$LocalTripsTableUpdateCompanionBuilder = LocalTripsCompanion Function({
  Value<String> id,
  Value<String> driverId,
  Value<String> driverName,
  Value<String> status,
  Value<int> startOdo,
  Value<DateTime> startedAt,
  Value<double> startLat,
  Value<double> startLng,
  Value<double> startAcc,
  Value<bool> startMock,
  Value<int?> endOdo,
  Value<DateTime?> endedAt,
  Value<double?> endLat,
  Value<double?> endLng,
  Value<double?> endAcc,
  Value<bool?> endMock,
  Value<int> rowid,
});

class $$LocalTripsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverId => $composableBuilder(
    column: $table.driverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startOdo => $composableBuilder(
    column: $table.startOdo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startAcc => $composableBuilder(
    column: $table.startAcc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get startMock => $composableBuilder(
    column: $table.startMock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOdo => $composableBuilder(
    column: $table.endOdo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endAcc => $composableBuilder(
    column: $table.endAcc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get endMock => $composableBuilder(
    column: $table.endMock,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverId => $composableBuilder(
    column: $table.driverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startOdo => $composableBuilder(
    column: $table.startOdo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startAcc => $composableBuilder(
    column: $table.startAcc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get startMock => $composableBuilder(
    column: $table.startMock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOdo => $composableBuilder(
    column: $table.endOdo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endAcc => $composableBuilder(
    column: $table.endAcc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get endMock => $composableBuilder(
    column: $table.endMock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get driverId =>
      $composableBuilder(column: $table.driverId, builder: (column) => column);

  GeneratedColumn<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startOdo =>
      $composableBuilder(column: $table.startOdo, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLng =>
      $composableBuilder(column: $table.startLng, builder: (column) => column);

  GeneratedColumn<double> get startAcc =>
      $composableBuilder(column: $table.startAcc, builder: (column) => column);

  GeneratedColumn<bool> get startMock =>
      $composableBuilder(column: $table.startMock, builder: (column) => column);

  GeneratedColumn<int> get endOdo =>
      $composableBuilder(column: $table.endOdo, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get endLat =>
      $composableBuilder(column: $table.endLat, builder: (column) => column);

  GeneratedColumn<double> get endLng =>
      $composableBuilder(column: $table.endLng, builder: (column) => column);

  GeneratedColumn<double> get endAcc =>
      $composableBuilder(column: $table.endAcc, builder: (column) => column);

  GeneratedColumn<bool> get endMock =>
      $composableBuilder(column: $table.endMock, builder: (column) => column);
}

class $$LocalTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTripsTable,
          LocalTrip,
          $$LocalTripsTableFilterComposer,
          $$LocalTripsTableOrderingComposer,
          $$LocalTripsTableAnnotationComposer,
          $$LocalTripsTableCreateCompanionBuilder,
          $$LocalTripsTableUpdateCompanionBuilder,
          (
            LocalTrip,
            BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>,
          ),
          LocalTrip,
          PrefetchHooks Function()
        > {
  $$LocalTripsTableTableManager(_$AppDatabase db, $LocalTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> driverId = const Value.absent(),
                Value<String> driverName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> startOdo = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<double> startLat = const Value.absent(),
                Value<double> startLng = const Value.absent(),
                Value<double> startAcc = const Value.absent(),
                Value<bool> startMock = const Value.absent(),
                Value<int?> endOdo = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double?> endLat = const Value.absent(),
                Value<double?> endLng = const Value.absent(),
                Value<double?> endAcc = const Value.absent(),
                Value<bool?> endMock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion(
                id: id,
                driverId: driverId,
                driverName: driverName,
                status: status,
                startOdo: startOdo,
                startedAt: startedAt,
                startLat: startLat,
                startLng: startLng,
                startAcc: startAcc,
                startMock: startMock,
                endOdo: endOdo,
                endedAt: endedAt,
                endLat: endLat,
                endLng: endLng,
                endAcc: endAcc,
                endMock: endMock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String driverId,
                required String driverName,
                required String status,
                required int startOdo,
                required DateTime startedAt,
                required double startLat,
                required double startLng,
                required double startAcc,
                required bool startMock,
                Value<int?> endOdo = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double?> endLat = const Value.absent(),
                Value<double?> endLng = const Value.absent(),
                Value<double?> endAcc = const Value.absent(),
                Value<bool?> endMock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion.insert(
                id: id,
                driverId: driverId,
                driverName: driverName,
                status: status,
                startOdo: startOdo,
                startedAt: startedAt,
                startLat: startLat,
                startLng: startLng,
                startAcc: startAcc,
                startMock: startMock,
                endOdo: endOdo,
                endedAt: endedAt,
                endLat: endLat,
                endLng: endLng,
                endAcc: endAcc,
                endMock: endMock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTripsTable, LocalTrip>(table),
                  BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTripsTable,
      LocalTrip,
      $$LocalTripsTableFilterComposer,
      $$LocalTripsTableOrderingComposer,
      $$LocalTripsTableAnnotationComposer,
      $$LocalTripsTableCreateCompanionBuilder,
      $$LocalTripsTableUpdateCompanionBuilder,
      (LocalTrip, BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>),
      LocalTrip,
      PrefetchHooks Function()
    >;
typedef $$LocalEvidenceTableCreateCompanionBuilder =
    LocalEvidenceCompanion Function({
      required String id,
      required String logId,
      required String logKind,
      required String phase,
      required String type,
      required String filePath,
      required String sha256,
      required DateTime capturedAtDevice,
      required double lat,
      required double lng,
      required double acc,
      required bool mock,
      Value<int?> durationSec,
      Value<int> rowid,
    });
typedef $$LocalEvidenceTableUpdateCompanionBuilder =
    LocalEvidenceCompanion Function({
      Value<String> id,
      Value<String> logId,
      Value<String> logKind,
      Value<String> phase,
      Value<String> type,
      Value<String> filePath,
      Value<String> sha256,
      Value<DateTime> capturedAtDevice,
      Value<double> lat,
      Value<double> lng,
      Value<double> acc,
      Value<bool> mock,
      Value<int?> durationSec,
      Value<int> rowid,
    });

class $$LocalEvidenceTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEvidenceTable> {
  $$LocalEvidenceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logId => $composableBuilder(
    column: $table.logId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logKind => $composableBuilder(
    column: $table.logKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAtDevice => $composableBuilder(
    column: $table.capturedAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get acc => $composableBuilder(
    column: $table.acc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mock => $composableBuilder(
    column: $table.mock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEvidenceTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEvidenceTable> {
  $$LocalEvidenceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logId => $composableBuilder(
    column: $table.logId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logKind => $composableBuilder(
    column: $table.logKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAtDevice => $composableBuilder(
    column: $table.capturedAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get acc => $composableBuilder(
    column: $table.acc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mock => $composableBuilder(
    column: $table.mock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEvidenceTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEvidenceTable> {
  $$LocalEvidenceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get logId =>
      $composableBuilder(column: $table.logId, builder: (column) => column);

  GeneratedColumn<String> get logKind =>
      $composableBuilder(column: $table.logKind, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAtDevice => $composableBuilder(
    column: $table.capturedAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get acc =>
      $composableBuilder(column: $table.acc, builder: (column) => column);

  GeneratedColumn<bool> get mock =>
      $composableBuilder(column: $table.mock, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );
}

class $$LocalEvidenceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEvidenceTable,
          LocalEvidenceData,
          $$LocalEvidenceTableFilterComposer,
          $$LocalEvidenceTableOrderingComposer,
          $$LocalEvidenceTableAnnotationComposer,
          $$LocalEvidenceTableCreateCompanionBuilder,
          $$LocalEvidenceTableUpdateCompanionBuilder,
          (
            LocalEvidenceData,
            BaseReferences<
              _$AppDatabase,
              $LocalEvidenceTable,
              LocalEvidenceData
            >,
          ),
          LocalEvidenceData,
          PrefetchHooks Function()
        > {
  $$LocalEvidenceTableTableManager(_$AppDatabase db, $LocalEvidenceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEvidenceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalEvidenceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalEvidenceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> logId = const Value.absent(),
                Value<String> logKind = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<DateTime> capturedAtDevice = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> acc = const Value.absent(),
                Value<bool> mock = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEvidenceCompanion(
                id: id,
                logId: logId,
                logKind: logKind,
                phase: phase,
                type: type,
                filePath: filePath,
                sha256: sha256,
                capturedAtDevice: capturedAtDevice,
                lat: lat,
                lng: lng,
                acc: acc,
                mock: mock,
                durationSec: durationSec,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String logId,
                required String logKind,
                required String phase,
                required String type,
                required String filePath,
                required String sha256,
                required DateTime capturedAtDevice,
                required double lat,
                required double lng,
                required double acc,
                required bool mock,
                Value<int?> durationSec = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEvidenceCompanion.insert(
                id: id,
                logId: logId,
                logKind: logKind,
                phase: phase,
                type: type,
                filePath: filePath,
                sha256: sha256,
                capturedAtDevice: capturedAtDevice,
                lat: lat,
                lng: lng,
                acc: acc,
                mock: mock,
                durationSec: durationSec,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalEvidenceTable, LocalEvidenceData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalEvidenceTable,
                    LocalEvidenceData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEvidenceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEvidenceTable,
      LocalEvidenceData,
      $$LocalEvidenceTableFilterComposer,
      $$LocalEvidenceTableOrderingComposer,
      $$LocalEvidenceTableAnnotationComposer,
      $$LocalEvidenceTableCreateCompanionBuilder,
      $$LocalEvidenceTableUpdateCompanionBuilder,
      (
        LocalEvidenceData,
        BaseReferences<_$AppDatabase, $LocalEvidenceTable, LocalEvidenceData>,
      ),
      LocalEvidenceData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTripsTableTableManager get localTrips =>
      $$LocalTripsTableTableManager(_db, _db.localTrips);
  $$LocalEvidenceTableTableManager get localEvidence =>
      $$LocalEvidenceTableTableManager(_db, _db.localEvidence);
}
