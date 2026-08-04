// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, Household> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(
    Insertable<Household> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Household map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Household(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class Household extends DataClass implements Insertable<Household> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Household({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Household.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Household(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Household copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Household(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Household copyWithCompanion(HouseholdsCompanion data) {
    return Household(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Household(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Household &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HouseholdsCompanion extends UpdateCompanion<Household> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    required String id,
    required String name,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Household> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberProfilesTable extends MemberProfiles
    with TableInfo<$MemberProfilesTable, MemberProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#91C8E4'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    displayName,
    colorHex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MemberProfilesTable createAlias(String alias) {
    return $MemberProfilesTable(attachedDatabase, alias);
  }
}

class MemberProfile extends DataClass implements Insertable<MemberProfile> {
  final String id;
  final String householdId;
  final String displayName;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MemberProfile({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['display_name'] = Variable<String>(displayName);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MemberProfilesCompanion toCompanion(bool nullToAbsent) {
    return MemberProfilesCompanion(
      id: Value(id),
      householdId: Value(householdId),
      displayName: Value(displayName),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MemberProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberProfile(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'displayName': serializer.toJson<String>(displayName),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MemberProfile copyWith({
    String? id,
    String? householdId,
    String? displayName,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MemberProfile(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    displayName: displayName ?? this.displayName,
    colorHex: colorHex ?? this.colorHex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MemberProfile copyWithCompanion(MemberProfilesCompanion data) {
    return MemberProfile(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberProfile(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('displayName: $displayName, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, displayName, colorHex, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberProfile &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.displayName == this.displayName &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MemberProfilesCompanion extends UpdateCompanion<MemberProfile> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> displayName;
  final Value<String> colorHex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MemberProfilesCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberProfilesCompanion.insert({
    required String id,
    required String householdId,
    required String displayName,
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       displayName = Value(displayName);
  static Insertable<MemberProfile> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? displayName,
    Expression<String>? colorHex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (displayName != null) 'display_name': displayName,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? displayName,
    Value<String>? colorHex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MemberProfilesCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      displayName: displayName ?? this.displayName,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberProfilesCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('displayName: $displayName, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryContainersTable extends InventoryContainers
    with TableInfo<$InventoryContainersTable, InventoryContainer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryContainersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ownerMemberIdMeta = const VerificationMeta(
    'ownerMemberId',
  );
  @override
  late final GeneratedColumn<String> ownerMemberId = GeneratedColumn<String>(
    'owner_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES member_profiles (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    ownerMemberId,
    name,
    kind,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_containers';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryContainer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('owner_member_id')) {
      context.handle(
        _ownerMemberIdMeta,
        ownerMemberId.isAcceptableOrUnknown(
          data['owner_member_id']!,
          _ownerMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryContainer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryContainer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      ownerMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_member_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InventoryContainersTable createAlias(String alias) {
    return $InventoryContainersTable(attachedDatabase, alias);
  }
}

class InventoryContainer extends DataClass
    implements Insertable<InventoryContainer> {
  final String id;
  final String householdId;
  final String? ownerMemberId;
  final String name;
  final String kind;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InventoryContainer({
    required this.id,
    required this.householdId,
    this.ownerMemberId,
    required this.name,
    required this.kind,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    if (!nullToAbsent || ownerMemberId != null) {
      map['owner_member_id'] = Variable<String>(ownerMemberId);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InventoryContainersCompanion toCompanion(bool nullToAbsent) {
    return InventoryContainersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      ownerMemberId: ownerMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerMemberId),
      name: Value(name),
      kind: Value(kind),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryContainer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryContainer(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      ownerMemberId: serializer.fromJson<String?>(json['ownerMemberId']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'ownerMemberId': serializer.toJson<String?>(ownerMemberId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InventoryContainer copyWith({
    String? id,
    String? householdId,
    Value<String?> ownerMemberId = const Value.absent(),
    String? name,
    String? kind,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InventoryContainer(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    ownerMemberId: ownerMemberId.present
        ? ownerMemberId.value
        : this.ownerMemberId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InventoryContainer copyWithCompanion(InventoryContainersCompanion data) {
    return InventoryContainer(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      ownerMemberId: data.ownerMemberId.present
          ? data.ownerMemberId.value
          : this.ownerMemberId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryContainer(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('ownerMemberId: $ownerMemberId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    ownerMemberId,
    name,
    kind,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryContainer &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.ownerMemberId == this.ownerMemberId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InventoryContainersCompanion extends UpdateCompanion<InventoryContainer> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String?> ownerMemberId;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InventoryContainersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.ownerMemberId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryContainersCompanion.insert({
    required String id,
    required String householdId,
    this.ownerMemberId = const Value.absent(),
    required String name,
    required String kind,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       name = Value(name),
       kind = Value(kind);
  static Insertable<InventoryContainer> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? ownerMemberId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (ownerMemberId != null) 'owner_member_id': ownerMemberId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryContainersCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String?>? ownerMemberId,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InventoryContainersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      ownerMemberId: ownerMemberId ?? this.ownerMemberId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (ownerMemberId.present) {
      map['owner_member_id'] = Variable<String>(ownerMemberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryContainersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('ownerMemberId: $ownerMemberId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _containerIdMeta = const VerificationMeta(
    'containerId',
  );
  @override
  late final GeneratedColumn<String> containerId = GeneratedColumn<String>(
    'container_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory_containers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemSeqMeta = const VerificationMeta(
    'itemSeq',
  );
  @override
  late final GeneratedColumn<String> itemSeq = GeneratedColumn<String>(
    'item_seq',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ingredientSummaryMeta = const VerificationMeta(
    'ingredientSummary',
  );
  @override
  late final GeneratedColumn<String> ingredientSummary =
      GeneratedColumn<String>(
        'ingredient_summary',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _identificationVariantKeyMeta =
      const VerificationMeta('identificationVariantKey');
  @override
  late final GeneratedColumn<String> identificationVariantKey =
      GeneratedColumn<String>(
        'identification_variant_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _officialImageUrlMeta = const VerificationMeta(
    'officialImageUrl',
  );
  @override
  late final GeneratedColumn<String> officialImageUrl = GeneratedColumn<String>(
    'official_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedImageBytesMeta =
      const VerificationMeta('capturedImageBytes');
  @override
  late final GeneratedColumn<Uint8List> capturedImageBytes =
      GeneratedColumn<Uint8List>(
        'captured_image_bytes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _appearanceSummaryMeta = const VerificationMeta(
    'appearanceSummary',
  );
  @override
  late final GeneratedColumn<String> appearanceSummary =
      GeneratedColumn<String>(
        'appearance_summary',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _itemKindMeta = const VerificationMeta(
    'itemKind',
  );
  @override
  late final GeneratedColumn<String> itemKind = GeneratedColumn<String>(
    'item_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medicine'),
  );
  static const VerificationMeta _officialCategoryMeta = const VerificationMeta(
    'officialCategory',
  );
  @override
  late final GeneratedColumn<String> officialCategory = GeneratedColumn<String>(
    'official_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cabinetSectionMeta = const VerificationMeta(
    'cabinetSection',
  );
  @override
  late final GeneratedColumn<String> cabinetSection = GeneratedColumn<String>(
    'cabinet_section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('개'),
  );
  static const VerificationMeta _expiresOnMeta = const VerificationMeta(
    'expiresOn',
  );
  @override
  late final GeneratedColumn<DateTime> expiresOn = GeneratedColumn<DateTime>(
    'expires_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageNoteMeta = const VerificationMeta(
    'storageNote',
  );
  @override
  late final GeneratedColumn<String> storageNote = GeneratedColumn<String>(
    'storage_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _privateNoteMeta = const VerificationMeta(
    'privateNote',
  );
  @override
  late final GeneratedColumn<String> privateNote = GeneratedColumn<String>(
    'private_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignedMemberIdMeta = const VerificationMeta(
    'assignedMemberId',
  );
  @override
  late final GeneratedColumn<String> assignedMemberId = GeneratedColumn<String>(
    'assigned_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES member_profiles (id) ON DELETE SET NULL',
    ),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    containerId,
    itemSeq,
    productName,
    manufacturer,
    ingredientSummary,
    identificationVariantKey,
    officialImageUrl,
    capturedImageBytes,
    appearanceSummary,
    itemKind,
    officialCategory,
    cabinetSection,
    quantity,
    unit,
    expiresOn,
    storageNote,
    privateNote,
    assignedMemberId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('container_id')) {
      context.handle(
        _containerIdMeta,
        containerId.isAcceptableOrUnknown(
          data['container_id']!,
          _containerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_containerIdMeta);
    }
    if (data.containsKey('item_seq')) {
      context.handle(
        _itemSeqMeta,
        itemSeq.isAcceptableOrUnknown(data['item_seq']!, _itemSeqMeta),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('ingredient_summary')) {
      context.handle(
        _ingredientSummaryMeta,
        ingredientSummary.isAcceptableOrUnknown(
          data['ingredient_summary']!,
          _ingredientSummaryMeta,
        ),
      );
    }
    if (data.containsKey('identification_variant_key')) {
      context.handle(
        _identificationVariantKeyMeta,
        identificationVariantKey.isAcceptableOrUnknown(
          data['identification_variant_key']!,
          _identificationVariantKeyMeta,
        ),
      );
    }
    if (data.containsKey('official_image_url')) {
      context.handle(
        _officialImageUrlMeta,
        officialImageUrl.isAcceptableOrUnknown(
          data['official_image_url']!,
          _officialImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('captured_image_bytes')) {
      context.handle(
        _capturedImageBytesMeta,
        capturedImageBytes.isAcceptableOrUnknown(
          data['captured_image_bytes']!,
          _capturedImageBytesMeta,
        ),
      );
    }
    if (data.containsKey('appearance_summary')) {
      context.handle(
        _appearanceSummaryMeta,
        appearanceSummary.isAcceptableOrUnknown(
          data['appearance_summary']!,
          _appearanceSummaryMeta,
        ),
      );
    }
    if (data.containsKey('item_kind')) {
      context.handle(
        _itemKindMeta,
        itemKind.isAcceptableOrUnknown(data['item_kind']!, _itemKindMeta),
      );
    }
    if (data.containsKey('official_category')) {
      context.handle(
        _officialCategoryMeta,
        officialCategory.isAcceptableOrUnknown(
          data['official_category']!,
          _officialCategoryMeta,
        ),
      );
    }
    if (data.containsKey('cabinet_section')) {
      context.handle(
        _cabinetSectionMeta,
        cabinetSection.isAcceptableOrUnknown(
          data['cabinet_section']!,
          _cabinetSectionMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('expires_on')) {
      context.handle(
        _expiresOnMeta,
        expiresOn.isAcceptableOrUnknown(data['expires_on']!, _expiresOnMeta),
      );
    }
    if (data.containsKey('storage_note')) {
      context.handle(
        _storageNoteMeta,
        storageNote.isAcceptableOrUnknown(
          data['storage_note']!,
          _storageNoteMeta,
        ),
      );
    }
    if (data.containsKey('private_note')) {
      context.handle(
        _privateNoteMeta,
        privateNote.isAcceptableOrUnknown(
          data['private_note']!,
          _privateNoteMeta,
        ),
      );
    }
    if (data.containsKey('assigned_member_id')) {
      context.handle(
        _assignedMemberIdMeta,
        assignedMemberId.isAcceptableOrUnknown(
          data['assigned_member_id']!,
          _assignedMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      containerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      )!,
      itemSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_seq'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      ingredientSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_summary'],
      ),
      identificationVariantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identification_variant_key'],
      ),
      officialImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}official_image_url'],
      ),
      capturedImageBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}captured_image_bytes'],
      ),
      appearanceSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance_summary'],
      ),
      itemKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_kind'],
      )!,
      officialCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}official_category'],
      ),
      cabinetSection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cabinet_section'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      expiresOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_on'],
      ),
      storageNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_note'],
      ),
      privateNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_note'],
      ),
      assignedMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_member_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final String id;
  final String containerId;
  final String? itemSeq;
  final String productName;
  final String? manufacturer;
  final String? ingredientSummary;
  final String? identificationVariantKey;
  final String? officialImageUrl;
  final Uint8List? capturedImageBytes;
  final String? appearanceSummary;
  final String itemKind;
  final String? officialCategory;
  final String cabinetSection;
  final int quantity;
  final String unit;
  final DateTime? expiresOn;
  final String? storageNote;
  final String? privateNote;
  final String? assignedMemberId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InventoryItem({
    required this.id,
    required this.containerId,
    this.itemSeq,
    required this.productName,
    this.manufacturer,
    this.ingredientSummary,
    this.identificationVariantKey,
    this.officialImageUrl,
    this.capturedImageBytes,
    this.appearanceSummary,
    required this.itemKind,
    this.officialCategory,
    required this.cabinetSection,
    required this.quantity,
    required this.unit,
    this.expiresOn,
    this.storageNote,
    this.privateNote,
    this.assignedMemberId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['container_id'] = Variable<String>(containerId);
    if (!nullToAbsent || itemSeq != null) {
      map['item_seq'] = Variable<String>(itemSeq);
    }
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || ingredientSummary != null) {
      map['ingredient_summary'] = Variable<String>(ingredientSummary);
    }
    if (!nullToAbsent || identificationVariantKey != null) {
      map['identification_variant_key'] = Variable<String>(
        identificationVariantKey,
      );
    }
    if (!nullToAbsent || officialImageUrl != null) {
      map['official_image_url'] = Variable<String>(officialImageUrl);
    }
    if (!nullToAbsent || capturedImageBytes != null) {
      map['captured_image_bytes'] = Variable<Uint8List>(capturedImageBytes);
    }
    if (!nullToAbsent || appearanceSummary != null) {
      map['appearance_summary'] = Variable<String>(appearanceSummary);
    }
    map['item_kind'] = Variable<String>(itemKind);
    if (!nullToAbsent || officialCategory != null) {
      map['official_category'] = Variable<String>(officialCategory);
    }
    map['cabinet_section'] = Variable<String>(cabinetSection);
    map['quantity'] = Variable<int>(quantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || expiresOn != null) {
      map['expires_on'] = Variable<DateTime>(expiresOn);
    }
    if (!nullToAbsent || storageNote != null) {
      map['storage_note'] = Variable<String>(storageNote);
    }
    if (!nullToAbsent || privateNote != null) {
      map['private_note'] = Variable<String>(privateNote);
    }
    if (!nullToAbsent || assignedMemberId != null) {
      map['assigned_member_id'] = Variable<String>(assignedMemberId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      containerId: Value(containerId),
      itemSeq: itemSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(itemSeq),
      productName: Value(productName),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      ingredientSummary: ingredientSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredientSummary),
      identificationVariantKey: identificationVariantKey == null && nullToAbsent
          ? const Value.absent()
          : Value(identificationVariantKey),
      officialImageUrl: officialImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(officialImageUrl),
      capturedImageBytes: capturedImageBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedImageBytes),
      appearanceSummary: appearanceSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(appearanceSummary),
      itemKind: Value(itemKind),
      officialCategory: officialCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(officialCategory),
      cabinetSection: Value(cabinetSection),
      quantity: Value(quantity),
      unit: Value(unit),
      expiresOn: expiresOn == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresOn),
      storageNote: storageNote == null && nullToAbsent
          ? const Value.absent()
          : Value(storageNote),
      privateNote: privateNote == null && nullToAbsent
          ? const Value.absent()
          : Value(privateNote),
      assignedMemberId: assignedMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedMemberId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<String>(json['id']),
      containerId: serializer.fromJson<String>(json['containerId']),
      itemSeq: serializer.fromJson<String?>(json['itemSeq']),
      productName: serializer.fromJson<String>(json['productName']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      ingredientSummary: serializer.fromJson<String?>(
        json['ingredientSummary'],
      ),
      identificationVariantKey: serializer.fromJson<String?>(
        json['identificationVariantKey'],
      ),
      officialImageUrl: serializer.fromJson<String?>(json['officialImageUrl']),
      capturedImageBytes: serializer.fromJson<Uint8List?>(
        json['capturedImageBytes'],
      ),
      appearanceSummary: serializer.fromJson<String?>(
        json['appearanceSummary'],
      ),
      itemKind: serializer.fromJson<String>(json['itemKind']),
      officialCategory: serializer.fromJson<String?>(json['officialCategory']),
      cabinetSection: serializer.fromJson<String>(json['cabinetSection']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      expiresOn: serializer.fromJson<DateTime?>(json['expiresOn']),
      storageNote: serializer.fromJson<String?>(json['storageNote']),
      privateNote: serializer.fromJson<String?>(json['privateNote']),
      assignedMemberId: serializer.fromJson<String?>(json['assignedMemberId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'containerId': serializer.toJson<String>(containerId),
      'itemSeq': serializer.toJson<String?>(itemSeq),
      'productName': serializer.toJson<String>(productName),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'ingredientSummary': serializer.toJson<String?>(ingredientSummary),
      'identificationVariantKey': serializer.toJson<String?>(
        identificationVariantKey,
      ),
      'officialImageUrl': serializer.toJson<String?>(officialImageUrl),
      'capturedImageBytes': serializer.toJson<Uint8List?>(capturedImageBytes),
      'appearanceSummary': serializer.toJson<String?>(appearanceSummary),
      'itemKind': serializer.toJson<String>(itemKind),
      'officialCategory': serializer.toJson<String?>(officialCategory),
      'cabinetSection': serializer.toJson<String>(cabinetSection),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String>(unit),
      'expiresOn': serializer.toJson<DateTime?>(expiresOn),
      'storageNote': serializer.toJson<String?>(storageNote),
      'privateNote': serializer.toJson<String?>(privateNote),
      'assignedMemberId': serializer.toJson<String?>(assignedMemberId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? containerId,
    Value<String?> itemSeq = const Value.absent(),
    String? productName,
    Value<String?> manufacturer = const Value.absent(),
    Value<String?> ingredientSummary = const Value.absent(),
    Value<String?> identificationVariantKey = const Value.absent(),
    Value<String?> officialImageUrl = const Value.absent(),
    Value<Uint8List?> capturedImageBytes = const Value.absent(),
    Value<String?> appearanceSummary = const Value.absent(),
    String? itemKind,
    Value<String?> officialCategory = const Value.absent(),
    String? cabinetSection,
    int? quantity,
    String? unit,
    Value<DateTime?> expiresOn = const Value.absent(),
    Value<String?> storageNote = const Value.absent(),
    Value<String?> privateNote = const Value.absent(),
    Value<String?> assignedMemberId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InventoryItem(
    id: id ?? this.id,
    containerId: containerId ?? this.containerId,
    itemSeq: itemSeq.present ? itemSeq.value : this.itemSeq,
    productName: productName ?? this.productName,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    ingredientSummary: ingredientSummary.present
        ? ingredientSummary.value
        : this.ingredientSummary,
    identificationVariantKey: identificationVariantKey.present
        ? identificationVariantKey.value
        : this.identificationVariantKey,
    officialImageUrl: officialImageUrl.present
        ? officialImageUrl.value
        : this.officialImageUrl,
    capturedImageBytes: capturedImageBytes.present
        ? capturedImageBytes.value
        : this.capturedImageBytes,
    appearanceSummary: appearanceSummary.present
        ? appearanceSummary.value
        : this.appearanceSummary,
    itemKind: itemKind ?? this.itemKind,
    officialCategory: officialCategory.present
        ? officialCategory.value
        : this.officialCategory,
    cabinetSection: cabinetSection ?? this.cabinetSection,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    expiresOn: expiresOn.present ? expiresOn.value : this.expiresOn,
    storageNote: storageNote.present ? storageNote.value : this.storageNote,
    privateNote: privateNote.present ? privateNote.value : this.privateNote,
    assignedMemberId: assignedMemberId.present
        ? assignedMemberId.value
        : this.assignedMemberId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      containerId: data.containerId.present
          ? data.containerId.value
          : this.containerId,
      itemSeq: data.itemSeq.present ? data.itemSeq.value : this.itemSeq,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      ingredientSummary: data.ingredientSummary.present
          ? data.ingredientSummary.value
          : this.ingredientSummary,
      identificationVariantKey: data.identificationVariantKey.present
          ? data.identificationVariantKey.value
          : this.identificationVariantKey,
      officialImageUrl: data.officialImageUrl.present
          ? data.officialImageUrl.value
          : this.officialImageUrl,
      capturedImageBytes: data.capturedImageBytes.present
          ? data.capturedImageBytes.value
          : this.capturedImageBytes,
      appearanceSummary: data.appearanceSummary.present
          ? data.appearanceSummary.value
          : this.appearanceSummary,
      itemKind: data.itemKind.present ? data.itemKind.value : this.itemKind,
      officialCategory: data.officialCategory.present
          ? data.officialCategory.value
          : this.officialCategory,
      cabinetSection: data.cabinetSection.present
          ? data.cabinetSection.value
          : this.cabinetSection,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      expiresOn: data.expiresOn.present ? data.expiresOn.value : this.expiresOn,
      storageNote: data.storageNote.present
          ? data.storageNote.value
          : this.storageNote,
      privateNote: data.privateNote.present
          ? data.privateNote.value
          : this.privateNote,
      assignedMemberId: data.assignedMemberId.present
          ? data.assignedMemberId.value
          : this.assignedMemberId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('containerId: $containerId, ')
          ..write('itemSeq: $itemSeq, ')
          ..write('productName: $productName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('ingredientSummary: $ingredientSummary, ')
          ..write('identificationVariantKey: $identificationVariantKey, ')
          ..write('officialImageUrl: $officialImageUrl, ')
          ..write('capturedImageBytes: $capturedImageBytes, ')
          ..write('appearanceSummary: $appearanceSummary, ')
          ..write('itemKind: $itemKind, ')
          ..write('officialCategory: $officialCategory, ')
          ..write('cabinetSection: $cabinetSection, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('expiresOn: $expiresOn, ')
          ..write('storageNote: $storageNote, ')
          ..write('privateNote: $privateNote, ')
          ..write('assignedMemberId: $assignedMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    containerId,
    itemSeq,
    productName,
    manufacturer,
    ingredientSummary,
    identificationVariantKey,
    officialImageUrl,
    $driftBlobEquality.hash(capturedImageBytes),
    appearanceSummary,
    itemKind,
    officialCategory,
    cabinetSection,
    quantity,
    unit,
    expiresOn,
    storageNote,
    privateNote,
    assignedMemberId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.containerId == this.containerId &&
          other.itemSeq == this.itemSeq &&
          other.productName == this.productName &&
          other.manufacturer == this.manufacturer &&
          other.ingredientSummary == this.ingredientSummary &&
          other.identificationVariantKey == this.identificationVariantKey &&
          other.officialImageUrl == this.officialImageUrl &&
          $driftBlobEquality.equals(
            other.capturedImageBytes,
            this.capturedImageBytes,
          ) &&
          other.appearanceSummary == this.appearanceSummary &&
          other.itemKind == this.itemKind &&
          other.officialCategory == this.officialCategory &&
          other.cabinetSection == this.cabinetSection &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.expiresOn == this.expiresOn &&
          other.storageNote == this.storageNote &&
          other.privateNote == this.privateNote &&
          other.assignedMemberId == this.assignedMemberId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<String> id;
  final Value<String> containerId;
  final Value<String?> itemSeq;
  final Value<String> productName;
  final Value<String?> manufacturer;
  final Value<String?> ingredientSummary;
  final Value<String?> identificationVariantKey;
  final Value<String?> officialImageUrl;
  final Value<Uint8List?> capturedImageBytes;
  final Value<String?> appearanceSummary;
  final Value<String> itemKind;
  final Value<String?> officialCategory;
  final Value<String> cabinetSection;
  final Value<int> quantity;
  final Value<String> unit;
  final Value<DateTime?> expiresOn;
  final Value<String?> storageNote;
  final Value<String?> privateNote;
  final Value<String?> assignedMemberId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.containerId = const Value.absent(),
    this.itemSeq = const Value.absent(),
    this.productName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.ingredientSummary = const Value.absent(),
    this.identificationVariantKey = const Value.absent(),
    this.officialImageUrl = const Value.absent(),
    this.capturedImageBytes = const Value.absent(),
    this.appearanceSummary = const Value.absent(),
    this.itemKind = const Value.absent(),
    this.officialCategory = const Value.absent(),
    this.cabinetSection = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.expiresOn = const Value.absent(),
    this.storageNote = const Value.absent(),
    this.privateNote = const Value.absent(),
    this.assignedMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    required String id,
    required String containerId,
    this.itemSeq = const Value.absent(),
    required String productName,
    this.manufacturer = const Value.absent(),
    this.ingredientSummary = const Value.absent(),
    this.identificationVariantKey = const Value.absent(),
    this.officialImageUrl = const Value.absent(),
    this.capturedImageBytes = const Value.absent(),
    this.appearanceSummary = const Value.absent(),
    this.itemKind = const Value.absent(),
    this.officialCategory = const Value.absent(),
    this.cabinetSection = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.expiresOn = const Value.absent(),
    this.storageNote = const Value.absent(),
    this.privateNote = const Value.absent(),
    this.assignedMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       containerId = Value(containerId),
       productName = Value(productName);
  static Insertable<InventoryItem> custom({
    Expression<String>? id,
    Expression<String>? containerId,
    Expression<String>? itemSeq,
    Expression<String>? productName,
    Expression<String>? manufacturer,
    Expression<String>? ingredientSummary,
    Expression<String>? identificationVariantKey,
    Expression<String>? officialImageUrl,
    Expression<Uint8List>? capturedImageBytes,
    Expression<String>? appearanceSummary,
    Expression<String>? itemKind,
    Expression<String>? officialCategory,
    Expression<String>? cabinetSection,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<DateTime>? expiresOn,
    Expression<String>? storageNote,
    Expression<String>? privateNote,
    Expression<String>? assignedMemberId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (containerId != null) 'container_id': containerId,
      if (itemSeq != null) 'item_seq': itemSeq,
      if (productName != null) 'product_name': productName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (ingredientSummary != null) 'ingredient_summary': ingredientSummary,
      if (identificationVariantKey != null)
        'identification_variant_key': identificationVariantKey,
      if (officialImageUrl != null) 'official_image_url': officialImageUrl,
      if (capturedImageBytes != null)
        'captured_image_bytes': capturedImageBytes,
      if (appearanceSummary != null) 'appearance_summary': appearanceSummary,
      if (itemKind != null) 'item_kind': itemKind,
      if (officialCategory != null) 'official_category': officialCategory,
      if (cabinetSection != null) 'cabinet_section': cabinetSection,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (expiresOn != null) 'expires_on': expiresOn,
      if (storageNote != null) 'storage_note': storageNote,
      if (privateNote != null) 'private_note': privateNote,
      if (assignedMemberId != null) 'assigned_member_id': assignedMemberId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? containerId,
    Value<String?>? itemSeq,
    Value<String>? productName,
    Value<String?>? manufacturer,
    Value<String?>? ingredientSummary,
    Value<String?>? identificationVariantKey,
    Value<String?>? officialImageUrl,
    Value<Uint8List?>? capturedImageBytes,
    Value<String?>? appearanceSummary,
    Value<String>? itemKind,
    Value<String?>? officialCategory,
    Value<String>? cabinetSection,
    Value<int>? quantity,
    Value<String>? unit,
    Value<DateTime?>? expiresOn,
    Value<String?>? storageNote,
    Value<String?>? privateNote,
    Value<String?>? assignedMemberId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      containerId: containerId ?? this.containerId,
      itemSeq: itemSeq ?? this.itemSeq,
      productName: productName ?? this.productName,
      manufacturer: manufacturer ?? this.manufacturer,
      ingredientSummary: ingredientSummary ?? this.ingredientSummary,
      identificationVariantKey:
          identificationVariantKey ?? this.identificationVariantKey,
      officialImageUrl: officialImageUrl ?? this.officialImageUrl,
      capturedImageBytes: capturedImageBytes ?? this.capturedImageBytes,
      appearanceSummary: appearanceSummary ?? this.appearanceSummary,
      itemKind: itemKind ?? this.itemKind,
      officialCategory: officialCategory ?? this.officialCategory,
      cabinetSection: cabinetSection ?? this.cabinetSection,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiresOn: expiresOn ?? this.expiresOn,
      storageNote: storageNote ?? this.storageNote,
      privateNote: privateNote ?? this.privateNote,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (containerId.present) {
      map['container_id'] = Variable<String>(containerId.value);
    }
    if (itemSeq.present) {
      map['item_seq'] = Variable<String>(itemSeq.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (ingredientSummary.present) {
      map['ingredient_summary'] = Variable<String>(ingredientSummary.value);
    }
    if (identificationVariantKey.present) {
      map['identification_variant_key'] = Variable<String>(
        identificationVariantKey.value,
      );
    }
    if (officialImageUrl.present) {
      map['official_image_url'] = Variable<String>(officialImageUrl.value);
    }
    if (capturedImageBytes.present) {
      map['captured_image_bytes'] = Variable<Uint8List>(
        capturedImageBytes.value,
      );
    }
    if (appearanceSummary.present) {
      map['appearance_summary'] = Variable<String>(appearanceSummary.value);
    }
    if (itemKind.present) {
      map['item_kind'] = Variable<String>(itemKind.value);
    }
    if (officialCategory.present) {
      map['official_category'] = Variable<String>(officialCategory.value);
    }
    if (cabinetSection.present) {
      map['cabinet_section'] = Variable<String>(cabinetSection.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (expiresOn.present) {
      map['expires_on'] = Variable<DateTime>(expiresOn.value);
    }
    if (storageNote.present) {
      map['storage_note'] = Variable<String>(storageNote.value);
    }
    if (privateNote.present) {
      map['private_note'] = Variable<String>(privateNote.value);
    }
    if (assignedMemberId.present) {
      map['assigned_member_id'] = Variable<String>(assignedMemberId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('containerId: $containerId, ')
          ..write('itemSeq: $itemSeq, ')
          ..write('productName: $productName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('ingredientSummary: $ingredientSummary, ')
          ..write('identificationVariantKey: $identificationVariantKey, ')
          ..write('officialImageUrl: $officialImageUrl, ')
          ..write('capturedImageBytes: $capturedImageBytes, ')
          ..write('appearanceSummary: $appearanceSummary, ')
          ..write('itemKind: $itemKind, ')
          ..write('officialCategory: $officialCategory, ')
          ..write('cabinetSection: $cabinetSection, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('expiresOn: $expiresOn, ')
          ..write('storageNote: $storageNote, ')
          ..write('privateNote: $privateNote, ')
          ..write('assignedMemberId: $assignedMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RenewalReadinessTable extends RenewalReadiness
    with TableInfo<$RenewalReadinessTable, RenewalReadinessData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RenewalReadinessTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nextVisitOnMeta = const VerificationMeta(
    'nextVisitOn',
  );
  @override
  late final GeneratedColumn<DateTime> nextVisitOn = GeneratedColumn<DateTime>(
    'next_visit_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescriptionPhotoCheckedMeta =
      const VerificationMeta('prescriptionPhotoChecked');
  @override
  late final GeneratedColumn<bool> prescriptionPhotoChecked =
      GeneratedColumn<bool>(
        'prescription_photo_checked',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("prescription_photo_checked" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _remainingQuantityCheckedMeta =
      const VerificationMeta('remainingQuantityChecked');
  @override
  late final GeneratedColumn<bool> remainingQuantityChecked =
      GeneratedColumn<bool>(
        'remaining_quantity_checked',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("remaining_quantity_checked" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _questionsPreparedMeta = const VerificationMeta(
    'questionsPrepared',
  );
  @override
  late final GeneratedColumn<bool> questionsPrepared = GeneratedColumn<bool>(
    'questions_prepared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("questions_prepared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _visitNoteMeta = const VerificationMeta(
    'visitNote',
  );
  @override
  late final GeneratedColumn<String> visitNote = GeneratedColumn<String>(
    'visit_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryItemId,
    nextVisitOn,
    prescriptionPhotoChecked,
    remainingQuantityChecked,
    questionsPrepared,
    visitNote,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'renewal_readiness';
  @override
  VerificationContext validateIntegrity(
    Insertable<RenewalReadinessData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryItemIdMeta);
    }
    if (data.containsKey('next_visit_on')) {
      context.handle(
        _nextVisitOnMeta,
        nextVisitOn.isAcceptableOrUnknown(
          data['next_visit_on']!,
          _nextVisitOnMeta,
        ),
      );
    }
    if (data.containsKey('prescription_photo_checked')) {
      context.handle(
        _prescriptionPhotoCheckedMeta,
        prescriptionPhotoChecked.isAcceptableOrUnknown(
          data['prescription_photo_checked']!,
          _prescriptionPhotoCheckedMeta,
        ),
      );
    }
    if (data.containsKey('remaining_quantity_checked')) {
      context.handle(
        _remainingQuantityCheckedMeta,
        remainingQuantityChecked.isAcceptableOrUnknown(
          data['remaining_quantity_checked']!,
          _remainingQuantityCheckedMeta,
        ),
      );
    }
    if (data.containsKey('questions_prepared')) {
      context.handle(
        _questionsPreparedMeta,
        questionsPrepared.isAcceptableOrUnknown(
          data['questions_prepared']!,
          _questionsPreparedMeta,
        ),
      );
    }
    if (data.containsKey('visit_note')) {
      context.handle(
        _visitNoteMeta,
        visitNote.isAcceptableOrUnknown(data['visit_note']!, _visitNoteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RenewalReadinessData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RenewalReadinessData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      )!,
      nextVisitOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_visit_on'],
      ),
      prescriptionPhotoChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prescription_photo_checked'],
      )!,
      remainingQuantityChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remaining_quantity_checked'],
      )!,
      questionsPrepared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}questions_prepared'],
      )!,
      visitNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RenewalReadinessTable createAlias(String alias) {
    return $RenewalReadinessTable(attachedDatabase, alias);
  }
}

class RenewalReadinessData extends DataClass
    implements Insertable<RenewalReadinessData> {
  final String id;
  final String inventoryItemId;
  final DateTime? nextVisitOn;
  final bool prescriptionPhotoChecked;
  final bool remainingQuantityChecked;
  final bool questionsPrepared;
  final String? visitNote;
  final DateTime updatedAt;
  const RenewalReadinessData({
    required this.id,
    required this.inventoryItemId,
    this.nextVisitOn,
    required this.prescriptionPhotoChecked,
    required this.remainingQuantityChecked,
    required this.questionsPrepared,
    this.visitNote,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_item_id'] = Variable<String>(inventoryItemId);
    if (!nullToAbsent || nextVisitOn != null) {
      map['next_visit_on'] = Variable<DateTime>(nextVisitOn);
    }
    map['prescription_photo_checked'] = Variable<bool>(
      prescriptionPhotoChecked,
    );
    map['remaining_quantity_checked'] = Variable<bool>(
      remainingQuantityChecked,
    );
    map['questions_prepared'] = Variable<bool>(questionsPrepared);
    if (!nullToAbsent || visitNote != null) {
      map['visit_note'] = Variable<String>(visitNote);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RenewalReadinessCompanion toCompanion(bool nullToAbsent) {
    return RenewalReadinessCompanion(
      id: Value(id),
      inventoryItemId: Value(inventoryItemId),
      nextVisitOn: nextVisitOn == null && nullToAbsent
          ? const Value.absent()
          : Value(nextVisitOn),
      prescriptionPhotoChecked: Value(prescriptionPhotoChecked),
      remainingQuantityChecked: Value(remainingQuantityChecked),
      questionsPrepared: Value(questionsPrepared),
      visitNote: visitNote == null && nullToAbsent
          ? const Value.absent()
          : Value(visitNote),
      updatedAt: Value(updatedAt),
    );
  }

  factory RenewalReadinessData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RenewalReadinessData(
      id: serializer.fromJson<String>(json['id']),
      inventoryItemId: serializer.fromJson<String>(json['inventoryItemId']),
      nextVisitOn: serializer.fromJson<DateTime?>(json['nextVisitOn']),
      prescriptionPhotoChecked: serializer.fromJson<bool>(
        json['prescriptionPhotoChecked'],
      ),
      remainingQuantityChecked: serializer.fromJson<bool>(
        json['remainingQuantityChecked'],
      ),
      questionsPrepared: serializer.fromJson<bool>(json['questionsPrepared']),
      visitNote: serializer.fromJson<String?>(json['visitNote']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryItemId': serializer.toJson<String>(inventoryItemId),
      'nextVisitOn': serializer.toJson<DateTime?>(nextVisitOn),
      'prescriptionPhotoChecked': serializer.toJson<bool>(
        prescriptionPhotoChecked,
      ),
      'remainingQuantityChecked': serializer.toJson<bool>(
        remainingQuantityChecked,
      ),
      'questionsPrepared': serializer.toJson<bool>(questionsPrepared),
      'visitNote': serializer.toJson<String?>(visitNote),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RenewalReadinessData copyWith({
    String? id,
    String? inventoryItemId,
    Value<DateTime?> nextVisitOn = const Value.absent(),
    bool? prescriptionPhotoChecked,
    bool? remainingQuantityChecked,
    bool? questionsPrepared,
    Value<String?> visitNote = const Value.absent(),
    DateTime? updatedAt,
  }) => RenewalReadinessData(
    id: id ?? this.id,
    inventoryItemId: inventoryItemId ?? this.inventoryItemId,
    nextVisitOn: nextVisitOn.present ? nextVisitOn.value : this.nextVisitOn,
    prescriptionPhotoChecked:
        prescriptionPhotoChecked ?? this.prescriptionPhotoChecked,
    remainingQuantityChecked:
        remainingQuantityChecked ?? this.remainingQuantityChecked,
    questionsPrepared: questionsPrepared ?? this.questionsPrepared,
    visitNote: visitNote.present ? visitNote.value : this.visitNote,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RenewalReadinessData copyWithCompanion(RenewalReadinessCompanion data) {
    return RenewalReadinessData(
      id: data.id.present ? data.id.value : this.id,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      nextVisitOn: data.nextVisitOn.present
          ? data.nextVisitOn.value
          : this.nextVisitOn,
      prescriptionPhotoChecked: data.prescriptionPhotoChecked.present
          ? data.prescriptionPhotoChecked.value
          : this.prescriptionPhotoChecked,
      remainingQuantityChecked: data.remainingQuantityChecked.present
          ? data.remainingQuantityChecked.value
          : this.remainingQuantityChecked,
      questionsPrepared: data.questionsPrepared.present
          ? data.questionsPrepared.value
          : this.questionsPrepared,
      visitNote: data.visitNote.present ? data.visitNote.value : this.visitNote,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RenewalReadinessData(')
          ..write('id: $id, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('nextVisitOn: $nextVisitOn, ')
          ..write('prescriptionPhotoChecked: $prescriptionPhotoChecked, ')
          ..write('remainingQuantityChecked: $remainingQuantityChecked, ')
          ..write('questionsPrepared: $questionsPrepared, ')
          ..write('visitNote: $visitNote, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryItemId,
    nextVisitOn,
    prescriptionPhotoChecked,
    remainingQuantityChecked,
    questionsPrepared,
    visitNote,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RenewalReadinessData &&
          other.id == this.id &&
          other.inventoryItemId == this.inventoryItemId &&
          other.nextVisitOn == this.nextVisitOn &&
          other.prescriptionPhotoChecked == this.prescriptionPhotoChecked &&
          other.remainingQuantityChecked == this.remainingQuantityChecked &&
          other.questionsPrepared == this.questionsPrepared &&
          other.visitNote == this.visitNote &&
          other.updatedAt == this.updatedAt);
}

class RenewalReadinessCompanion extends UpdateCompanion<RenewalReadinessData> {
  final Value<String> id;
  final Value<String> inventoryItemId;
  final Value<DateTime?> nextVisitOn;
  final Value<bool> prescriptionPhotoChecked;
  final Value<bool> remainingQuantityChecked;
  final Value<bool> questionsPrepared;
  final Value<String?> visitNote;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RenewalReadinessCompanion({
    this.id = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.nextVisitOn = const Value.absent(),
    this.prescriptionPhotoChecked = const Value.absent(),
    this.remainingQuantityChecked = const Value.absent(),
    this.questionsPrepared = const Value.absent(),
    this.visitNote = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RenewalReadinessCompanion.insert({
    required String id,
    required String inventoryItemId,
    this.nextVisitOn = const Value.absent(),
    this.prescriptionPhotoChecked = const Value.absent(),
    this.remainingQuantityChecked = const Value.absent(),
    this.questionsPrepared = const Value.absent(),
    this.visitNote = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryItemId = Value(inventoryItemId);
  static Insertable<RenewalReadinessData> custom({
    Expression<String>? id,
    Expression<String>? inventoryItemId,
    Expression<DateTime>? nextVisitOn,
    Expression<bool>? prescriptionPhotoChecked,
    Expression<bool>? remainingQuantityChecked,
    Expression<bool>? questionsPrepared,
    Expression<String>? visitNote,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (nextVisitOn != null) 'next_visit_on': nextVisitOn,
      if (prescriptionPhotoChecked != null)
        'prescription_photo_checked': prescriptionPhotoChecked,
      if (remainingQuantityChecked != null)
        'remaining_quantity_checked': remainingQuantityChecked,
      if (questionsPrepared != null) 'questions_prepared': questionsPrepared,
      if (visitNote != null) 'visit_note': visitNote,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RenewalReadinessCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryItemId,
    Value<DateTime?>? nextVisitOn,
    Value<bool>? prescriptionPhotoChecked,
    Value<bool>? remainingQuantityChecked,
    Value<bool>? questionsPrepared,
    Value<String?>? visitNote,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RenewalReadinessCompanion(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      nextVisitOn: nextVisitOn ?? this.nextVisitOn,
      prescriptionPhotoChecked:
          prescriptionPhotoChecked ?? this.prescriptionPhotoChecked,
      remainingQuantityChecked:
          remainingQuantityChecked ?? this.remainingQuantityChecked,
      questionsPrepared: questionsPrepared ?? this.questionsPrepared,
      visitNote: visitNote ?? this.visitNote,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (nextVisitOn.present) {
      map['next_visit_on'] = Variable<DateTime>(nextVisitOn.value);
    }
    if (prescriptionPhotoChecked.present) {
      map['prescription_photo_checked'] = Variable<bool>(
        prescriptionPhotoChecked.value,
      );
    }
    if (remainingQuantityChecked.present) {
      map['remaining_quantity_checked'] = Variable<bool>(
        remainingQuantityChecked.value,
      );
    }
    if (questionsPrepared.present) {
      map['questions_prepared'] = Variable<bool>(questionsPrepared.value);
    }
    if (visitNote.present) {
      map['visit_note'] = Variable<String>(visitNote.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RenewalReadinessCompanion(')
          ..write('id: $id, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('nextVisitOn: $nextVisitOn, ')
          ..write('prescriptionPhotoChecked: $prescriptionPhotoChecked, ')
          ..write('remainingQuantityChecked: $remainingQuantityChecked, ')
          ..write('questionsPrepared: $questionsPrepared, ')
          ..write('visitNote: $visitNote, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hidesMedicineNameMeta = const VerificationMeta(
    'hidesMedicineName',
  );
  @override
  late final GeneratedColumn<bool> hidesMedicineName = GeneratedColumn<bool>(
    'hides_medicine_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hides_medicine_name" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _privateLabelMeta = const VerificationMeta(
    'privateLabel',
  );
  @override
  late final GeneratedColumn<String> privateLabel = GeneratedColumn<String>(
    'private_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryItemId,
    kind,
    scheduledAt,
    enabled,
    hidesMedicineName,
    privateLabel,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('hides_medicine_name')) {
      context.handle(
        _hidesMedicineNameMeta,
        hidesMedicineName.isAcceptableOrUnknown(
          data['hides_medicine_name']!,
          _hidesMedicineNameMeta,
        ),
      );
    }
    if (data.containsKey('private_label')) {
      context.handle(
        _privateLabelMeta,
        privateLabel.isAcceptableOrUnknown(
          data['private_label']!,
          _privateLabelMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      hidesMedicineName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hides_medicine_name'],
      )!,
      privateLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String? inventoryItemId;
  final String kind;
  final DateTime scheduledAt;
  final bool enabled;
  final bool hidesMedicineName;
  final String? privateLabel;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Reminder({
    required this.id,
    this.inventoryItemId,
    required this.kind,
    required this.scheduledAt,
    required this.enabled,
    required this.hidesMedicineName,
    this.privateLabel,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || inventoryItemId != null) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId);
    }
    map['kind'] = Variable<String>(kind);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['enabled'] = Variable<bool>(enabled);
    map['hides_medicine_name'] = Variable<bool>(hidesMedicineName);
    if (!nullToAbsent || privateLabel != null) {
      map['private_label'] = Variable<String>(privateLabel);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      inventoryItemId: inventoryItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(inventoryItemId),
      kind: Value(kind),
      scheduledAt: Value(scheduledAt),
      enabled: Value(enabled),
      hidesMedicineName: Value(hidesMedicineName),
      privateLabel: privateLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(privateLabel),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      inventoryItemId: serializer.fromJson<String?>(json['inventoryItemId']),
      kind: serializer.fromJson<String>(json['kind']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      hidesMedicineName: serializer.fromJson<bool>(json['hidesMedicineName']),
      privateLabel: serializer.fromJson<String?>(json['privateLabel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryItemId': serializer.toJson<String?>(inventoryItemId),
      'kind': serializer.toJson<String>(kind),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'enabled': serializer.toJson<bool>(enabled),
      'hidesMedicineName': serializer.toJson<bool>(hidesMedicineName),
      'privateLabel': serializer.toJson<String?>(privateLabel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Reminder copyWith({
    String? id,
    Value<String?> inventoryItemId = const Value.absent(),
    String? kind,
    DateTime? scheduledAt,
    bool? enabled,
    bool? hidesMedicineName,
    Value<String?> privateLabel = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    inventoryItemId: inventoryItemId.present
        ? inventoryItemId.value
        : this.inventoryItemId,
    kind: kind ?? this.kind,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    enabled: enabled ?? this.enabled,
    hidesMedicineName: hidesMedicineName ?? this.hidesMedicineName,
    privateLabel: privateLabel.present ? privateLabel.value : this.privateLabel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      hidesMedicineName: data.hidesMedicineName.present
          ? data.hidesMedicineName.value
          : this.hidesMedicineName,
      privateLabel: data.privateLabel.present
          ? data.privateLabel.value
          : this.privateLabel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('kind: $kind, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('enabled: $enabled, ')
          ..write('hidesMedicineName: $hidesMedicineName, ')
          ..write('privateLabel: $privateLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryItemId,
    kind,
    scheduledAt,
    enabled,
    hidesMedicineName,
    privateLabel,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.inventoryItemId == this.inventoryItemId &&
          other.kind == this.kind &&
          other.scheduledAt == this.scheduledAt &&
          other.enabled == this.enabled &&
          other.hidesMedicineName == this.hidesMedicineName &&
          other.privateLabel == this.privateLabel &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String?> inventoryItemId;
  final Value<String> kind;
  final Value<DateTime> scheduledAt;
  final Value<bool> enabled;
  final Value<bool> hidesMedicineName;
  final Value<String?> privateLabel;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.enabled = const Value.absent(),
    this.hidesMedicineName = const Value.absent(),
    this.privateLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    this.inventoryItemId = const Value.absent(),
    required String kind,
    required DateTime scheduledAt,
    this.enabled = const Value.absent(),
    this.hidesMedicineName = const Value.absent(),
    this.privateLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       scheduledAt = Value(scheduledAt);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? inventoryItemId,
    Expression<String>? kind,
    Expression<DateTime>? scheduledAt,
    Expression<bool>? enabled,
    Expression<bool>? hidesMedicineName,
    Expression<String>? privateLabel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (kind != null) 'kind': kind,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (enabled != null) 'enabled': enabled,
      if (hidesMedicineName != null) 'hides_medicine_name': hidesMedicineName,
      if (privateLabel != null) 'private_label': privateLabel,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String?>? inventoryItemId,
    Value<String>? kind,
    Value<DateTime>? scheduledAt,
    Value<bool>? enabled,
    Value<bool>? hidesMedicineName,
    Value<String?>? privateLabel,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      kind: kind ?? this.kind,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      enabled: enabled ?? this.enabled,
      hidesMedicineName: hidesMedicineName ?? this.hidesMedicineName,
      privateLabel: privateLabel ?? this.privateLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (hidesMedicineName.present) {
      map['hides_medicine_name'] = Variable<bool>(hidesMedicineName.value);
    }
    if (privateLabel.present) {
      map['private_label'] = Variable<String>(privateLabel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('kind: $kind, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('enabled: $enabled, ')
          ..write('hidesMedicineName: $hidesMedicineName, ')
          ..write('privateLabel: $privateLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogCacheEntriesTable extends CatalogCacheEntries
    with TableInfo<$CatalogCacheEntriesTable, CatalogCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheNamespaceMeta = const VerificationMeta(
    'cacheNamespace',
  );
  @override
  late final GeneratedColumn<String> cacheNamespace = GeneratedColumn<String>(
    'cache_namespace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    cacheNamespace,
    cacheKey,
    formatVersion,
    payloadJson,
    byteSize,
    cachedAt,
    expiresAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('cache_namespace')) {
      context.handle(
        _cacheNamespaceMeta,
        cacheNamespace.isAcceptableOrUnknown(
          data['cache_namespace']!,
          _cacheNamespaceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheNamespaceMeta);
    }
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatVersionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, cacheNamespace, cacheKey};
  @override
  CatalogCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogCacheEntry(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      cacheNamespace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_namespace'],
      )!,
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $CatalogCacheEntriesTable createAlias(String alias) {
    return $CatalogCacheEntriesTable(attachedDatabase, alias);
  }
}

class CatalogCacheEntry extends DataClass
    implements Insertable<CatalogCacheEntry> {
  final String accountId;
  final String cacheNamespace;
  final String cacheKey;
  final int formatVersion;
  final String payloadJson;
  final int byteSize;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final DateTime lastAccessedAt;
  const CatalogCacheEntry({
    required this.accountId,
    required this.cacheNamespace,
    required this.cacheKey,
    required this.formatVersion,
    required this.payloadJson,
    required this.byteSize,
    required this.cachedAt,
    required this.expiresAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['cache_namespace'] = Variable<String>(cacheNamespace);
    map['cache_key'] = Variable<String>(cacheKey);
    map['format_version'] = Variable<int>(formatVersion);
    map['payload_json'] = Variable<String>(payloadJson);
    map['byte_size'] = Variable<int>(byteSize);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  CatalogCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CatalogCacheEntriesCompanion(
      accountId: Value(accountId),
      cacheNamespace: Value(cacheNamespace),
      cacheKey: Value(cacheKey),
      formatVersion: Value(formatVersion),
      payloadJson: Value(payloadJson),
      byteSize: Value(byteSize),
      cachedAt: Value(cachedAt),
      expiresAt: Value(expiresAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory CatalogCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogCacheEntry(
      accountId: serializer.fromJson<String>(json['accountId']),
      cacheNamespace: serializer.fromJson<String>(json['cacheNamespace']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'cacheNamespace': serializer.toJson<String>(cacheNamespace),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'byteSize': serializer.toJson<int>(byteSize),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  CatalogCacheEntry copyWith({
    String? accountId,
    String? cacheNamespace,
    String? cacheKey,
    int? formatVersion,
    String? payloadJson,
    int? byteSize,
    DateTime? cachedAt,
    DateTime? expiresAt,
    DateTime? lastAccessedAt,
  }) => CatalogCacheEntry(
    accountId: accountId ?? this.accountId,
    cacheNamespace: cacheNamespace ?? this.cacheNamespace,
    cacheKey: cacheKey ?? this.cacheKey,
    formatVersion: formatVersion ?? this.formatVersion,
    payloadJson: payloadJson ?? this.payloadJson,
    byteSize: byteSize ?? this.byteSize,
    cachedAt: cachedAt ?? this.cachedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  CatalogCacheEntry copyWithCompanion(CatalogCacheEntriesCompanion data) {
    return CatalogCacheEntry(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cacheNamespace: data.cacheNamespace.present
          ? data.cacheNamespace.value
          : this.cacheNamespace,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheEntry(')
          ..write('accountId: $accountId, ')
          ..write('cacheNamespace: $cacheNamespace, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('byteSize: $byteSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    cacheNamespace,
    cacheKey,
    formatVersion,
    payloadJson,
    byteSize,
    cachedAt,
    expiresAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogCacheEntry &&
          other.accountId == this.accountId &&
          other.cacheNamespace == this.cacheNamespace &&
          other.cacheKey == this.cacheKey &&
          other.formatVersion == this.formatVersion &&
          other.payloadJson == this.payloadJson &&
          other.byteSize == this.byteSize &&
          other.cachedAt == this.cachedAt &&
          other.expiresAt == this.expiresAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class CatalogCacheEntriesCompanion extends UpdateCompanion<CatalogCacheEntry> {
  final Value<String> accountId;
  final Value<String> cacheNamespace;
  final Value<String> cacheKey;
  final Value<int> formatVersion;
  final Value<String> payloadJson;
  final Value<int> byteSize;
  final Value<DateTime> cachedAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const CatalogCacheEntriesCompanion({
    this.accountId = const Value.absent(),
    this.cacheNamespace = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogCacheEntriesCompanion.insert({
    required String accountId,
    required String cacheNamespace,
    required String cacheKey,
    required int formatVersion,
    required String payloadJson,
    required int byteSize,
    required DateTime cachedAt,
    required DateTime expiresAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       cacheNamespace = Value(cacheNamespace),
       cacheKey = Value(cacheKey),
       formatVersion = Value(formatVersion),
       payloadJson = Value(payloadJson),
       byteSize = Value(byteSize),
       cachedAt = Value(cachedAt),
       expiresAt = Value(expiresAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<CatalogCacheEntry> custom({
    Expression<String>? accountId,
    Expression<String>? cacheNamespace,
    Expression<String>? cacheKey,
    Expression<int>? formatVersion,
    Expression<String>? payloadJson,
    Expression<int>? byteSize,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (cacheNamespace != null) 'cache_namespace': cacheNamespace,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (formatVersion != null) 'format_version': formatVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (byteSize != null) 'byte_size': byteSize,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogCacheEntriesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? cacheNamespace,
    Value<String>? cacheKey,
    Value<int>? formatVersion,
    Value<String>? payloadJson,
    Value<int>? byteSize,
    Value<DateTime>? cachedAt,
    Value<DateTime>? expiresAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return CatalogCacheEntriesCompanion(
      accountId: accountId ?? this.accountId,
      cacheNamespace: cacheNamespace ?? this.cacheNamespace,
      cacheKey: cacheKey ?? this.cacheKey,
      formatVersion: formatVersion ?? this.formatVersion,
      payloadJson: payloadJson ?? this.payloadJson,
      byteSize: byteSize ?? this.byteSize,
      cachedAt: cachedAt ?? this.cachedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cacheNamespace.present) {
      map['cache_namespace'] = Variable<String>(cacheNamespace.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheEntriesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('cacheNamespace: $cacheNamespace, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('byteSize: $byteSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfficialImageCacheEntriesTable extends OfficialImageCacheEntries
    with TableInfo<$OfficialImageCacheEntriesTable, OfficialImageCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfficialImageCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageBytesMeta = const VerificationMeta(
    'imageBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> imageBytes = GeneratedColumn<Uint8List>(
    'image_bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    imageUrl,
    imageBytes,
    contentType,
    byteSize,
    cachedAt,
    expiresAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'official_image_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfficialImageCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_imageUrlMeta);
    }
    if (data.containsKey('image_bytes')) {
      context.handle(
        _imageBytesMeta,
        imageBytes.isAcceptableOrUnknown(data['image_bytes']!, _imageBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_imageBytesMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, imageUrl};
  @override
  OfficialImageCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfficialImageCacheEntry(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      imageBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}image_bytes'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $OfficialImageCacheEntriesTable createAlias(String alias) {
    return $OfficialImageCacheEntriesTable(attachedDatabase, alias);
  }
}

class OfficialImageCacheEntry extends DataClass
    implements Insertable<OfficialImageCacheEntry> {
  final String accountId;
  final String imageUrl;
  final Uint8List imageBytes;
  final String? contentType;
  final int byteSize;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final DateTime lastAccessedAt;
  const OfficialImageCacheEntry({
    required this.accountId,
    required this.imageUrl,
    required this.imageBytes,
    this.contentType,
    required this.byteSize,
    required this.cachedAt,
    required this.expiresAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['image_url'] = Variable<String>(imageUrl);
    map['image_bytes'] = Variable<Uint8List>(imageBytes);
    if (!nullToAbsent || contentType != null) {
      map['content_type'] = Variable<String>(contentType);
    }
    map['byte_size'] = Variable<int>(byteSize);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  OfficialImageCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return OfficialImageCacheEntriesCompanion(
      accountId: Value(accountId),
      imageUrl: Value(imageUrl),
      imageBytes: Value(imageBytes),
      contentType: contentType == null && nullToAbsent
          ? const Value.absent()
          : Value(contentType),
      byteSize: Value(byteSize),
      cachedAt: Value(cachedAt),
      expiresAt: Value(expiresAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory OfficialImageCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfficialImageCacheEntry(
      accountId: serializer.fromJson<String>(json['accountId']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      imageBytes: serializer.fromJson<Uint8List>(json['imageBytes']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'imageBytes': serializer.toJson<Uint8List>(imageBytes),
      'contentType': serializer.toJson<String?>(contentType),
      'byteSize': serializer.toJson<int>(byteSize),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  OfficialImageCacheEntry copyWith({
    String? accountId,
    String? imageUrl,
    Uint8List? imageBytes,
    Value<String?> contentType = const Value.absent(),
    int? byteSize,
    DateTime? cachedAt,
    DateTime? expiresAt,
    DateTime? lastAccessedAt,
  }) => OfficialImageCacheEntry(
    accountId: accountId ?? this.accountId,
    imageUrl: imageUrl ?? this.imageUrl,
    imageBytes: imageBytes ?? this.imageBytes,
    contentType: contentType.present ? contentType.value : this.contentType,
    byteSize: byteSize ?? this.byteSize,
    cachedAt: cachedAt ?? this.cachedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  OfficialImageCacheEntry copyWithCompanion(
    OfficialImageCacheEntriesCompanion data,
  ) {
    return OfficialImageCacheEntry(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      imageBytes: data.imageBytes.present
          ? data.imageBytes.value
          : this.imageBytes,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfficialImageCacheEntry(')
          ..write('accountId: $accountId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imageBytes: $imageBytes, ')
          ..write('contentType: $contentType, ')
          ..write('byteSize: $byteSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    imageUrl,
    $driftBlobEquality.hash(imageBytes),
    contentType,
    byteSize,
    cachedAt,
    expiresAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfficialImageCacheEntry &&
          other.accountId == this.accountId &&
          other.imageUrl == this.imageUrl &&
          $driftBlobEquality.equals(other.imageBytes, this.imageBytes) &&
          other.contentType == this.contentType &&
          other.byteSize == this.byteSize &&
          other.cachedAt == this.cachedAt &&
          other.expiresAt == this.expiresAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class OfficialImageCacheEntriesCompanion
    extends UpdateCompanion<OfficialImageCacheEntry> {
  final Value<String> accountId;
  final Value<String> imageUrl;
  final Value<Uint8List> imageBytes;
  final Value<String?> contentType;
  final Value<int> byteSize;
  final Value<DateTime> cachedAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const OfficialImageCacheEntriesCompanion({
    this.accountId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.imageBytes = const Value.absent(),
    this.contentType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfficialImageCacheEntriesCompanion.insert({
    required String accountId,
    required String imageUrl,
    required Uint8List imageBytes,
    this.contentType = const Value.absent(),
    required int byteSize,
    required DateTime cachedAt,
    required DateTime expiresAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       imageUrl = Value(imageUrl),
       imageBytes = Value(imageBytes),
       byteSize = Value(byteSize),
       cachedAt = Value(cachedAt),
       expiresAt = Value(expiresAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<OfficialImageCacheEntry> custom({
    Expression<String>? accountId,
    Expression<String>? imageUrl,
    Expression<Uint8List>? imageBytes,
    Expression<String>? contentType,
    Expression<int>? byteSize,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (imageBytes != null) 'image_bytes': imageBytes,
      if (contentType != null) 'content_type': contentType,
      if (byteSize != null) 'byte_size': byteSize,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfficialImageCacheEntriesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? imageUrl,
    Value<Uint8List>? imageBytes,
    Value<String?>? contentType,
    Value<int>? byteSize,
    Value<DateTime>? cachedAt,
    Value<DateTime>? expiresAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return OfficialImageCacheEntriesCompanion(
      accountId: accountId ?? this.accountId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      contentType: contentType ?? this.contentType,
      byteSize: byteSize ?? this.byteSize,
      cachedAt: cachedAt ?? this.cachedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (imageBytes.present) {
      map['image_bytes'] = Variable<Uint8List>(imageBytes.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfficialImageCacheEntriesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imageBytes: $imageBytes, ')
          ..write('contentType: $contentType, ')
          ..write('byteSize: $byteSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationPrivacyMeta =
      const VerificationMeta('notificationPrivacy');
  @override
  late final GeneratedColumn<bool> notificationPrivacy = GeneratedColumn<bool>(
    'notification_privacy',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notification_privacy" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _localeCodeMeta = const VerificationMeta(
    'localeCode',
  );
  @override
  late final GeneratedColumn<String> localeCode = GeneratedColumn<String>(
    'locale_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ko'),
  );
  static const VerificationMeta _environmentMeta = const VerificationMeta(
    'environment',
  );
  @override
  late final GeneratedColumn<String> environment = GeneratedColumn<String>(
    'environment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('production'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    onboardingCompleted,
    notificationPrivacy,
    localeCode,
    environment,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('notification_privacy')) {
      context.handle(
        _notificationPrivacyMeta,
        notificationPrivacy.isAcceptableOrUnknown(
          data['notification_privacy']!,
          _notificationPrivacyMeta,
        ),
      );
    }
    if (data.containsKey('locale_code')) {
      context.handle(
        _localeCodeMeta,
        localeCode.isAcceptableOrUnknown(data['locale_code']!, _localeCodeMeta),
      );
    }
    if (data.containsKey('environment')) {
      context.handle(
        _environmentMeta,
        environment.isAcceptableOrUnknown(
          data['environment']!,
          _environmentMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      notificationPrivacy: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_privacy'],
      )!,
      localeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_code'],
      )!,
      environment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final bool onboardingCompleted;
  final bool notificationPrivacy;
  final String localeCode;
  final String environment;
  final DateTime updatedAt;
  const AppSetting({
    required this.id,
    required this.onboardingCompleted,
    required this.notificationPrivacy,
    required this.localeCode,
    required this.environment,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['notification_privacy'] = Variable<bool>(notificationPrivacy);
    map['locale_code'] = Variable<String>(localeCode);
    map['environment'] = Variable<String>(environment);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      onboardingCompleted: Value(onboardingCompleted),
      notificationPrivacy: Value(notificationPrivacy),
      localeCode: Value(localeCode),
      environment: Value(environment),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      notificationPrivacy: serializer.fromJson<bool>(
        json['notificationPrivacy'],
      ),
      localeCode: serializer.fromJson<String>(json['localeCode']),
      environment: serializer.fromJson<String>(json['environment']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'notificationPrivacy': serializer.toJson<bool>(notificationPrivacy),
      'localeCode': serializer.toJson<String>(localeCode),
      'environment': serializer.toJson<String>(environment),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({
    int? id,
    bool? onboardingCompleted,
    bool? notificationPrivacy,
    String? localeCode,
    String? environment,
    DateTime? updatedAt,
  }) => AppSetting(
    id: id ?? this.id,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    notificationPrivacy: notificationPrivacy ?? this.notificationPrivacy,
    localeCode: localeCode ?? this.localeCode,
    environment: environment ?? this.environment,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      notificationPrivacy: data.notificationPrivacy.present
          ? data.notificationPrivacy.value
          : this.notificationPrivacy,
      localeCode: data.localeCode.present
          ? data.localeCode.value
          : this.localeCode,
      environment: data.environment.present
          ? data.environment.value
          : this.environment,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('notificationPrivacy: $notificationPrivacy, ')
          ..write('localeCode: $localeCode, ')
          ..write('environment: $environment, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    onboardingCompleted,
    notificationPrivacy,
    localeCode,
    environment,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.notificationPrivacy == this.notificationPrivacy &&
          other.localeCode == this.localeCode &&
          other.environment == this.environment &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<bool> onboardingCompleted;
  final Value<bool> notificationPrivacy;
  final Value<String> localeCode;
  final Value<String> environment;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.notificationPrivacy = const Value.absent(),
    this.localeCode = const Value.absent(),
    this.environment = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.notificationPrivacy = const Value.absent(),
    this.localeCode = const Value.absent(),
    this.environment = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<bool>? onboardingCompleted,
    Expression<bool>? notificationPrivacy,
    Expression<String>? localeCode,
    Expression<String>? environment,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (notificationPrivacy != null)
        'notification_privacy': notificationPrivacy,
      if (localeCode != null) 'locale_code': localeCode,
      if (environment != null) 'environment': environment,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? onboardingCompleted,
    Value<bool>? notificationPrivacy,
    Value<String>? localeCode,
    Value<String>? environment,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationPrivacy: notificationPrivacy ?? this.notificationPrivacy,
      localeCode: localeCode ?? this.localeCode,
      environment: environment ?? this.environment,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (notificationPrivacy.present) {
      map['notification_privacy'] = Variable<bool>(notificationPrivacy.value);
    }
    if (localeCode.present) {
      map['locale_code'] = Variable<String>(localeCode.value);
    }
    if (environment.present) {
      map['environment'] = Variable<String>(environment.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('notificationPrivacy: $notificationPrivacy, ')
          ..write('localeCode: $localeCode, ')
          ..write('environment: $environment, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $MemberProfilesTable memberProfiles = $MemberProfilesTable(this);
  late final $InventoryContainersTable inventoryContainers =
      $InventoryContainersTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $RenewalReadinessTable renewalReadiness = $RenewalReadinessTable(
    this,
  );
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $CatalogCacheEntriesTable catalogCacheEntries =
      $CatalogCacheEntriesTable(this);
  late final $OfficialImageCacheEntriesTable officialImageCacheEntries =
      $OfficialImageCacheEntriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    households,
    memberProfiles,
    inventoryContainers,
    inventoryItems,
    renewalReadiness,
    reminders,
    catalogCacheEntries,
    officialImageCacheEntries,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'households',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('member_profiles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'households',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('inventory_containers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'member_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('inventory_containers', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'inventory_containers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('inventory_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'member_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('inventory_items', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'inventory_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('renewal_readiness', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'inventory_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HouseholdsTableCreateCompanionBuilder =
    HouseholdsCompanion Function({
      required String id,
      required String name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$HouseholdsTableUpdateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$HouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $HouseholdsTable, Household> {
  $$HouseholdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MemberProfilesTable, List<MemberProfile>>
  _memberProfilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.memberProfiles,
    aliasName: 'households__id__member_profiles__household_id',
  );

  $$MemberProfilesTableProcessedTableManager get memberProfilesRefs {
    final manager = $$MemberProfilesTableTableManager(
      $_db,
      $_db.memberProfiles,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_memberProfilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InventoryContainersTable,
    List<InventoryContainer>
  >
  _inventoryContainersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inventoryContainers,
        aliasName: 'households__id__inventory_containers__household_id',
      );

  $$InventoryContainersTableProcessedTableManager get inventoryContainersRefs {
    final manager = $$InventoryContainersTableTableManager(
      $_db,
      $_db.inventoryContainers,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryContainersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> memberProfilesRefs(
    Expression<bool> Function($$MemberProfilesTableFilterComposer f) f,
  ) {
    final $$MemberProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableFilterComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryContainersRefs(
    Expression<bool> Function($$InventoryContainersTableFilterComposer f) f,
  ) {
    final $$InventoryContainersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryContainers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryContainersTableFilterComposer(
            $db: $db,
            $table: $db.inventoryContainers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> memberProfilesRefs<T extends Object>(
    Expression<T> Function($$MemberProfilesTableAnnotationComposer a) f,
  ) {
    final $$MemberProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inventoryContainersRefs<T extends Object>(
    Expression<T> Function($$InventoryContainersTableAnnotationComposer a) f,
  ) {
    final $$InventoryContainersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryContainers,
          getReferencedColumn: (t) => t.householdId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryContainersTableAnnotationComposer(
                $db: $db,
                $table: $db.inventoryContainers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$HouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdsTable,
          Household,
          $$HouseholdsTableFilterComposer,
          $$HouseholdsTableOrderingComposer,
          $$HouseholdsTableAnnotationComposer,
          $$HouseholdsTableCreateCompanionBuilder,
          $$HouseholdsTableUpdateCompanionBuilder,
          (Household, $$HouseholdsTableReferences),
          Household,
          PrefetchHooks Function({
            bool memberProfilesRefs,
            bool inventoryContainersRefs,
          })
        > {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({memberProfilesRefs = false, inventoryContainersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (memberProfilesRefs) db.memberProfiles,
                    if (inventoryContainersRefs) db.inventoryContainers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (memberProfilesRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          MemberProfile
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._memberProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).memberProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryContainersRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          InventoryContainer
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._inventoryContainersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryContainersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdsTable,
      Household,
      $$HouseholdsTableFilterComposer,
      $$HouseholdsTableOrderingComposer,
      $$HouseholdsTableAnnotationComposer,
      $$HouseholdsTableCreateCompanionBuilder,
      $$HouseholdsTableUpdateCompanionBuilder,
      (Household, $$HouseholdsTableReferences),
      Household,
      PrefetchHooks Function({
        bool memberProfilesRefs,
        bool inventoryContainersRefs,
      })
    >;
typedef $$MemberProfilesTableCreateCompanionBuilder =
    MemberProfilesCompanion Function({
      required String id,
      required String householdId,
      required String displayName,
      Value<String> colorHex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MemberProfilesTableUpdateCompanionBuilder =
    MemberProfilesCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> displayName,
      Value<String> colorHex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MemberProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $MemberProfilesTable, MemberProfile> {
  $$MemberProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) => db.households
      .createAlias('member_profiles__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $InventoryContainersTable,
    List<InventoryContainer>
  >
  _inventoryContainersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inventoryContainers,
        aliasName: 'member_profiles__id__inventory_containers__owner_member_id',
      );

  $$InventoryContainersTableProcessedTableManager get inventoryContainersRefs {
    final manager = $$InventoryContainersTableTableManager(
      $_db,
      $_db.inventoryContainers,
    ).filter((f) => f.ownerMemberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryContainersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InventoryItemsTable, List<InventoryItem>>
  _inventoryItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryItems,
    aliasName: 'member_profiles__id__inventory_items__assigned_member_id',
  );

  $$InventoryItemsTableProcessedTableManager get inventoryItemsRefs {
    final manager = $$InventoryItemsTableTableManager($_db, $_db.inventoryItems)
        .filter(
          (f) => f.assignedMemberId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_inventoryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MemberProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $MemberProfilesTable> {
  $$MemberProfilesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> inventoryContainersRefs(
    Expression<bool> Function($$InventoryContainersTableFilterComposer f) f,
  ) {
    final $$InventoryContainersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryContainers,
      getReferencedColumn: (t) => t.ownerMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryContainersTableFilterComposer(
            $db: $db,
            $table: $db.inventoryContainers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryItemsRefs(
    Expression<bool> Function($$InventoryItemsTableFilterComposer f) f,
  ) {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.assignedMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemberProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemberProfilesTable> {
  $$MemberProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemberProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemberProfilesTable> {
  $$MemberProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> inventoryContainersRefs<T extends Object>(
    Expression<T> Function($$InventoryContainersTableAnnotationComposer a) f,
  ) {
    final $$InventoryContainersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryContainers,
          getReferencedColumn: (t) => t.ownerMemberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryContainersTableAnnotationComposer(
                $db: $db,
                $table: $db.inventoryContainers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> inventoryItemsRefs<T extends Object>(
    Expression<T> Function($$InventoryItemsTableAnnotationComposer a) f,
  ) {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.assignedMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemberProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemberProfilesTable,
          MemberProfile,
          $$MemberProfilesTableFilterComposer,
          $$MemberProfilesTableOrderingComposer,
          $$MemberProfilesTableAnnotationComposer,
          $$MemberProfilesTableCreateCompanionBuilder,
          $$MemberProfilesTableUpdateCompanionBuilder,
          (MemberProfile, $$MemberProfilesTableReferences),
          MemberProfile,
          PrefetchHooks Function({
            bool householdId,
            bool inventoryContainersRefs,
            bool inventoryItemsRefs,
          })
        > {
  $$MemberProfilesTableTableManager(
    _$AppDatabase db,
    $MemberProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberProfilesCompanion(
                id: id,
                householdId: householdId,
                displayName: displayName,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String displayName,
                Value<String> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberProfilesCompanion.insert(
                id: id,
                householdId: householdId,
                displayName: displayName,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemberProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                householdId = false,
                inventoryContainersRefs = false,
                inventoryItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (inventoryContainersRefs) db.inventoryContainers,
                    if (inventoryItemsRefs) db.inventoryItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable:
                                        $$MemberProfilesTableReferences
                                            ._householdIdTable(db),
                                    referencedColumn:
                                        $$MemberProfilesTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (inventoryContainersRefs)
                        await $_getPrefetchedData<
                          MemberProfile,
                          $MemberProfilesTable,
                          InventoryContainer
                        >(
                          currentTable: table,
                          referencedTable: $$MemberProfilesTableReferences
                              ._inventoryContainersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemberProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryContainersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerMemberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryItemsRefs)
                        await $_getPrefetchedData<
                          MemberProfile,
                          $MemberProfilesTable,
                          InventoryItem
                        >(
                          currentTable: table,
                          referencedTable: $$MemberProfilesTableReferences
                              ._inventoryItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemberProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assignedMemberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MemberProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemberProfilesTable,
      MemberProfile,
      $$MemberProfilesTableFilterComposer,
      $$MemberProfilesTableOrderingComposer,
      $$MemberProfilesTableAnnotationComposer,
      $$MemberProfilesTableCreateCompanionBuilder,
      $$MemberProfilesTableUpdateCompanionBuilder,
      (MemberProfile, $$MemberProfilesTableReferences),
      MemberProfile,
      PrefetchHooks Function({
        bool householdId,
        bool inventoryContainersRefs,
        bool inventoryItemsRefs,
      })
    >;
typedef $$InventoryContainersTableCreateCompanionBuilder =
    InventoryContainersCompanion Function({
      required String id,
      required String householdId,
      Value<String?> ownerMemberId,
      required String name,
      required String kind,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InventoryContainersTableUpdateCompanionBuilder =
    InventoryContainersCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String?> ownerMemberId,
      Value<String> name,
      Value<String> kind,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InventoryContainersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InventoryContainersTable,
          InventoryContainer
        > {
  $$InventoryContainersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) => db.households
      .createAlias('inventory_containers__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MemberProfilesTable _ownerMemberIdTable(_$AppDatabase db) =>
      db.memberProfiles.createAlias(
        'inventory_containers__owner_member_id__member_profiles__id',
      );

  $$MemberProfilesTableProcessedTableManager? get ownerMemberId {
    final $_column = $_itemColumn<String>('owner_member_id');
    if ($_column == null) return null;
    final manager = $$MemberProfilesTableTableManager(
      $_db,
      $_db.memberProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InventoryItemsTable, List<InventoryItem>>
  _inventoryItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryItems,
    aliasName: 'inventory_containers__id__inventory_items__container_id',
  );

  $$InventoryItemsTableProcessedTableManager get inventoryItemsRefs {
    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.containerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventoryContainersTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryContainersTable> {
  $$InventoryContainersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberProfilesTableFilterComposer get ownerMemberId {
    final $$MemberProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerMemberId,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableFilterComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> inventoryItemsRefs(
    Expression<bool> Function($$InventoryItemsTableFilterComposer f) f,
  ) {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryContainersTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryContainersTable> {
  $$InventoryContainersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberProfilesTableOrderingComposer get ownerMemberId {
    final $$MemberProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerMemberId,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryContainersTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryContainersTable> {
  $$InventoryContainersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberProfilesTableAnnotationComposer get ownerMemberId {
    final $$MemberProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerMemberId,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> inventoryItemsRefs<T extends Object>(
    Expression<T> Function($$InventoryItemsTableAnnotationComposer a) f,
  ) {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryContainersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryContainersTable,
          InventoryContainer,
          $$InventoryContainersTableFilterComposer,
          $$InventoryContainersTableOrderingComposer,
          $$InventoryContainersTableAnnotationComposer,
          $$InventoryContainersTableCreateCompanionBuilder,
          $$InventoryContainersTableUpdateCompanionBuilder,
          (InventoryContainer, $$InventoryContainersTableReferences),
          InventoryContainer,
          PrefetchHooks Function({
            bool householdId,
            bool ownerMemberId,
            bool inventoryItemsRefs,
          })
        > {
  $$InventoryContainersTableTableManager(
    _$AppDatabase db,
    $InventoryContainersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryContainersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryContainersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryContainersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String?> ownerMemberId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryContainersCompanion(
                id: id,
                householdId: householdId,
                ownerMemberId: ownerMemberId,
                name: name,
                kind: kind,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                Value<String?> ownerMemberId = const Value.absent(),
                required String name,
                required String kind,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryContainersCompanion.insert(
                id: id,
                householdId: householdId,
                ownerMemberId: ownerMemberId,
                name: name,
                kind: kind,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryContainersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                householdId = false,
                ownerMemberId = false,
                inventoryItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (inventoryItemsRefs) db.inventoryItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable:
                                        $$InventoryContainersTableReferences
                                            ._householdIdTable(db),
                                    referencedColumn:
                                        $$InventoryContainersTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (ownerMemberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerMemberId,
                                    referencedTable:
                                        $$InventoryContainersTableReferences
                                            ._ownerMemberIdTable(db),
                                    referencedColumn:
                                        $$InventoryContainersTableReferences
                                            ._ownerMemberIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (inventoryItemsRefs)
                        await $_getPrefetchedData<
                          InventoryContainer,
                          $InventoryContainersTable,
                          InventoryItem
                        >(
                          currentTable: table,
                          referencedTable: $$InventoryContainersTableReferences
                              ._inventoryItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoryContainersTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.containerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InventoryContainersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryContainersTable,
      InventoryContainer,
      $$InventoryContainersTableFilterComposer,
      $$InventoryContainersTableOrderingComposer,
      $$InventoryContainersTableAnnotationComposer,
      $$InventoryContainersTableCreateCompanionBuilder,
      $$InventoryContainersTableUpdateCompanionBuilder,
      (InventoryContainer, $$InventoryContainersTableReferences),
      InventoryContainer,
      PrefetchHooks Function({
        bool householdId,
        bool ownerMemberId,
        bool inventoryItemsRefs,
      })
    >;
typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      required String id,
      required String containerId,
      Value<String?> itemSeq,
      required String productName,
      Value<String?> manufacturer,
      Value<String?> ingredientSummary,
      Value<String?> identificationVariantKey,
      Value<String?> officialImageUrl,
      Value<Uint8List?> capturedImageBytes,
      Value<String?> appearanceSummary,
      Value<String> itemKind,
      Value<String?> officialCategory,
      Value<String> cabinetSection,
      Value<int> quantity,
      Value<String> unit,
      Value<DateTime?> expiresOn,
      Value<String?> storageNote,
      Value<String?> privateNote,
      Value<String?> assignedMemberId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<String> id,
      Value<String> containerId,
      Value<String?> itemSeq,
      Value<String> productName,
      Value<String?> manufacturer,
      Value<String?> ingredientSummary,
      Value<String?> identificationVariantKey,
      Value<String?> officialImageUrl,
      Value<Uint8List?> capturedImageBytes,
      Value<String?> appearanceSummary,
      Value<String> itemKind,
      Value<String?> officialCategory,
      Value<String> cabinetSection,
      Value<int> quantity,
      Value<String> unit,
      Value<DateTime?> expiresOn,
      Value<String?> storageNote,
      Value<String?> privateNote,
      Value<String?> assignedMemberId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InventoryItemsTableReferences
    extends BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem> {
  $$InventoryItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoryContainersTable _containerIdTable(_$AppDatabase db) => db
      .inventoryContainers
      .createAlias('inventory_items__container_id__inventory_containers__id');

  $$InventoryContainersTableProcessedTableManager get containerId {
    final $_column = $_itemColumn<String>('container_id')!;

    final manager = $$InventoryContainersTableTableManager(
      $_db,
      $_db.inventoryContainers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_containerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MemberProfilesTable _assignedMemberIdTable(_$AppDatabase db) => db
      .memberProfiles
      .createAlias('inventory_items__assigned_member_id__member_profiles__id');

  $$MemberProfilesTableProcessedTableManager? get assignedMemberId {
    final $_column = $_itemColumn<String>('assigned_member_id');
    if ($_column == null) return null;
    final manager = $$MemberProfilesTableTableManager(
      $_db,
      $_db.memberProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assignedMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RenewalReadinessTable, List<RenewalReadinessData>>
  _renewalReadinessRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.renewalReadiness,
    aliasName: 'inventory_items__id__renewal_readiness__inventory_item_id',
  );

  $$RenewalReadinessTableProcessedTableManager get renewalReadinessRefs {
    final manager =
        $$RenewalReadinessTableTableManager($_db, $_db.renewalReadiness).filter(
          (f) => f.inventoryItemId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _renewalReadinessRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'inventory_items__id__reminders__inventory_item_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager($_db, $_db.reminders).filter(
      (f) => f.inventoryItemId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
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

  ColumnFilters<String> get itemSeq => $composableBuilder(
    column: $table.itemSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientSummary => $composableBuilder(
    column: $table.ingredientSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identificationVariantKey => $composableBuilder(
    column: $table.identificationVariantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get officialImageUrl => $composableBuilder(
    column: $table.officialImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get capturedImageBytes => $composableBuilder(
    column: $table.capturedImageBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearanceSummary => $composableBuilder(
    column: $table.appearanceSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemKind => $composableBuilder(
    column: $table.itemKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get officialCategory => $composableBuilder(
    column: $table.officialCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cabinetSection => $composableBuilder(
    column: $table.cabinetSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresOn => $composableBuilder(
    column: $table.expiresOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageNote => $composableBuilder(
    column: $table.storageNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateNote => $composableBuilder(
    column: $table.privateNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoryContainersTableFilterComposer get containerId {
    final $$InventoryContainersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: $db.inventoryContainers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryContainersTableFilterComposer(
            $db: $db,
            $table: $db.inventoryContainers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberProfilesTableFilterComposer get assignedMemberId {
    final $$MemberProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedMemberId,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableFilterComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> renewalReadinessRefs(
    Expression<bool> Function($$RenewalReadinessTableFilterComposer f) f,
  ) {
    final $$RenewalReadinessTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.renewalReadiness,
      getReferencedColumn: (t) => t.inventoryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenewalReadinessTableFilterComposer(
            $db: $db,
            $table: $db.renewalReadiness,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.inventoryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get itemSeq => $composableBuilder(
    column: $table.itemSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientSummary => $composableBuilder(
    column: $table.ingredientSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identificationVariantKey => $composableBuilder(
    column: $table.identificationVariantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get officialImageUrl => $composableBuilder(
    column: $table.officialImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get capturedImageBytes => $composableBuilder(
    column: $table.capturedImageBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearanceSummary => $composableBuilder(
    column: $table.appearanceSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemKind => $composableBuilder(
    column: $table.itemKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get officialCategory => $composableBuilder(
    column: $table.officialCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cabinetSection => $composableBuilder(
    column: $table.cabinetSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresOn => $composableBuilder(
    column: $table.expiresOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageNote => $composableBuilder(
    column: $table.storageNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateNote => $composableBuilder(
    column: $table.privateNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoryContainersTableOrderingComposer get containerId {
    final $$InventoryContainersTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.containerId,
          referencedTable: $db.inventoryContainers,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryContainersTableOrderingComposer(
                $db: $db,
                $table: $db.inventoryContainers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$MemberProfilesTableOrderingComposer get assignedMemberId {
    final $$MemberProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedMemberId,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemSeq =>
      $composableBuilder(column: $table.itemSeq, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ingredientSummary => $composableBuilder(
    column: $table.ingredientSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identificationVariantKey => $composableBuilder(
    column: $table.identificationVariantKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get officialImageUrl => $composableBuilder(
    column: $table.officialImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get capturedImageBytes => $composableBuilder(
    column: $table.capturedImageBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appearanceSummary => $composableBuilder(
    column: $table.appearanceSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemKind =>
      $composableBuilder(column: $table.itemKind, builder: (column) => column);

  GeneratedColumn<String> get officialCategory => $composableBuilder(
    column: $table.officialCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cabinetSection => $composableBuilder(
    column: $table.cabinetSection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresOn =>
      $composableBuilder(column: $table.expiresOn, builder: (column) => column);

  GeneratedColumn<String> get storageNote => $composableBuilder(
    column: $table.storageNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privateNote => $composableBuilder(
    column: $table.privateNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InventoryContainersTableAnnotationComposer get containerId {
    final $$InventoryContainersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.containerId,
          referencedTable: $db.inventoryContainers,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryContainersTableAnnotationComposer(
                $db: $db,
                $table: $db.inventoryContainers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$MemberProfilesTableAnnotationComposer get assignedMemberId {
    final $$MemberProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedMemberId,
      referencedTable: $db.memberProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.memberProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> renewalReadinessRefs<T extends Object>(
    Expression<T> Function($$RenewalReadinessTableAnnotationComposer a) f,
  ) {
    final $$RenewalReadinessTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.renewalReadiness,
      getReferencedColumn: (t) => t.inventoryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenewalReadinessTableAnnotationComposer(
            $db: $db,
            $table: $db.renewalReadiness,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.inventoryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTable,
          InventoryItem,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (InventoryItem, $$InventoryItemsTableReferences),
          InventoryItem,
          PrefetchHooks Function({
            bool containerId,
            bool assignedMemberId,
            bool renewalReadinessRefs,
            bool remindersRefs,
          })
        > {
  $$InventoryItemsTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> containerId = const Value.absent(),
                Value<String?> itemSeq = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> ingredientSummary = const Value.absent(),
                Value<String?> identificationVariantKey = const Value.absent(),
                Value<String?> officialImageUrl = const Value.absent(),
                Value<Uint8List?> capturedImageBytes = const Value.absent(),
                Value<String?> appearanceSummary = const Value.absent(),
                Value<String> itemKind = const Value.absent(),
                Value<String?> officialCategory = const Value.absent(),
                Value<String> cabinetSection = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime?> expiresOn = const Value.absent(),
                Value<String?> storageNote = const Value.absent(),
                Value<String?> privateNote = const Value.absent(),
                Value<String?> assignedMemberId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                containerId: containerId,
                itemSeq: itemSeq,
                productName: productName,
                manufacturer: manufacturer,
                ingredientSummary: ingredientSummary,
                identificationVariantKey: identificationVariantKey,
                officialImageUrl: officialImageUrl,
                capturedImageBytes: capturedImageBytes,
                appearanceSummary: appearanceSummary,
                itemKind: itemKind,
                officialCategory: officialCategory,
                cabinetSection: cabinetSection,
                quantity: quantity,
                unit: unit,
                expiresOn: expiresOn,
                storageNote: storageNote,
                privateNote: privateNote,
                assignedMemberId: assignedMemberId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String containerId,
                Value<String?> itemSeq = const Value.absent(),
                required String productName,
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> ingredientSummary = const Value.absent(),
                Value<String?> identificationVariantKey = const Value.absent(),
                Value<String?> officialImageUrl = const Value.absent(),
                Value<Uint8List?> capturedImageBytes = const Value.absent(),
                Value<String?> appearanceSummary = const Value.absent(),
                Value<String> itemKind = const Value.absent(),
                Value<String?> officialCategory = const Value.absent(),
                Value<String> cabinetSection = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime?> expiresOn = const Value.absent(),
                Value<String?> storageNote = const Value.absent(),
                Value<String?> privateNote = const Value.absent(),
                Value<String?> assignedMemberId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                containerId: containerId,
                itemSeq: itemSeq,
                productName: productName,
                manufacturer: manufacturer,
                ingredientSummary: ingredientSummary,
                identificationVariantKey: identificationVariantKey,
                officialImageUrl: officialImageUrl,
                capturedImageBytes: capturedImageBytes,
                appearanceSummary: appearanceSummary,
                itemKind: itemKind,
                officialCategory: officialCategory,
                cabinetSection: cabinetSection,
                quantity: quantity,
                unit: unit,
                expiresOn: expiresOn,
                storageNote: storageNote,
                privateNote: privateNote,
                assignedMemberId: assignedMemberId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                containerId = false,
                assignedMemberId = false,
                renewalReadinessRefs = false,
                remindersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (renewalReadinessRefs) db.renewalReadiness,
                    if (remindersRefs) db.reminders,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (containerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.containerId,
                                    referencedTable:
                                        $$InventoryItemsTableReferences
                                            ._containerIdTable(db),
                                    referencedColumn:
                                        $$InventoryItemsTableReferences
                                            ._containerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (assignedMemberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assignedMemberId,
                                    referencedTable:
                                        $$InventoryItemsTableReferences
                                            ._assignedMemberIdTable(db),
                                    referencedColumn:
                                        $$InventoryItemsTableReferences
                                            ._assignedMemberIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (renewalReadinessRefs)
                        await $_getPrefetchedData<
                          InventoryItem,
                          $InventoryItemsTable,
                          RenewalReadinessData
                        >(
                          currentTable: table,
                          referencedTable: $$InventoryItemsTableReferences
                              ._renewalReadinessRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).renewalReadinessRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.inventoryItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<
                          InventoryItem,
                          $InventoryItemsTable,
                          Reminder
                        >(
                          currentTable: table,
                          referencedTable: $$InventoryItemsTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.inventoryItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTable,
      InventoryItem,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (InventoryItem, $$InventoryItemsTableReferences),
      InventoryItem,
      PrefetchHooks Function({
        bool containerId,
        bool assignedMemberId,
        bool renewalReadinessRefs,
        bool remindersRefs,
      })
    >;
typedef $$RenewalReadinessTableCreateCompanionBuilder =
    RenewalReadinessCompanion Function({
      required String id,
      required String inventoryItemId,
      Value<DateTime?> nextVisitOn,
      Value<bool> prescriptionPhotoChecked,
      Value<bool> remainingQuantityChecked,
      Value<bool> questionsPrepared,
      Value<String?> visitNote,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RenewalReadinessTableUpdateCompanionBuilder =
    RenewalReadinessCompanion Function({
      Value<String> id,
      Value<String> inventoryItemId,
      Value<DateTime?> nextVisitOn,
      Value<bool> prescriptionPhotoChecked,
      Value<bool> remainingQuantityChecked,
      Value<bool> questionsPrepared,
      Value<String?> visitNote,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RenewalReadinessTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RenewalReadinessTable,
          RenewalReadinessData
        > {
  $$RenewalReadinessTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoryItemsTable _inventoryItemIdTable(_$AppDatabase db) => db
      .inventoryItems
      .createAlias('renewal_readiness__inventory_item_id__inventory_items__id');

  $$InventoryItemsTableProcessedTableManager get inventoryItemId {
    final $_column = $_itemColumn<String>('inventory_item_id')!;

    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RenewalReadinessTableFilterComposer
    extends Composer<_$AppDatabase, $RenewalReadinessTable> {
  $$RenewalReadinessTableFilterComposer({
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

  ColumnFilters<DateTime> get nextVisitOn => $composableBuilder(
    column: $table.nextVisitOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get prescriptionPhotoChecked => $composableBuilder(
    column: $table.prescriptionPhotoChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remainingQuantityChecked => $composableBuilder(
    column: $table.remainingQuantityChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get questionsPrepared => $composableBuilder(
    column: $table.questionsPrepared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitNote => $composableBuilder(
    column: $table.visitNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoryItemsTableFilterComposer get inventoryItemId {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenewalReadinessTableOrderingComposer
    extends Composer<_$AppDatabase, $RenewalReadinessTable> {
  $$RenewalReadinessTableOrderingComposer({
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

  ColumnOrderings<DateTime> get nextVisitOn => $composableBuilder(
    column: $table.nextVisitOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get prescriptionPhotoChecked => $composableBuilder(
    column: $table.prescriptionPhotoChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remainingQuantityChecked => $composableBuilder(
    column: $table.remainingQuantityChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get questionsPrepared => $composableBuilder(
    column: $table.questionsPrepared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitNote => $composableBuilder(
    column: $table.visitNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoryItemsTableOrderingComposer get inventoryItemId {
    final $$InventoryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenewalReadinessTableAnnotationComposer
    extends Composer<_$AppDatabase, $RenewalReadinessTable> {
  $$RenewalReadinessTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get nextVisitOn => $composableBuilder(
    column: $table.nextVisitOn,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get prescriptionPhotoChecked => $composableBuilder(
    column: $table.prescriptionPhotoChecked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remainingQuantityChecked => $composableBuilder(
    column: $table.remainingQuantityChecked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get questionsPrepared => $composableBuilder(
    column: $table.questionsPrepared,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visitNote =>
      $composableBuilder(column: $table.visitNote, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InventoryItemsTableAnnotationComposer get inventoryItemId {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenewalReadinessTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RenewalReadinessTable,
          RenewalReadinessData,
          $$RenewalReadinessTableFilterComposer,
          $$RenewalReadinessTableOrderingComposer,
          $$RenewalReadinessTableAnnotationComposer,
          $$RenewalReadinessTableCreateCompanionBuilder,
          $$RenewalReadinessTableUpdateCompanionBuilder,
          (RenewalReadinessData, $$RenewalReadinessTableReferences),
          RenewalReadinessData,
          PrefetchHooks Function({bool inventoryItemId})
        > {
  $$RenewalReadinessTableTableManager(
    _$AppDatabase db,
    $RenewalReadinessTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RenewalReadinessTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RenewalReadinessTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RenewalReadinessTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryItemId = const Value.absent(),
                Value<DateTime?> nextVisitOn = const Value.absent(),
                Value<bool> prescriptionPhotoChecked = const Value.absent(),
                Value<bool> remainingQuantityChecked = const Value.absent(),
                Value<bool> questionsPrepared = const Value.absent(),
                Value<String?> visitNote = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RenewalReadinessCompanion(
                id: id,
                inventoryItemId: inventoryItemId,
                nextVisitOn: nextVisitOn,
                prescriptionPhotoChecked: prescriptionPhotoChecked,
                remainingQuantityChecked: remainingQuantityChecked,
                questionsPrepared: questionsPrepared,
                visitNote: visitNote,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryItemId,
                Value<DateTime?> nextVisitOn = const Value.absent(),
                Value<bool> prescriptionPhotoChecked = const Value.absent(),
                Value<bool> remainingQuantityChecked = const Value.absent(),
                Value<bool> questionsPrepared = const Value.absent(),
                Value<String?> visitNote = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RenewalReadinessCompanion.insert(
                id: id,
                inventoryItemId: inventoryItemId,
                nextVisitOn: nextVisitOn,
                prescriptionPhotoChecked: prescriptionPhotoChecked,
                remainingQuantityChecked: remainingQuantityChecked,
                questionsPrepared: questionsPrepared,
                visitNote: visitNote,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RenewalReadinessTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryItemId,
                                referencedTable:
                                    $$RenewalReadinessTableReferences
                                        ._inventoryItemIdTable(db),
                                referencedColumn:
                                    $$RenewalReadinessTableReferences
                                        ._inventoryItemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RenewalReadinessTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RenewalReadinessTable,
      RenewalReadinessData,
      $$RenewalReadinessTableFilterComposer,
      $$RenewalReadinessTableOrderingComposer,
      $$RenewalReadinessTableAnnotationComposer,
      $$RenewalReadinessTableCreateCompanionBuilder,
      $$RenewalReadinessTableUpdateCompanionBuilder,
      (RenewalReadinessData, $$RenewalReadinessTableReferences),
      RenewalReadinessData,
      PrefetchHooks Function({bool inventoryItemId})
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      Value<String?> inventoryItemId,
      required String kind,
      required DateTime scheduledAt,
      Value<bool> enabled,
      Value<bool> hidesMedicineName,
      Value<String?> privateLabel,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String?> inventoryItemId,
      Value<String> kind,
      Value<DateTime> scheduledAt,
      Value<bool> enabled,
      Value<bool> hidesMedicineName,
      Value<String?> privateLabel,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InventoryItemsTable _inventoryItemIdTable(_$AppDatabase db) => db
      .inventoryItems
      .createAlias('reminders__inventory_item_id__inventory_items__id');

  $$InventoryItemsTableProcessedTableManager? get inventoryItemId {
    final $_column = $_itemColumn<String>('inventory_item_id');
    if ($_column == null) return null;
    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidesMedicineName => $composableBuilder(
    column: $table.hidesMedicineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateLabel => $composableBuilder(
    column: $table.privateLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoryItemsTableFilterComposer get inventoryItemId {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidesMedicineName => $composableBuilder(
    column: $table.hidesMedicineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateLabel => $composableBuilder(
    column: $table.privateLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoryItemsTableOrderingComposer get inventoryItemId {
    final $$InventoryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get hidesMedicineName => $composableBuilder(
    column: $table.hidesMedicineName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privateLabel => $composableBuilder(
    column: $table.privateLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InventoryItemsTableAnnotationComposer get inventoryItemId {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool inventoryItemId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> inventoryItemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> hidesMedicineName = const Value.absent(),
                Value<String?> privateLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                inventoryItemId: inventoryItemId,
                kind: kind,
                scheduledAt: scheduledAt,
                enabled: enabled,
                hidesMedicineName: hidesMedicineName,
                privateLabel: privateLabel,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> inventoryItemId = const Value.absent(),
                required String kind,
                required DateTime scheduledAt,
                Value<bool> enabled = const Value.absent(),
                Value<bool> hidesMedicineName = const Value.absent(),
                Value<String?> privateLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                inventoryItemId: inventoryItemId,
                kind: kind,
                scheduledAt: scheduledAt,
                enabled: enabled,
                hidesMedicineName: hidesMedicineName,
                privateLabel: privateLabel,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryItemId,
                                referencedTable: $$RemindersTableReferences
                                    ._inventoryItemIdTable(db),
                                referencedColumn: $$RemindersTableReferences
                                    ._inventoryItemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool inventoryItemId})
    >;
typedef $$CatalogCacheEntriesTableCreateCompanionBuilder =
    CatalogCacheEntriesCompanion Function({
      required String accountId,
      required String cacheNamespace,
      required String cacheKey,
      required int formatVersion,
      required String payloadJson,
      required int byteSize,
      required DateTime cachedAt,
      required DateTime expiresAt,
      required DateTime lastAccessedAt,
      Value<int> rowid,
    });
typedef $$CatalogCacheEntriesTableUpdateCompanionBuilder =
    CatalogCacheEntriesCompanion Function({
      Value<String> accountId,
      Value<String> cacheNamespace,
      Value<String> cacheKey,
      Value<int> formatVersion,
      Value<String> payloadJson,
      Value<int> byteSize,
      Value<DateTime> cachedAt,
      Value<DateTime> expiresAt,
      Value<DateTime> lastAccessedAt,
      Value<int> rowid,
    });

class $$CatalogCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogCacheEntriesTable> {
  $$CatalogCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheNamespace => $composableBuilder(
    column: $table.cacheNamespace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogCacheEntriesTable> {
  $$CatalogCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheNamespace => $composableBuilder(
    column: $table.cacheNamespace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogCacheEntriesTable> {
  $$CatalogCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get cacheNamespace => $composableBuilder(
    column: $table.cacheNamespace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$CatalogCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogCacheEntriesTable,
          CatalogCacheEntry,
          $$CatalogCacheEntriesTableFilterComposer,
          $$CatalogCacheEntriesTableOrderingComposer,
          $$CatalogCacheEntriesTableAnnotationComposer,
          $$CatalogCacheEntriesTableCreateCompanionBuilder,
          $$CatalogCacheEntriesTableUpdateCompanionBuilder,
          (
            CatalogCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $CatalogCacheEntriesTable,
              CatalogCacheEntry
            >,
          ),
          CatalogCacheEntry,
          PrefetchHooks Function()
        > {
  $$CatalogCacheEntriesTableTableManager(
    _$AppDatabase db,
    $CatalogCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CatalogCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> cacheNamespace = const Value.absent(),
                Value<String> cacheKey = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogCacheEntriesCompanion(
                accountId: accountId,
                cacheNamespace: cacheNamespace,
                cacheKey: cacheKey,
                formatVersion: formatVersion,
                payloadJson: payloadJson,
                byteSize: byteSize,
                cachedAt: cachedAt,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String cacheNamespace,
                required String cacheKey,
                required int formatVersion,
                required String payloadJson,
                required int byteSize,
                required DateTime cachedAt,
                required DateTime expiresAt,
                required DateTime lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => CatalogCacheEntriesCompanion.insert(
                accountId: accountId,
                cacheNamespace: cacheNamespace,
                cacheKey: cacheKey,
                formatVersion: formatVersion,
                payloadJson: payloadJson,
                byteSize: byteSize,
                cachedAt: cachedAt,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogCacheEntriesTable,
      CatalogCacheEntry,
      $$CatalogCacheEntriesTableFilterComposer,
      $$CatalogCacheEntriesTableOrderingComposer,
      $$CatalogCacheEntriesTableAnnotationComposer,
      $$CatalogCacheEntriesTableCreateCompanionBuilder,
      $$CatalogCacheEntriesTableUpdateCompanionBuilder,
      (
        CatalogCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $CatalogCacheEntriesTable,
          CatalogCacheEntry
        >,
      ),
      CatalogCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$OfficialImageCacheEntriesTableCreateCompanionBuilder =
    OfficialImageCacheEntriesCompanion Function({
      required String accountId,
      required String imageUrl,
      required Uint8List imageBytes,
      Value<String?> contentType,
      required int byteSize,
      required DateTime cachedAt,
      required DateTime expiresAt,
      required DateTime lastAccessedAt,
      Value<int> rowid,
    });
typedef $$OfficialImageCacheEntriesTableUpdateCompanionBuilder =
    OfficialImageCacheEntriesCompanion Function({
      Value<String> accountId,
      Value<String> imageUrl,
      Value<Uint8List> imageBytes,
      Value<String?> contentType,
      Value<int> byteSize,
      Value<DateTime> cachedAt,
      Value<DateTime> expiresAt,
      Value<DateTime> lastAccessedAt,
      Value<int> rowid,
    });

class $$OfficialImageCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OfficialImageCacheEntriesTable> {
  $$OfficialImageCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get imageBytes => $composableBuilder(
    column: $table.imageBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfficialImageCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfficialImageCacheEntriesTable> {
  $$OfficialImageCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get imageBytes => $composableBuilder(
    column: $table.imageBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfficialImageCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfficialImageCacheEntriesTable> {
  $$OfficialImageCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<Uint8List> get imageBytes => $composableBuilder(
    column: $table.imageBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$OfficialImageCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfficialImageCacheEntriesTable,
          OfficialImageCacheEntry,
          $$OfficialImageCacheEntriesTableFilterComposer,
          $$OfficialImageCacheEntriesTableOrderingComposer,
          $$OfficialImageCacheEntriesTableAnnotationComposer,
          $$OfficialImageCacheEntriesTableCreateCompanionBuilder,
          $$OfficialImageCacheEntriesTableUpdateCompanionBuilder,
          (
            OfficialImageCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $OfficialImageCacheEntriesTable,
              OfficialImageCacheEntry
            >,
          ),
          OfficialImageCacheEntry,
          PrefetchHooks Function()
        > {
  $$OfficialImageCacheEntriesTableTableManager(
    _$AppDatabase db,
    $OfficialImageCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfficialImageCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OfficialImageCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfficialImageCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<Uint8List> imageBytes = const Value.absent(),
                Value<String?> contentType = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfficialImageCacheEntriesCompanion(
                accountId: accountId,
                imageUrl: imageUrl,
                imageBytes: imageBytes,
                contentType: contentType,
                byteSize: byteSize,
                cachedAt: cachedAt,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String imageUrl,
                required Uint8List imageBytes,
                Value<String?> contentType = const Value.absent(),
                required int byteSize,
                required DateTime cachedAt,
                required DateTime expiresAt,
                required DateTime lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfficialImageCacheEntriesCompanion.insert(
                accountId: accountId,
                imageUrl: imageUrl,
                imageBytes: imageBytes,
                contentType: contentType,
                byteSize: byteSize,
                cachedAt: cachedAt,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfficialImageCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfficialImageCacheEntriesTable,
      OfficialImageCacheEntry,
      $$OfficialImageCacheEntriesTableFilterComposer,
      $$OfficialImageCacheEntriesTableOrderingComposer,
      $$OfficialImageCacheEntriesTableAnnotationComposer,
      $$OfficialImageCacheEntriesTableCreateCompanionBuilder,
      $$OfficialImageCacheEntriesTableUpdateCompanionBuilder,
      (
        OfficialImageCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $OfficialImageCacheEntriesTable,
          OfficialImageCacheEntry
        >,
      ),
      OfficialImageCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> onboardingCompleted,
      Value<bool> notificationPrivacy,
      Value<String> localeCode,
      Value<String> environment,
      Value<DateTime> updatedAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> onboardingCompleted,
      Value<bool> notificationPrivacy,
      Value<String> localeCode,
      Value<String> environment,
      Value<DateTime> updatedAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationPrivacy => $composableBuilder(
    column: $table.notificationPrivacy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationPrivacy => $composableBuilder(
    column: $table.notificationPrivacy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationPrivacy => $composableBuilder(
    column: $table.notificationPrivacy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> notificationPrivacy = const Value.absent(),
                Value<String> localeCode = const Value.absent(),
                Value<String> environment = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                onboardingCompleted: onboardingCompleted,
                notificationPrivacy: notificationPrivacy,
                localeCode: localeCode,
                environment: environment,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> notificationPrivacy = const Value.absent(),
                Value<String> localeCode = const Value.absent(),
                Value<String> environment = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                onboardingCompleted: onboardingCompleted,
                notificationPrivacy: notificationPrivacy,
                localeCode: localeCode,
                environment: environment,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$MemberProfilesTableTableManager get memberProfiles =>
      $$MemberProfilesTableTableManager(_db, _db.memberProfiles);
  $$InventoryContainersTableTableManager get inventoryContainers =>
      $$InventoryContainersTableTableManager(_db, _db.inventoryContainers);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$RenewalReadinessTableTableManager get renewalReadiness =>
      $$RenewalReadinessTableTableManager(_db, _db.renewalReadiness);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$CatalogCacheEntriesTableTableManager get catalogCacheEntries =>
      $$CatalogCacheEntriesTableTableManager(_db, _db.catalogCacheEntries);
  $$OfficialImageCacheEntriesTableTableManager get officialImageCacheEntries =>
      $$OfficialImageCacheEntriesTableTableManager(
        _db,
        _db.officialImageCacheEntries,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
