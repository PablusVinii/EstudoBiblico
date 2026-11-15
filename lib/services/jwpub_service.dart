import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;

class JwpubCryptoKeys {
  final Uint8List key;
  final Uint8List iv;
  final String keyHex;
  final String ivHex;

  const JwpubCryptoKeys({
    required this.key,
    required this.iv,
    required this.keyHex,
    required this.ivHex,
  });
}

class JwpubBibleCitation {
  final int bookNumber;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;

  const JwpubBibleCitation({
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });
}

class JwpubInternalCitation {
  final String lang;
  final int documentId;

  const JwpubInternalCitation({
    required this.lang,
    required this.documentId,
  });
}

class JwpubManifest {
  final String name;
  final String symbol;
  final int year;
  final int language;
  final String publicationType;
  final String dbFileName;

  const JwpubManifest({
    required this.name,
    required this.symbol,
    required this.year,
    required this.language,
    required this.publicationType,
    required this.dbFileName,
  });

  factory JwpubManifest.fromJson(Map<String, dynamic> json) {
    final pub = json['publication'] as Map<String, dynamic>? ?? {};
    return JwpubManifest(
      name: json['name']?.toString() ?? '',
      symbol: pub['symbol']?.toString() ?? '',
      year: int.tryParse(pub['year']?.toString() ?? '') ?? 0,
      language: int.tryParse(pub['language']?.toString() ?? '') ?? 0,
      publicationType: pub['publicationType']?.toString() ?? 'Unknown',
      dbFileName: pub['fileName']?.toString() ?? '',
    );
  }
}

class JwpubService {
  /// Constante hexadecimal fixa para operação XOR (32 bytes = 256 bits)
  static const String xorConstantHex =
      '11cbb5587e32846d4c26790c633da289f66fe5842a3a585ce1bc3a294af5ada7';

  /// Mapeamento canônico dos 66 livros da Bíblia pelo esquema NWTR
  static const Map<int, String> canonicalBookNames = {
    1: 'Gênesis', 2: 'Êxodo', 3: 'Levítico', 4: 'Números', 5: 'Deuteronômio',
    6: 'Josué', 7: 'Juízes', 8: 'Rute', 9: '1 Samuel', 10: '2 Samuel',
    11: '1 Reis', 12: '2 Reis', 13: '1 Crônicas', 14: '2 Crônicas', 15: 'Esdras',
    16: 'Neemias', 17: 'Ester', 18: 'Jó', 19: 'Salmos', 20: 'Provérbios',
    21: 'Eclesiastes', 22: 'Cântico de Salomão', 23: 'Isaías', 24: 'Jeremias',
    25: 'Lamentações', 26: 'Ezequiel', 27: 'Daniel', 28: 'Oseias', 29: 'Joel',
    30: 'Amós', 31: 'Obadias', 32: 'Jonas', 33: 'Miqueias', 34: 'Naum',
    35: 'Habacuque', 36: 'Sofonias', 37: 'Ageu', 38: 'Zacarias', 39: 'Malaquias',
    40: 'Mateus', 41: 'Marcos', 42: 'Lucas', 43: 'João', 44: 'Atos',
    45: 'Romanos', 46: '1 Coríntios', 47: '2 Coríntios', 48: 'Gálatas', 49: 'Efésios',
    50: 'Filipenses', 51: 'Colossenses', 52: '1 Tessalonicenses', 53: '2 Tessalonicenses',
    54: '1 Timóteo', 55: '2 Timóteo', 56: 'Tito', 57: 'Filêmon', 58: 'Hebreus',
    59: 'Tiago', 60: '1 Pedro', 61: '2 Pedro', 62: '1 João', 63: '2 João',
    64: '3 João', 65: 'Judas', 66: 'Apocalipse',
  };

  /// Deriva a Chave AES (16 bytes) e o Vetor de Inicialização IV (16 bytes)
  /// aplicando SHA-256 no identificador base e depois XOR com a constante fixa.
  static JwpubCryptoKeys deriveKeyAndIv({
    required int languageIndex,
    required String symbol,
    required int year,
    int? issueTagNumber,
  }) {
    String baseStr = '${languageIndex}_${symbol}_$year';
    if (issueTagNumber != null && issueTagNumber != 0) {
      baseStr += '_$issueTagNumber';
    }

    final shaBytes = sha256.convert(utf8.encode(baseStr)).bytes;
    final constantBytes = _hexToBytes(xorConstantHex);

    final xorBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      xorBytes[i] = shaBytes[i] ^ constantBytes[i];
    }

    final key = Uint8List.sublistView(xorBytes, 0, 16);
    final iv = Uint8List.sublistView(xorBytes, 16, 32);

    return JwpubCryptoKeys(
      key: key,
      iv: iv,
      keyHex: _bytesToHex(key),
      ivHex: _bytesToHex(iv),
    );
  }

  /// Criptografa conteúdo HTML com UTF-8 -> Zlib Deflate -> AES-128-CBC (PKCS7)
  static Uint8List encryptContent({
    required String html,
    required Uint8List key,
    required Uint8List iv,
  }) {
    final utf8Bytes = utf8.encode(html);
    final compressed = zlib.encode(utf8Bytes);

    final encKey = enc.Key(key);
    final encIv = enc.IV(iv);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));

    final encrypted = encrypter.encryptBytes(compressed, iv: encIv);
    return Uint8List.fromList(encrypted.bytes);
  }

  /// Descriptografa conteúdo BLOB com AES-128-CBC -> Zlib Inflate -> UTF-8
  static String decryptContent({
    required List<int> encryptedBytes,
    required Uint8List key,
    required Uint8List iv,
  }) {
    final encKey = enc.Key(key);
    final encIv = enc.IV(iv);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));

    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(Uint8List.fromList(encryptedBytes)),
      iv: encIv,
    );

    List<int> decompressed;
    try {
      decompressed = zlib.decode(decrypted);
    } catch (_) {
      try {
        decompressed = ZLibDecoder().decodeBytes(decrypted);
      } catch (_) {
        decompressed = decrypted;
      }
    }

    return utf8.decode(decompressed);
  }

  /// Analisa link de citação bíblica no formato `jwpub://b/NWTR/{livro}:{cap}:{vers}`
  static JwpubBibleCitation? parseBibleLink(String url) {
    if (!url.startsWith('jwpub://b/NWTR/')) return null;
    final path = url.substring('jwpub://b/NWTR/'.length);

    // Formato 1: range completo 19:23:1-19:23:6 ou 66:21:3-66:21:4
    final fullRangeMatch = RegExp(r'^(\d+):(\d+):(\d+)-\d+:(\d+):(\d+)$').firstMatch(path);
    if (fullRangeMatch != null) {
      final bookNum = int.parse(fullRangeMatch.group(1)!);
      final ch = int.parse(fullRangeMatch.group(2)!);
      final startV = int.parse(fullRangeMatch.group(3)!);
      final endV = int.parse(fullRangeMatch.group(5)!);
      final bookName = canonicalBookNames[bookNum] ?? 'Livro $bookNum';
      return JwpubBibleCitation(
        bookNumber: bookNum,
        bookName: bookName,
        chapter: ch,
        startVerse: startV,
        endVerse: endV,
      );
    }

    // Formato 2: range simples 66:21:3-4
    final simpleRangeMatch = RegExp(r'^(\d+):(\d+):(\d+)-(\d+)$').firstMatch(path);
    if (simpleRangeMatch != null) {
      final bookNum = int.parse(simpleRangeMatch.group(1)!);
      final ch = int.parse(simpleRangeMatch.group(2)!);
      final startV = int.parse(simpleRangeMatch.group(3)!);
      final endV = int.parse(simpleRangeMatch.group(4)!);
      final bookName = canonicalBookNames[bookNum] ?? 'Livro $bookNum';
      return JwpubBibleCitation(
        bookNumber: bookNum,
        bookName: bookName,
        chapter: ch,
        startVerse: startV,
        endVerse: endV,
      );
    }

    // Formato 3: versículo único 40:24:14
    final singleMatch = RegExp(r'^(\d+):(\d+):(\d+)$').firstMatch(path);
    if (singleMatch != null) {
      final bookNum = int.parse(singleMatch.group(1)!);
      final ch = int.parse(singleMatch.group(2)!);
      final v = int.parse(singleMatch.group(3)!);
      final bookName = canonicalBookNames[bookNum] ?? 'Livro $bookNum';
      return JwpubBibleCitation(
        bookNumber: bookNum,
        bookName: bookName,
        chapter: ch,
        startVerse: v,
        endVerse: v,
      );
    }

    return null;
  }

  /// Analisa link interno de documento no formato `jwpub://p/{lang}:{docId}/`
  static JwpubInternalCitation? parseInternalLink(String url) {
    final match = RegExp(r'^jwpub:\/\/p\/([a-zA-Z]+):(\d+)\/?$').firstMatch(url);
    if (match == null) return null;
    return JwpubInternalCitation(
      lang: match.group(1)!,
      documentId: int.parse(match.group(2)!),
    );
  }

  /// Extração segura contra Zip Slip
  static Future<void> _safeExtractArchive(Archive archive, Directory targetDir) async {
    final normalizedTarget = p.normalize(targetDir.path);
    for (final file in archive) {
      if (!file.isFile) continue;
      final resolvedPath = p.normalize(p.join(targetDir.path, file.name));
      if (!p.isWithin(normalizedTarget, resolvedPath) && resolvedPath != normalizedTarget) {
        throw FormatException('Caminho inseguro detectado no arquivo: ${file.name}');
      }
      final outFile = File(resolvedPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  /// Descompacta um pacote `.jwpub` extraindo o `manifest.json` e o `contents`
  static Future<JwpubManifest?> extractJwpubPackage({
    required File jwpubFile,
    required Directory destinationDir,
  }) async {
    final bytes = await jwpubFile.readAsBytes();
    final outerArchive = ZipDecoder().decodeBytes(bytes);

    // 1. Extrai o manifest.json
    final manifestEntry = outerArchive.findFile('manifest.json');
    JwpubManifest? manifest;
    if (manifestEntry != null) {
      final manifestJsonStr = utf8.decode(manifestEntry.content as List<int>);
      final manifestMap = jsonDecode(manifestJsonStr) as Map<String, dynamic>;
      manifest = JwpubManifest.fromJson(manifestMap);
    }

    // 2. Extrai o ZIP interno 'contents'
    final contentsEntry = outerArchive.findFile('contents');
    if (contentsEntry != null) {
      final innerArchive = ZipDecoder().decodeBytes(contentsEntry.content as List<int>);
      await _safeExtractArchive(innerArchive, destinationDir);
    } else {
      await _safeExtractArchive(outerArchive, destinationDir);
    }

    return manifest;
  }

  static Uint8List _hexToBytes(String hex) {
    final clean = hex.replaceAll(' ', '');
    final result = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < clean.length; i += 2) {
      result[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
