import 'dart:io';
import 'data class parser.dart';
import 'package:recase/recase.dart';

/// Runs the 'generate' command logic.
void runGenerateHive(List<String> rest) {
  if (rest.isEmpty) {
    print('Usage: feature_cli generate hive <path/to/model.dart>');
    exit(0);
  }
  final sub = rest[0];
  if (sub == 'hive') {
    if (rest.length < 2) {
      print('Usage: feature_cli generate hive <path/to/model.dart>');
      exit(0);
    }
    final filePath = rest[1];
    _generateHiveAdapterForFile(filePath);
    return;
  } else {
    print('Only "hive" generation is supported currently under generate.');
    exit(0);
  }
}

/// ---------- Generate hive companion + adapter for a given file ----------
void _generateHiveAdapterForFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $filePath');
    exit(2);
  }
  final source = file.readAsStringSync();
  final classDef = parseFirstClass(source);
  if (classDef == null) {
    stderr.writeln('No class definition found in $filePath');
    exit(3);
  }

  final dir = file.parent.path;
  final basename = file.uri.pathSegments.last.split('.').first;
  final hiveFilename = '${basename}_db.dart';
  final adapterFilename = '$basename.g.dart';
  final helperFilename = '${basename}_db_helper.dart';

  // Create hive class file
  final hiveClassCode = buildHiveClassFile(classDef, basename);
  File('$dir/$hiveFilename').writeAsStringSync(hiveClassCode);
  stdout.writeln('✅ Created Hive class file: $dir/$hiveFilename');

  // Create adapter file
  final adapterCode = buildAdapterCode(classDef, '${basename}_db');
  File('$dir/$adapterFilename').writeAsStringSync(adapterCode);
  stdout.writeln('✅ Created Hive adapter file: $dir/$adapterFilename');

  // Create DB helper file
  final helperCode = buildDbHelperFile(classDef.name);
  File('$dir/$helperFilename').writeAsStringSync(helperCode);
  stdout.writeln('✅ Created Hive DB helper file: $dir/$helperFilename');

  stdout.writeln('');
  stdout.writeln('🎉 Generated Hive files for class ${classDef.name}.');
  stdout.writeln(
      '⚠️ Note: adapter typeId is 0 by default — update to a unique id before using.');
  stdout.writeln(
      '⚠️ You now have a full DbHelper for ${classDef.name} for CRUD + query helpers.');
}

/// ---------- Hive code generation helpers ----------
String dartTypeToHiveWriteExpression(String type, String objAccessor) {
  // type = raw type like String, CodesKinds, Color, TimeOfDay, Gradient, CustomModel
  switch (type) {
    case 'String':
    case 'int':
    case 'double':
    case 'bool':
    case 'DateTime':
    case 'List':
    case 'Map':
      return '$objAccessor';
    default:
      // heuristics for known Flutter types
      if (type.endsWith('Color')) {
        return '$objAccessor?.value';
      }
      if (type == 'TimeOfDay') {
        // store as Map so it's easy to restore
        return "$objAccessor != null ? {'hour': ${objAccessor}!.hour, 'minute': ${objAccessor}!.minute} : null";
      }
      if (type.endsWith('Gradient') ||
          type == 'Gradient' ||
          type.contains('Gradient')) {
        return "$objAccessor != null ? {'colors': (${objAccessor} as LinearGradient).colors.map((c) => c.value).toList()} : null";
      }
      // enum detection: we'll assume enums are declared as simple types (user must adjust if not)
      // fallback: call toMap() if exists, else jsonEncode
      return "(${objAccessor} != null) ? ( ${objAccessor} is Map ? ${objAccessor} : ( ${objAccessor}.toMap != null ? ${objAccessor}.toMap() : jsonDecode(jsonEncode(${objAccessor})) ) ) : null";
  }
}

String dartTypeToHiveReadConstruction(String type, String fieldVar) {
  switch (type) {
    case 'String':
      return '$fieldVar as String?';
    case 'int':
      return '$fieldVar as int?';
    case 'double':
      return '$fieldVar as double?';
    case 'bool':
      return '$fieldVar as bool?';
    case 'DateTime':
      return '$fieldVar as DateTime?';
    case 'List':
      return '$fieldVar as List?';
    case 'Map':
      return '$fieldVar as Map?';
    default:
      if (type.endsWith('Color')) {
        return '$fieldVar != null ? Color(fieldVar as int) : null';
      }
      if (type == 'TimeOfDay') {
        return """{
        final m = $fieldVar as Map?;
        if (m == null) return null;
        return TimeOfDay(hour: (m['hour'] as int), minute: (m['minute'] as int));
      }()""";
      }
      if (type.endsWith('Gradient') ||
          type == 'Gradient' ||
          type.contains('Gradient')) {
        return """{
        final m = $fieldVar as Map?;
        if (m == null) return null;
        final colors = (m['colors'] as List).map((c) => Color(c as int)).toList();
        return LinearGradient(colors: colors, begin: Alignment.centerLeft, end: Alignment.centerRight);
      }()""";
      }
      // enum heuristic: try to parse int index
      // fallback: try CustomModel.fromMap(fieldVar as Map)
      return """{
        final v = $fieldVar;
        if (v == null) return null;
        if (v is int) {
          // enum by index - map later by EnumName.values[v]
          return v;
        }
        if (v is Map) {
          try {
            return ${type}.fromMap(v as Map<String, dynamic>);
          } catch (_) {
            return jsonDecode(jsonEncode(v));
          }
        }
        return v;
      }()""";
  }
}

/// Build a simple Hive adapter (g.dart) content for a class
String buildAdapterCode(ClassDef c, String origBasename) {
  final className = c.name;
  final adapterName = '${className}Adapter';
  final typeId = 0; // TODO: remind user to change

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('');
  buffer.writeln("part of '${origBasename}.dart';");
  buffer.writeln('');
  buffer.writeln(
      '// ***************************************************************************');
  buffer.writeln('// TypeAdapterGenerator');
  buffer.writeln(
      '// ***************************************************************************');
  buffer.writeln('');
  buffer.writeln('class $adapterName extends TypeAdapter<$className> {');
  buffer.writeln('  @override');
  buffer.writeln('  final int typeId = $typeId; //TODO: <-- change to a unique id!');
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln('  $className read(BinaryReader reader) {');
  buffer.writeln('    final numOfFields = reader.readByte();');
  buffer.writeln('    final fields = <int, dynamic>{');
  buffer.writeln(
      '      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),');
  buffer.writeln('    };');
  buffer.writeln('');
  // Build restoration code using fields map by index
  for (var i = 0; i < c.fields.length; i++) {
    buffer.writeln('    final field_$i = fields[$i];');
  }
  buffer.writeln('');
  // Now construct constructor call, but we need to map fields appropriately
  buffer.writeln('    return $className(');
  for (var i = 0; i < c.fields.length; i++) {
    final f = c.fields[i];
    final readExpr = dartTypeToHiveReadConstruction(f.type, 'field_$i');
    // If it's enum, produce extra mapping (we'll map enums in a follow up block)
    if (_looksLikeEnum(f.type)) {
      buffer.writeln(
          '      ${f.name}: (field_$i is int) ? ${f.type}.values[field_$i] : null,');
    } else {
      buffer.writeln('      ${f.name}: $readExpr,');
    }
  }
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln('  void write(BinaryWriter writer, $className obj) {');
  buffer.writeln('    writer..writeByte(${c.fields.length})');
  for (var i = 0; i < c.fields.length; i++) {
    final f = c.fields[i];
    final writeExpr = dartTypeToHiveWriteExpression(f.type, 'obj.${f.name}');
    buffer.writeln('      ..writeByte($i)');
    buffer.writeln('      ..write($writeExpr)');
  }
  buffer.writeln('    ;');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln('  int get hashCode => typeId.hashCode;');
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln('  bool operator ==(Object other) =>');
  buffer.writeln('      identical(this, other) ||');
  buffer.writeln(
      '      other is $adapterName && runtimeType == other.runtimeType && typeId == other.typeId;');
  buffer.writeln('}');
  return buffer.toString();
}

/// Build a Hive-ready Dart class file (companion) with Hive annotations + helpers
String buildHiveClassFile(ClassDef c, String origBasename) {
  final className = c.name;
  final buffer = StringBuffer();

  buffer.writeln("import 'dart:convert';");
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:hive/hive.dart';");
  buffer.writeln('');
  buffer.writeln("part '${origBasename}_db.g.dart';");
  buffer.writeln('');
  buffer.writeln(
      "// TODO: change the typeId constant to a unique value in your HiveTypes.");
  buffer.writeln("@HiveType(typeId: 0, adapterName: '${className}Adapter')");
  buffer.writeln("class $className extends HiveObject {");
  buffer.writeln('  // fields (auto-generated)');
  for (var i = 0; i < c.fields.length; i++) {
    final f = c.fields[i];
    buffer.writeln("  @HiveField($i)");
    buffer.writeln("  ${f.type}${f.nullable ? '?' : ''} ${f.name};");
    buffer.writeln('');
  }

  // Constructor
  buffer.writeln('');
  buffer.writeln('  $className({');
  for (var i = 0; i < c.fields.length; i++) {
    final f = c.fields[i];
    buffer.writeln('    this.${f.name},');
  }
  buffer.writeln('  });');
  buffer.writeln('');

  // generate ui getters/setters calling save() wrapped
  buffer.writeln('  // ----------------- UI getters/setters -----------------');
  for (final f in c.fields) {
    final cap = _capitalize(f.name);
    final defaultValue = _defaultForType(f.type, f.nullable);
    buffer.writeln(
        '  ${f.type}${f.nullable ? '?' : ''} get ui$cap => ${f.name} ?? $defaultValue;');
    buffer.writeln('  set ui$cap(${f.type}${f.nullable ? '?' : ''} v) {');
    buffer.writeln('    ${f.name} = v;');
    buffer.writeln('    try { save(); } catch (_) {}');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  // copyWith
  buffer.writeln('  $className copyWith({');
  for (final f in c.fields) {
    buffer.writeln('    ${f.type}${f.nullable ? '?' : ''} ${f.name},');
  }
  buffer.writeln('  }) {');
  buffer.writeln('    return $className(');
  for (final f in c.fields) {
    buffer.writeln('      ${f.name}: ${f.name} ?? this.${f.name},');
  }
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln('');

  // toJson
  buffer.writeln('  Map<String,dynamic> toJson() {');
  buffer.writeln('    return {');
  for (var i = 0; i < c.fields.length; i++) {
    final f = c.fields[i];
    final key = f.name;
    final valExpr = _toJsonFieldExpr(f);
    buffer.writeln("      '$key': $valExpr,");
  }
  buffer.writeln('    };');
  buffer.writeln('  }');
  buffer.writeln('');

  // fromJson
  buffer.writeln('  static $className fromJson(Map<String,dynamic> m) {');
  buffer.writeln('    return $className(');
  for (final f in c.fields) {
    final conv = _fromJsonFieldExpr(f);
    buffer.writeln('      ${f.name}: $conv,');
  }
  buffer.writeln('    );');
  buffer.writeln('  }');

  buffer.writeln('}');
  return buffer.toString();
}

/// Build the DB Helper file
String buildDbHelperFile(String modelName) {
  final pascal = ReCase(modelName).pascalCase;
  // I've corrected the import path here to use '_db.dart' which is what you generate.
  return '''
import 'package:hive/hive.dart';
import '${ReCase(modelName).snakeCase}_db.dart';

typedef Condition = bool Function($pascal item);

class ${pascal}DbHelper {
  static const String boxName = '$pascal-box';

  Box<$pascal> get _box => Hive.box<$pascal>(boxName);
  
  static Future<void> init() async {
    Hive.registerAdapter(${pascal}Adapter());

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<$pascal>(boxName);
    }
  }
  
  // ---------- CRUD ----------
  Future<void> add(dynamic id, $pascal item) => _box.put(id, item);

  Future<void> update(dynamic id, $pascal item) => _box.put(id, item);

  List<$pascal> getAll() => _box.values.toList();

  $pascal? getById(dynamic id) => _box.get(id);

  Future<void> delete(dynamic id) => _box.delete(id);

  Future<void> deleteAll(List<dynamic> ids) => _box.deleteAll(ids);

  Future<int> clear() => _box.clear();

  Future<void> deleteFromDisk() => _box.deleteFromDisk();

  // ---------- Helpers ----------

  /// Returns every item that matches [test].
  List<$pascal> where(Condition test) => _box.values.where(test).toList();

  /// Deletes every item whose value satisfies [test].
  Future<int> deleteWhere(Condition test) async {
    final keysToDelete = _box.keys
        .where((k) => test(_box.get(k) as $pascal))
        .toList();
    await _box.deleteAll(keysToDelete);
    return keysToDelete.length;
  }

  /// Returns the first matching item or null.
  $pascal? firstWhereOrNull(Condition test) {
    try {
      return _box.values.firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// Returns the last matching item or null.
  $pascal? lastWhereOrNull(Condition test) {
    try {
      return _box.values.lastWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// Returns true if at least one element satisfies [test].
  bool any(Condition test) => _box.values.any(test);

  /// Count elements that satisfy [test] (or all if [test] is null).
  int count([Condition? test]) =>
      test == null ? _box.length : _box.values.where(test).length;

  /// Returns a Map<key, value> of items that match [test].
  Map<dynamic, $pascal> mapWhere(Condition test) {
    final result = <dynamic, $pascal>{};
    for (final k in _box.keys) {
      final v = _box.get(k);
      if (v != null && test(v)) result[k] = v;
    }
    return result;
  }
}
''';
}

/// Helpers for toJson/fromJson defaults
String _toJsonFieldExpr(FieldDef f) {
  final n = f.name;
  final t = f.type;
  if (t == 'Color' || t.endsWith('Color')) return "${n}?.value";
  if (t == 'DateTime') return "${n}?.toIso8601String()";
  if (t == 'TimeOfDay')
    return "${n} != null ? {'hour': ${n}!.hour, 'minute': ${n}!.minute} : null";
  if (_looksLikeEnum(t)) return "${n}?.index";
  // assume has toJson or toMap
  return "${n} is Map ? ${n} : (${n} != null ? ( ${n}.toMap != null ? ${n}.toMap() : jsonDecode(jsonEncode(${n})) ) : null)";
}

String _fromJsonFieldExpr(FieldDef f) {
  final n = "m['${f.name}']";
  final t = f.type;
  if (t == 'String') return "$n as String?";
  if (t == 'int') return "$n as int?";
  if (t == 'double') return "$n as double?";
  if (t == 'bool') return "$n as bool?";
  if (t == 'DateTime')
    return "$n != null ? DateTime.parse($n as String) : null";
  if (t == 'Color' || t.endsWith('Color'))
    return "$n != null ? Color($n as int) : null";
  if (t == 'TimeOfDay')
    return """{
    final tmp = $n as Map?;
    if (tmp == null) return null;
    return TimeOfDay(hour: tmp['hour'] as int, minute: tmp['minute'] as int);
  }()""";
  if (_looksLikeEnum(t)) return "(($n is int) ? ${t}.values[$n as int] : null)";
  // fallback attempt to call fromMap
  return """{
    final v = $n;
    if (v == null) return null;
    if (v is Map && ${_maybeHasFromMap(t)}) {
       try {
        return ${t}.fromMap(Map<String,dynamic>.from(v as Map));
       } catch (e) {
        return v; // fallback if fromMap fails
       }
    }
    return v;
  }()""";
}

/// crude enum detector: capitalized simple type (user may refine)
bool _looksLikeEnum(String t) {
  // if type starts with uppercase and it's short, treat as enum (heuristic)
  final name = t;
  if (name.contains('<')) return false;
  if (name.length <= 1) return false;
  return name[0] == name[0].toUpperCase() && name.toLowerCase() != name;
}

/// naive check placeholder (can't inspect other files here)
bool _maybeHasFromMap(String t) => _looksLikeEnum(t) || t.endsWith('Model');

String _capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

String _defaultForType(String t, bool nullable) {
  if (nullable) return 'null';
  if (t == 'String') return "''";
  if (t == 'int' || t == 'double') return '0';
  if (t == 'bool') return 'false';
  if (t == 'List') return '[]';
  if (t == 'Map') return '{}';
  return 'null'; // Fallback for complex types
}
