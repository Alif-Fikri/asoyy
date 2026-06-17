import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/password_entity.dart';

Future<Directory> _passwordDir() async {
  if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext != null) return ext;
  }
  return getApplicationDocumentsDirectory();
}

class CsvService {
  static const _headers = ['title', 'username', 'password', 'website', 'notes', 'createdAt'];

  String _escape(String? value) {
    if (value == null || value.isEmpty) return '""';
    return '"${value.replaceAll('"', '""')}"';
  }

  String exportToCsvString(List<PasswordEntity> passwords) {
    final buffer = StringBuffer();
    buffer.writeln(_headers.join(','));
    for (final p in passwords) {
      buffer.writeln([
        _escape(p.title),
        _escape(p.username),
        _escape(p.password),
        _escape(p.website),
        _escape(p.notes),
        _escape(p.createdAt.toIso8601String()),
      ].join(','));
    }
    return buffer.toString();
  }

  Future<File> exportToFile(List<PasswordEntity> passwords) async {
    final dir = await _passwordDir();
    final file = File('${dir.path}/vela_passwords.csv');
    await file.writeAsString(exportToCsvString(passwords), encoding: utf8);
    return file;
  }

  List<PasswordEntity> importFromBytes(List<int> bytes) {
    final content = utf8.decode(bytes);
    return _parseCsv(content);
  }

  List<PasswordEntity> _parseCsv(String content) {
    final lines = content
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) return [];

    final passwords = <PasswordEntity>[];
    for (final line in lines.sublist(1)) {
      try {
        final fields = _parseLine(line);
        if (fields.length < 3 || fields[0].isEmpty || fields[2].isEmpty) continue;

        final createdAt = fields.length > 5 && fields[5].isNotEmpty
            ? DateTime.tryParse(fields[5]) ?? DateTime.now()
            : DateTime.now();

        passwords.add(PasswordEntity(
          id: const Uuid().v4(),
          title: fields[0],
          username: fields[1],
          password: fields[2],
          website: fields.length > 3 && fields[3].isNotEmpty ? fields[3] : null,
          notes: fields.length > 4 && fields[4].isNotEmpty ? fields[4] : null,
          createdAt: createdAt,
        ));
      } catch (_) {
        continue;
      }
    }
    return passwords;
  }

  List<String> _parseLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i += 2;
          continue;
        }
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
      i++;
    }
    fields.add(buffer.toString());
    return fields;
  }
}
