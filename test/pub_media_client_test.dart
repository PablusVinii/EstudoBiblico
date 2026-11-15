import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinela_study/services/pub_media_client.dart';

void main() {
  group('PubMediaFile and PubMediaPublication Models', () {
    test('PubMediaFile.fromApi correctly parses API JSON payload', () {
      final json = {
        'title': 'A Sentinela (Edição de Estudo)',
        'filesize': 3650000,
        'booknum': 0,
        'track': 1,
        'file': {
          'url': 'https://cfp2.jw-cdn.org/a/e72d878/2/o/w_T_202601.jwpub',
          'checksum': '2350ef125c156f0e4b77f1947ebaa61c5c56784d5df68b577317781b0a85c07b',
          'mimetype': 'application/octet-stream',
        }
      };

      final file = PubMediaFile.fromApi('T', 'JWPUB', json);

      expect(file.url, equals('https://cfp2.jw-cdn.org/a/e72d878/2/o/w_T_202601.jwpub'));
      expect(file.filename, equals('w_T_202601.jwpub'));
      expect(file.fileFormat, equals('JWPUB'));
      expect(file.language, equals('T'));
      expect(file.sizeBytes, equals(3650000));
      expect(file.checksum, equals('2350ef125c156f0e4b77f1947ebaa61c5c56784d5df68b577317781b0a85c07b'));
      expect(file.track, equals(1));
    });

    test('PubMediaPublication preferredFile prioritizes JWPUB over EPUB', () {
      final jwpubFile = PubMediaFile(
        url: 'https://example.com/w_T.jwpub',
        filename: 'w_T.jwpub',
        title: 'A Sentinela JWPUB',
        language: 'T',
        fileFormat: 'JWPUB',
        sizeBytes: 3000000,
      );

      final epubFile = PubMediaFile(
        url: 'https://example.com/w_T.epub',
        filename: 'w_T.epub',
        title: 'A Sentinela EPUB',
        language: 'T',
        fileFormat: 'EPUB',
        sizeBytes: 3500000,
      );

      final pub = PubMediaPublication(
        pubCode: 'w',
        pubName: 'A Sentinela',
        files: [epubFile, jwpubFile],
      );

      expect(pub.filesByFormat('JWPUB').length, equals(1));
      expect(pub.filesByFormat('EPUB').length, equals(1));

      final preferred = pub.preferredFile(preferredLanguage: 'T');
      expect(preferred, isNotNull);
      expect(preferred!.fileFormat, equals('JWPUB'));
      expect(preferred.url, equals('https://example.com/w_T.jwpub'));
    });

    test('PubMediaPublication falls back to EPUB when JWPUB is unavailable', () {
      final epubFile = PubMediaFile(
        url: 'https://example.com/bi12_T.epub',
        filename: 'bi12_T.epub',
        title: 'Bíblia com Referências',
        language: 'T',
        fileFormat: 'EPUB',
        sizeBytes: 14000000,
      );

      final pub = PubMediaPublication(
        pubCode: 'bi12',
        pubName: 'Bíblia com Referências',
        files: [epubFile],
      );

      final preferred = pub.preferredFile(preferredLanguage: 'T');
      expect(preferred, isNotNull);
      expect(preferred!.fileFormat, equals('EPUB'));
      expect(preferred.url, equals('https://example.com/bi12_T.epub'));
    });
  });

  group('PubMediaClient Network and Download Verification', () {
    test('getPublication queries API and maps files correctly', () async {
      final mockResponse = jsonEncode({
        'pubName': 'Tradução do Novo Mundo',
        'files': {
          'T': {
            'JWPUB': [
              {
                'title': 'Bíblia JWPUB',
                'filesize': 120000000,
                'file': {
                  'url': 'https://cfp2.jw-cdn.org/nwtsty_T.jwpub',
                  'checksum': 'abcdef123456',
                }
              }
            ],
            'EPUB': [
              {
                'title': 'Bíblia EPUB',
                'filesize': 15000000,
                'file': {
                  'url': 'https://cfp2.jw-cdn.org/nwt_T.epub',
                  'checksum': '987654fedcba',
                }
              }
            ]
          }
        }
      });

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('GETPUBMEDIALINKS'));
        expect(request.url.queryParameters['pub'], equals('nwtsty'));
        expect(request.url.queryParameters['langwritten'], equals('T'));
        return http.Response(mockResponse, 200);
      });

      final client = PubMediaClient(client: mockClient);
      final pub = await client.getPublication(pubCode: 'nwtsty', language: 'T');

      expect(pub, isNotNull);
      expect(pub!.pubCode, equals('nwtsty'));
      expect(pub.pubName, equals('Tradução do Novo Mundo'));
      expect(pub.files.length, equals(2));

      final preferred = pub.preferredFile();
      expect(preferred, isNotNull);
      expect(preferred!.fileFormat, equals('JWPUB'));
      expect(preferred.url, equals('https://cfp2.jw-cdn.org/nwtsty_T.jwpub'));
    });

    test('downloadFile validates SHA-256 integrity when matching checksum', () async {
      final contentBytes = utf8.encode('Conteúdo legítimo de teste da Sentinela');
      final validChecksum = sha256.convert(contentBytes).toString();

      final mockClient = MockClient((request) async {
        return http.Response.bytes(contentBytes, 200);
      });

      final client = PubMediaClient(client: mockClient);
      final tempDir = await Directory.systemTemp.createTemp('pubmedia_test_');
      final destFile = File('${tempDir.path}/test_download.jwpub');

      final mediaFile = PubMediaFile(
        url: 'https://example.com/test.jwpub',
        filename: 'test.jwpub',
        title: 'Test',
        language: 'T',
        fileFormat: 'JWPUB',
        sizeBytes: contentBytes.length,
        checksum: validChecksum,
      );

      double reportedProgress = 0.0;
      final savedFile = await client.downloadFile(
        file: mediaFile,
        destinationFile: destFile,
        onProgress: (p) => reportedProgress = p,
        verifyChecksum: true,
      );

      expect(savedFile.existsSync(), isTrue);
      expect(reportedProgress, equals(1.0));
      expect(await savedFile.readAsString(), equals('Conteúdo legítimo de teste da Sentinela'));

      await tempDir.delete(recursive: true);
    });

    test('downloadFile throws PubMediaChecksumException and deletes temp file on checksum mismatch', () async {
      final contentBytes = utf8.encode('Conteúdo corrompido ou adulterado');
      const expectedOriginalChecksum = '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff';

      final mockClient = MockClient((request) async {
        return http.Response.bytes(contentBytes, 200);
      });

      final client = PubMediaClient(client: mockClient);
      final tempDir = await Directory.systemTemp.createTemp('pubmedia_test_');
      final destFile = File('${tempDir.path}/test_corrupted.jwpub');

      final mediaFile = PubMediaFile(
        url: 'https://example.com/corrupted.jwpub',
        filename: 'corrupted.jwpub',
        title: 'Corrupted',
        language: 'T',
        fileFormat: 'JWPUB',
        sizeBytes: contentBytes.length,
        checksum: expectedOriginalChecksum,
      );

      await expectLater(
        client.downloadFile(
          file: mediaFile,
          destinationFile: destFile,
          verifyChecksum: true,
        ),
        throwsA(isA<PubMediaChecksumException>()),
      );

      expect(destFile.existsSync(), isFalse);
      expect(File('${destFile.path}.download.tmp').existsSync(), isFalse);

      await tempDir.delete(recursive: true);
    });
  });
}
