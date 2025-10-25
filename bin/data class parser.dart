/// ---------- Utility: simple dart-model parser (best-effort) ----------
class FieldDef {
  final String type;
  final String name;
  final bool nullable;
  FieldDef(this.type, this.name, {this.nullable = false});
}

class ClassDef {
  final String name;
  final List<FieldDef> fields;
  ClassDef(this.name, this.fields);
}

/// Very small parser to extract the first class and its fields.
/// NOTE: this is a heuristic parser — it handles simple field declarations like:
///   String? title;
///   int count;
///   Color? color;
ClassDef? parseFirstClass(String source) {
  final classRegex = RegExp(
      r'class\s+([A-Za-z0-9_]+)\s*(?:extends\s+[A-Za-z0-9_<>]+)?\s*{',
      multiLine: true);
  final classMatch = classRegex.firstMatch(source);
  if (classMatch == null) return null;
  final className = classMatch.group(1)!;

  // find the class body roughly by counting braces from match.start
  int start = classMatch.end;
  int braceCount = 1;
  int i = start;
  while (i < source.length && braceCount > 0) {
    if (source[i] == '{') braceCount++;
    if (source[i] == '}') braceCount--;
    i++;
  }
  final body = source.substring(start, i - 1);

  // Field regex: capture lines like: Type? name;  or final Type name;
  final fieldRegex = RegExp(
      r'(?:@[\w\(\)\s,]+\s*)*(?:final|var)?\s*([A-Za-z0-9_<>, ?]+)\s+([A-Za-z0-9_]+)\s*;',
      multiLine: true);
  final matches = fieldRegex.allMatches(body);
  final fields = <FieldDef>[];
  for (final m in matches) {
    var rawType = m.group(1)!.trim();
    var name = m.group(2)!;
    var nullable = rawType.endsWith('?');
    if (nullable) rawType = rawType.substring(0, rawType.length - 1).trim();
    fields.add(FieldDef(rawType, name, nullable: nullable));
  }
  return ClassDef(className, fields);
}
