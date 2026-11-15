import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class PubMediaException implements Exception {
  final String message;
  final Uri? uri;
  final int? statusCode;

  const PubMediaException(this.message, {this.uri, this.statusCode});

  @override
  String toString() => 'PubMediaException: $message ${statusCode != null ? "(Status $statusCode)" : ""}';
}

class PubMediaChecksumException implements Exception {
  final String expectedChecksum;
  final String actualChecksum;
  final String filePath;

  const PubMediaChecksumException({
    required this.expectedChecksum,
    required this.actualChecksum,
    required this.filePath,
  });

  @override
  String toString() =>
      'PubMediaChecksumException: Falha na integridade SHA-256 para $filePath. Esperado: $expectedChecksum, Obtido: $actualChecksum';
}

class PubMediaFile {
  final String url;
  final String filename;
  final String title;
  final String language;
  final String fileFormat;
  final int sizeBytes;
  final String checksum;
  final int? bibleBook;
  final int? track;
  final int? durationSeconds;
  final String mimeType;

  const PubMediaFile({
    required this.url,
    required this.filename,
    required this.title,
    required this.language,
    required this.fileFormat,
    this.sizeBytes = 0,
    this.checksum = '',
    this.bibleBook,
    this.track,
    this.durationSeconds,
    this.mimeType = '',
  });

  factory PubMediaFile.fromApi(String language, String format, Map<String, dynamic> data) {
    final fileMeta = data['file'] as Map<String, dynamic>? ?? {};
    final rawUrl = fileMeta['url']?.toString() ?? '';
    final fn = rawUrl.isNotEmpty ? p.basename(Uri.parse(rawUrl).path) : '';

    return PubMediaFile(
      url: rawUrl,
      filename: fn,
      title: data['title']?.toString() ?? '',
      language: language,
      fileFormat: format.toUpperCase(),
      sizeBytes: int.tryParse(data['filesize']?.toString() ?? '') ??
          int.tryParse(fileMeta['filesize']?.toString() ?? '') ??
          0,
      checksum: fileMeta['checksum']?.toString() ?? '',
      bibleBook: int.tryParse(data['booknum']?.toString() ?? ''),
      track: int.tryParse(data['track']?.toString() ?? ''),
      durationSeconds: int.tryParse(data['duration']?.toString() ?? ''),
      mimeType: data['mimetype']?.toString() ?? fileMeta['mimetype']?.toString() ?? '',
    );
  }
}

class PubMediaPublication {
  final String pubCode;
  final String pubName;
  final List<PubMediaFile> files;

  const PubMediaPublication({
    required this.pubCode,
    required this.pubName,
    required this.files,
  });

  List<PubMediaFile> filesByFormat(String fmt) {
    return files.where((f) => f.fileFormat.toUpperCase() == fmt.toUpperCase()).toList();
  }

  List<PubMediaFile> filesByLanguage(String langCode) {
    return files.where((f) => f.language.toUpperCase() == langCode.toUpperCase()).toList();
  }

  /// Retorna o arquivo preferencial priorizando formatos (por padrao JWPUB, depois EPUB)
  PubMediaFile? preferredFile({
    String? preferredLanguage,
    List<String> preferredFormats = const ['JWPUB', 'EPUB'],
  }) {
    final candidatePool = preferredLanguage != null
        ? filesByLanguage(preferredLanguage)
        : files;

    for (final fmt in preferredFormats) {
      final matches = candidatePool.where((f) => f.fileFormat == fmt.toUpperCase());
      if (matches.isNotEmpty) {
        return matches.first;
      }
    }

    return candidatePool.isNotEmpty ? candidatePool.first : null;
  }
}

class PubMediaClient {
  static const List<String> defaultEndpoints = [
    'https://b.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS',
    'https://app.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS',
  ];

  final http.Client _client;
  final List<String> _endpoints;

  PubMediaClient({
    http.Client? client,
    List<String>? endpoints,
  })  : _client = client ?? http.Client(),
        _endpoints = endpoints ?? defaultEndpoints;

  /// Consulta os metadados de uma publicacao e descobre todos os arquivos disponiveis
  Future<PubMediaPublication?> getPublication({
    required String pubCode,
    String language = 'T',
    int? issue,
    int? bookNumber,
    String fileFormat = 'JWPUB,EPUB',
    bool allLanguages = false,
  }) async {
    for (final baseEndpoint in _endpoints) {
      final queryParams = <String, String>{
        'output': 'json',
        'pub': pubCode,
        'langwritten': language,
        'fileformat': fileFormat,
        'alllangs': allLanguages ? '1' : '0',
      };

      if (issue != null) {
        queryParams['issue'] = issue.toString();
      }
      if (bookNumber != null) {
        queryParams['booknum'] = bookNumber.toString();
      }

      final uri = Uri.parse(baseEndpoint).replace(queryParameters: queryParams);

      try {
        final response = await _client.get(
          uri,
          headers: {'User-Agent': 'JWLibrary/14.3'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 404) {
          continue;
        }

        if (response.statusCode != 200) {
          continue;
        }

        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) continue;

        final pubName = data['pubName']?.toString() ?? '';
        final files = <PubMediaFile>[];
        final languagesBlock = data['files'];

        if (languagesBlock is Map) {
          languagesBlock.forEach((langKey, byFormat) {
            if (byFormat is Map) {
              byFormat.forEach((fmtKey, fileList) {
                if (fileList is List) {
                  for (final item in fileList) {
                    if (item is Map) {
                      files.add(PubMediaFile.fromApi(
                        langKey.toString(),
                        fmtKey.toString(),
                        Map<String, dynamic>.from(item),
                      ));
                    }
                  }
                }
              });
            }
          });
        }

        return PubMediaPublication(
          pubCode: pubCode,
          pubName: pubName,
          files: files,
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  /// Realiza o download de um arquivo com tracking de progresso e verificacao de integridade SHA-256
  Future<File> downloadFile({
    required PubMediaFile file,
    required File destinationFile,
    void Function(double progress)? onProgress,
    bool verifyChecksum = true,
  }) async {
    final parentDir = destinationFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final tempFile = File(p.normalize('${destinationFile.path}.download.tmp'));
    if (!await tempFile.parent.exists()) {
      await tempFile.parent.create(recursive: true);
    }
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final request = http.Request('GET', Uri.parse(file.url));
    request.headers['User-Agent'] = 'JWLibrary/14.3';

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw PubMediaException('Erro ao iniciar download: $e', uri: Uri.parse(file.url));
    }

    if (streamedResponse.statusCode != 200) {
      throw PubMediaException(
        'Falha no download (HTTP ${streamedResponse.statusCode})',
        uri: Uri.parse(file.url),
        statusCode: streamedResponse.statusCode,
      );
    }

    final totalBytes = streamedResponse.contentLength ?? file.sizeBytes;
    var receivedBytes = 0;
    final sink = tempFile.openWrite();

    try {
      await for (final chunk in streamedResponse.stream.timeout(const Duration(seconds: 30))) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw PubMediaException('Erro durante transferencia de bytes: $e', uri: Uri.parse(file.url));
    }

    // Verificacao rigorosa de integridade SHA-256
    if (verifyChecksum && file.checksum.isNotEmpty) {
      final downloadedBytes = await tempFile.readAsBytes();
      final calculatedSha256 = sha256.convert(downloadedBytes).toString().toLowerCase();
      final expectedSha256 = file.checksum.toLowerCase();

      if (calculatedSha256 != expectedSha256) {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        throw PubMediaChecksumException(
          expectedChecksum: expectedSha256,
          actualChecksum: calculatedSha256,
          filePath: destinationFile.path,
        );
      }
    }

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }
    await tempFile.rename(destinationFile.path);

    return destinationFile;
  }

  void close() {
    _client.close();
  }
}
