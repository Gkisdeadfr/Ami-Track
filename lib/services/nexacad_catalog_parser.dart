/// Parser for the NexAcad course catalogue.
///
/// https://nexacad.pages.dev/pages/resources serves its whole library from a
/// generated script containing a JavaScript object literal:
///
///     window.EMBEDDED_COURSE_CATALOG={CSIT124:{name:"...",children:[...]}}
///
/// It is not JSON (unquoted keys), so this file contains a small, dependency
/// free reader for that subset of JavaScript and turns it into library entries.
library;

class NexacadEntry {
  final String subjectCode;
  final String subjectName;
  final String title;
  final String fileType;
  final String size;
  final String previewUrl;
  final String downloadUrl;

  const NexacadEntry({
    required this.subjectCode,
    required this.subjectName,
    required this.title,
    required this.fileType,
    required this.size,
    required this.previewUrl,
    required this.downloadUrl,
  });
}

/// Returns null when [script] does not look like the catalogue bundle.
List<NexacadEntry>? parseNexacadCatalog(String script) {
  final marker = script.indexOf('EMBEDDED_COURSE_CATALOG');
  if (marker == -1) return null;

  final equals = script.indexOf('=', marker);
  final brace = script.indexOf('{', equals == -1 ? marker : equals);
  if (brace == -1) return null;

  final Object? catalog;
  try {
    catalog = _JsValueReader(script, brace).readValue();
  } on FormatException {
    return null;
  }
  if (catalog is! Map) return null;

  final entries = <NexacadEntry>[];
  final seen = <String>{};

  void visitFolder(Map folder, String code, String name) {
    final folderCode = _string(folder['code']);
    final folderName = _string(folder['name']);
    final isNestedCourse = _string(folder['type']) == 'college' && folderCode.isNotEmpty;
    final effectiveCode = isNestedCourse ? folderCode : code;
    final effectiveName = isNestedCourse && folderName.isNotEmpty ? folderName : name;

    final children = folder['children'];
    if (children is! List) return;

    for (final child in children) {
      if (child is! Map) continue;
      final type = _string(child['type']);
      if (type == 'folder' || type == 'college') {
        visitFolder(child, effectiveCode, effectiveName);
        continue;
      }

      final fileId = _string(child['fileId']);
      final title = _string(child['name']);
      if (title.isEmpty || (fileId.isEmpty && _string(child['driveUrl']).isEmpty)) {
        continue;
      }
      final driveId = _driveId(child);
      final dedupeKey = driveId.isEmpty ? '$effectiveCode/$title' : driveId;
      if (!seen.add(dedupeKey)) continue;

      entries.add(
        NexacadEntry(
          subjectCode: effectiveCode.isNotEmpty ? effectiveCode : 'General',
          subjectName: effectiveName,
          title: title,
          fileType: _fileType(child, title),
          size: _formatSize(_string(child['size'])),
          previewUrl: _string(child['previewUrl']).isNotEmpty
              ? _string(child['previewUrl'])
              : (driveId.isEmpty ? '' : 'https://drive.google.com/file/d/$driveId/preview'),
          downloadUrl: _string(child['downloadUrl']).isNotEmpty
              ? _string(child['downloadUrl'])
              : (driveId.isEmpty
                  ? _string(child['driveUrl'])
                  : 'https://drive.google.com/uc?id=$driveId&export=download'),
        ),
      );
    }
  }

  for (final entry in catalog.entries) {
    final value = entry.value;
    if (value is Map) {
      visitFolder(
        value,
        entry.key.toString(),
        _string(value['name']),
      );
    }
  }

  return entries.isEmpty ? null : entries;
}

String _driveId(Map file) {
  final fileId = _string(file['fileId']);
  if (fileId.isNotEmpty) return fileId;
  final match = RegExp(r'/d/([a-zA-Z0-9_-]{10,})|id=([a-zA-Z0-9_-]{10,})')
      .firstMatch(_string(file['driveUrl']));
  if (match == null) return '';
  return match.group(1) ?? match.group(2) ?? '';
}

String _fileType(Map file, String title) {
  final declared = _string(file['fileType']);
  if (declared.isNotEmpty) return declared;

  final lower = title.toLowerCase();
  if (lower.contains('pyq') || lower.contains('previous year') || lower.contains('question paper')) {
    return 'PYQ';
  }
  if (lower.contains('lab')) return 'Lab';
  if (lower.contains('book')) return 'Books';
  return 'Notes';
}

String _formatSize(String rawBytes) {
  final bytes = int.tryParse(rawBytes);
  if (bytes == null || bytes <= 0) return '';
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).round()} KB';
}

String _string(Object? value) => value is String ? value : '';

/// Minimal reader for the JavaScript literal subset the catalogue uses:
/// object literals, arrays, strings, numbers and booleans.
class _JsValueReader {
  _JsValueReader(this.source, this.index);

  final String source;
  int index;

  Object? readValue() {
    _skipWhitespace();
    if (index >= source.length) {
      throw const FormatException('Unexpected end of input');
    }

    final char = source[index];
    if (char == '{') return _readObject();
    if (char == '[') return _readArray();
    if (char == '"' || char == "'" || char == '`') return _readString(char);
    if (source.startsWith('true', index)) {
      index += 4;
      return true;
    }
    if (source.startsWith('false', index)) {
      index += 5;
      return false;
    }
    if (source.startsWith('null', index)) {
      index += 4;
      return null;
    }
    if (source.startsWith('undefined', index)) {
      index += 9;
      return null;
    }
    return _readNumberOrWord();
  }

  Map<String, Object?> _readObject() {
    final result = <String, Object?>{};
    index++; // {
    while (true) {
      _skipWhitespace();
      if (index >= source.length) throw const FormatException('Unterminated object');
      if (source[index] == '}') {
        index++;
        return result;
      }
      if (source[index] == ',') {
        index++;
        continue;
      }

      final key = _readKey();
      _skipWhitespace();
      if (index >= source.length || source[index] != ':') {
        throw const FormatException('Expected ":"');
      }
      index++;
      result[key] = readValue();
    }
  }

  List<Object?> _readArray() {
    final result = <Object?>[];
    index++; // [
    while (true) {
      _skipWhitespace();
      if (index >= source.length) throw const FormatException('Unterminated array');
      if (source[index] == ']') {
        index++;
        return result;
      }
      if (source[index] == ',') {
        index++;
        continue;
      }
      result.add(readValue());
    }
  }

  String _readKey() {
    final char = source[index];
    if (char == '"' || char == "'" || char == '`') {
      return _readString(char);
    }
    final start = index;
    while (index < source.length && RegExp(r'[A-Za-z0-9_$]').hasMatch(source[index])) {
      index++;
    }
    if (start == index) throw const FormatException('Expected a property name');
    return source.substring(start, index);
  }

  String _readString(String quote) {
    index++; // opening quote
    final buffer = StringBuffer();
    while (index < source.length) {
      final char = source[index];
      if (char == quote) {
        index++;
        return buffer.toString();
      }
      if (char == r'\') {
        index++;
        if (index >= source.length) break;
        final escaped = source[index];
        switch (escaped) {
          case 'n':
            buffer.write('\n');
          case 'r':
            buffer.write('\r');
          case 't':
            buffer.write('\t');
          case 'b':
            buffer.write('\b');
          case 'f':
            buffer.write('\f');
          case 'u':
            if (index + 4 < source.length) {
              final code = int.tryParse(source.substring(index + 1, index + 5), radix: 16);
              if (code != null) {
                buffer.writeCharCode(code);
                index += 5;
                continue;
              }
            }
            buffer.write('u');
          default:
            buffer.write(escaped);
        }
        index++;
        continue;
      }
      buffer.write(char);
      index++;
    }
    throw const FormatException('Unterminated string');
  }

  Object _readNumberOrWord() {
    final start = index;
    while (index < source.length && !'{}[],:"\'`'.contains(source[index])) {
      index++;
    }
    final raw = source.substring(start, index).trim();
    return num.tryParse(raw) ?? raw;
  }

  void _skipWhitespace() {
    while (index < source.length) {
      final char = source[index];
      if (char == ' ' || char == '\n' || char == '\r' || char == '\t') {
        index++;
        continue;
      }
      if (source.startsWith('//', index)) {
        final end = source.indexOf('\n', index);
        index = end == -1 ? source.length : end + 1;
        continue;
      }
      if (source.startsWith('/*', index)) {
        final end = source.indexOf('*/', index);
        index = end == -1 ? source.length : end + 2;
        continue;
      }
      break;
    }
  }
}
