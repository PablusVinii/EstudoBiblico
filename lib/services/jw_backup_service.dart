import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class JwBackupService {
  static Archive _decodeZip(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

  /// Exporta todas as anotações e respostas para um arquivo oficial `.jwlibrary`
  static Future<String> exportToJwLibrary() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    // 1. Cria banco temporário SQLite com o schema oficial do JW Library
    final tempDbPath = p.join(backupDir.path, 'temp_userData.db');
    final tempDbFile = File(tempDbPath);
    if (await tempDbFile.exists()) {
      await tempDbFile.delete();
    }

    final db = await openDatabase(
      tempDbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Location (
            LocationId INTEGER PRIMARY KEY AUTOINCREMENT,
            BookNumber INTEGER,
            ChapterNumber INTEGER,
            DocumentId INTEGER,
            Track INTEGER,
            IssueTagNumber INTEGER NOT NULL DEFAULT 0,
            KeySymbol TEXT,
            MepsLanguage INTEGER NOT NULL DEFAULT 0,
            Type INTEGER NOT NULL DEFAULT 0,
            Title TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE UserMark (
            UserMarkId INTEGER PRIMARY KEY AUTOINCREMENT,
            ColorIndex INTEGER DEFAULT 1,
            LocationId INTEGER NOT NULL,
            StyleIndex INTEGER DEFAULT 0,
            UserMarkGuid TEXT NOT NULL,
            Version INTEGER DEFAULT 1
          );
        ''');

        await db.execute('''
          CREATE TABLE Note (
            NoteId INTEGER PRIMARY KEY AUTOINCREMENT,
            Guid TEXT NOT NULL,
            UserMarkId INTEGER,
            LocationId INTEGER,
            Title TEXT,
            Content TEXT NOT NULL,
            LastModified TEXT NOT NULL,
            Created TEXT NOT NULL,
            BlockType INTEGER DEFAULT 1,
            BlockIdentifier INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE InputField (
            LocationId INTEGER NOT NULL,
            TextTag TEXT NOT NULL,
            Value TEXT NOT NULL,
            PRIMARY KEY (LocationId, TextTag),
            FOREIGN KEY (LocationId) REFERENCES Location (LocationId)
          );
        ''');
      },
    );

    int locationId = 1;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      // Insere anotações no banco com suporte a Note e InputField
      for (final key in keys) {
        if (key.startsWith('study_ans_')) {
          final val = prefs.getString(key) ?? '';
          if (val.trim().isNotEmpty) {
            final cleanKey = key.replaceFirst('study_ans_', '');
            final lastPIndex = cleanKey.lastIndexOf('_p');
            final articleId = lastPIndex != -1 ? cleanKey.substring(0, lastPIndex) : cleanKey;
            final pNum = lastPIndex != -1 ? cleanKey.substring(lastPIndex + 2) : '1';
            final pInt = int.tryParse(pNum) ?? 1;

            await db.insert('Location', {
              'LocationId': locationId,
              'KeySymbol': 'w',
              'Title': articleId,
            });

            await db.insert('InputField', {
              'LocationId': locationId,
              'TextTag': 'p$pNum',
              'Value': val,
            });

            await db.insert('Note', {
              'NoteId': locationId,
              'Guid': 'note_${DateTime.now().microsecondsSinceEpoch}_$locationId',
              'LocationId': locationId,
              'Title': 'Parágrafo $pNum',
              'Content': val,
              'LastModified': nowIso,
              'Created': nowIso,
              'BlockType': 1,
              'BlockIdentifier': pInt,
            });

            locationId++;
          }
        }
      }
    } finally {
      await db.close();
    }

    // 2. Prepara o manifest.json oficial do JW Library
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final manifestData = {
      'name': 'Sentinela Study Backup',
      'creationDate': timestamp,
      'version': 1,
      'type': 0,
      'userDataBackup': {
        'lastModifiedDate': timestamp,
        'deviceName': 'Sentinela Study App',
        'databaseName': 'userData.db',
        'schemaVersion': 8,
      }
    };

    // 3. Empacota no formato .jwlibrary (ZIP)
    final archive = Archive();
    final manifestBytes = utf8.encode(jsonEncode(manifestData));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    final dbBytes = await File(tempDbPath).readAsBytes();
    archive.addFile(ArchiveFile('userData.db', dbBytes.length, dbBytes));

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    final nowStr = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '_').substring(0, 15);
    final backupFilePath = p.join(backupDir.path, 'Sentinela_Backup_$nowStr.jwlibrary');

    final backupFile = File(backupFilePath);
    await backupFile.writeAsBytes(zipBytes);

    // Limpa banco temporário
    if (await tempDbFile.exists()) {
      await tempDbFile.delete();
    }

    return backupFilePath;
  }

  /// Restaura as anotações a partir de um arquivo .jwlibrary oficial (tanto de Note quanto de InputField)
  static Future<int> importFromJwLibrary(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;

    final bytes = await file.readAsBytes();
    final archive = await compute(_decodeZip, bytes);

    ArchiveFile? dbFile;
    for (final f in archive) {
      if (f.name == 'userData.db') {
        dbFile = f;
        break;
      }
    }

    if (dbFile == null) return 0;

    final appDir = await getApplicationDocumentsDirectory();
    final tempDbPath = p.join(appDir.path, 'restore_userData.db');
    await File(tempDbPath).writeAsBytes(dbFile.content as List<int>);

    final db = await openDatabase(tempDbPath, readOnly: true);
    final prefs = await SharedPreferences.getInstance();
    int importedCount = 0;

    try {
      // 1. Tenta restaurar da tabela Note oficial
      try {
        final noteRows = await db.rawQuery('''
          SELECT Location.Title, Note.Title AS NoteTitle, Note.Content, Note.BlockIdentifier
          FROM Note
          LEFT JOIN Location ON Note.LocationId = Location.LocationId
        ''');

        for (final r in noteRows) {
          final title = r['Title']?.toString() ?? 'imported';
          final content = r['Content']?.toString() ?? '';
          final blockId = r['BlockIdentifier'] as int? ?? 1;

          if (content.trim().isNotEmpty) {
            final key = 'study_ans_${title}_p$blockId';
            await prefs.setString(key, content);
            importedCount++;
          }
        }
      } catch (_) {}

      // 2. Tenta restaurar da tabela InputField (caso o backup use formulários)
      try {
        final inputRows = await db.rawQuery('''
          SELECT Location.Title, InputField.TextTag, InputField.Value 
          FROM InputField 
          LEFT JOIN Location ON InputField.LocationId = Location.LocationId
        ''');

        for (final r in inputRows) {
          final title = r['Title']?.toString() ?? 'imported';
          final tag = r['TextTag']?.toString() ?? 'p1';
          final val = r['Value']?.toString() ?? '';

          if (val.trim().isNotEmpty) {
            final pNum = tag.replaceAll(RegExp(r'[^0-9]'), '');
            final key = 'study_ans_${title}_p$pNum';
            if (!prefs.containsKey(key)) {
              await prefs.setString(key, val);
              importedCount++;
            }
          }
        }
      } catch (_) {}
    } finally {
      await db.close();
      final f = File(tempDbPath);
      if (await f.exists()) await f.delete();
    }

    return importedCount;
  }
}
