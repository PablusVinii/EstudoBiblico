import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela_study/services/gemini_service.dart';

void main() {
  group('GeminiService Greeting and Presentation Stripping Tests', () {
    final service = GeminiService();

    test('strips "Olá, irmãos!" greeting and preserves content', () {
      const input = 'Olá, irmãos! Analisando as razões pelas quais as pessoas seguem leis e regras, vemos que muitas vezes isso acontece apenas por aparência.';
      final result = service.sanitizeAnswer(input);
      expect(result, startsWith('Analisando as razões'));
      expect(result.contains('Olá'), isFalse);
      expect(result.contains('irmãos'), isFalse);
    });

    test('strips "Irmãos," vocative and capitalizes the following word', () {
      const input = 'Irmãos, a simplicidade que Jesus escolheu para o Memorial nos ensina muito sobre ele.';
      final result = service.sanitizeAnswer(input);
      expect(result, equals('A simplicidade que Jesus escolheu para o Memorial nos ensina muito sobre ele.'));
    });

    test('strips "Queridos irmãos," and "Bom dia, irmãos!"', () {
      expect(
        service.sanitizeAnswer('Queridos irmãos, devemos sempre confiar em Jeová.'),
        equals('Devemos sempre confiar em Jeová.'),
      );
      expect(
        service.sanitizeAnswer('Bom dia, irmãos! Jeová nos ama muito.'),
        equals('Jeová nos ama muito.'),
      );
      expect(
        service.sanitizeAnswer('Olá a todos! Jeová nos ama.'),
        equals('Jeová nos ama.'),
      );
    });

    test('strips greetings in sub-answers (a), (b) and (c)', () {
      const input = '''(a) Olá, irmãos! A primeira razão é o amor a Deus.

(b) Irmãos, a segunda razão é a gratidão pelo resgate.''';

      final result = service.sanitizeAnswer(input);
      expect(result, contains('(a) A primeira razão é o amor a Deus.'));
      expect(result, contains('(b) A segunda razão é a gratidão pelo resgate.'));
      expect(result.contains('Olá'), isFalse);
      expect(result.contains('Irmãos,'), isFalse);
    });

    test('does not strip non-vocative uses of "irmãos"', () {
      const input = 'Os irmãos na congregação demonstram amor mútuo através de boas ações.';
      final result = service.sanitizeAnswer(input);
      expect(result, equals('Os irmãos na congregação demonstram amor mútuo através de boas ações.'));
    });

    test('does not corrupt words starting with "Oi" (Oito, Oitenta, Oitavo)', () {
      const input1 = 'Oito testemunhas viram que o túmulo estava vazio.';
      expect(service.sanitizeAnswer(input1), equals('Oito testemunhas viram que o túmulo estava vazio.'));

      const input2 = 'Oitenta anos se passaram desde então.';
      expect(service.sanitizeAnswer(input2), equals('Oitenta anos se passaram desde então.'));
    });

    test('does not corrupt biblical phrases like "A paz de Deus"', () {
      const input = 'A paz de Deus nos protege contra a ansiedade.';
      expect(service.sanitizeAnswer(input), equals('A paz de Deus nos protege contra a ansiedade.'));
    });

    test('preserves preamble before sub-answers (a) and (b)', () {
      const input = 'Podemos aprender duas lições: (a) a primeira é o amor; (b) a segunda é a fé.';
      final result = service.sanitizeAnswer(input);
      expect(result, contains('Podemos aprender duas lições:'));
      expect(result, contains('(a) A primeira é o amor;'));
      expect(result, contains('(b) A segunda é a fé.'));
    });

    test('handles inline citations like "A alínea (a) diz que devemos orar"', () {
      const input = 'A alínea (a) diz que devemos orar.';
      expect(service.sanitizeAnswer(input), equals('A alínea (a) diz que devemos orar.'));
    });

    test('correctly parses JSON with greetings and removes them', () {
      const json = '''{
        "answer": "Olá, irmãos! Este parágrafo nos ensina a ser humildes.",
        "keyPoint": "Este é o ponto chave"
      }''';
      final parsed = service.parseModelResponse(json);
      expect(parsed.answer, equals('Este parágrafo nos ensina a ser humildes.'));
      expect(parsed.keyPoint, equals('Este é o ponto chave'));
      expect(parsed.directComment, isNull);
      expect(parsed.additionalComment, isNull);
    });

    test('parses and sanitizes dual comments from jw-meeting-prep schema', () {
      const json = '''{
        "answer": "Jesus mostrou humildade ao lavar os pés dos discípulos.",
        "directComment": "Olá, irmãos! Jesus foi humilde e não buscou glória para si.",
        "additionalComment": "Queridos irmãos, Filipenses 2:5-8 destaca que Jesus abriu mão de sua posição celestial.",
        "keyPoint": "Jesus mostrou humildade"
      }''';
      final parsed = service.parseModelResponse(json);
      expect(parsed.answer, equals('Jesus mostrou humildade ao lavar os pés dos discípulos.'));
      expect(parsed.directComment, equals('Jesus foi humilde e não buscou glória para si.'));
      expect(parsed.additionalComment, equals('Filipenses 2:5-8 destaca que Jesus abriu mão de sua posição celestial.'));
      expect(parsed.keyPoint, equals('Jesus mostrou humildade'));
    });
    test('strips multiple sequential greetings and quotes/markdown', () {
      const input1 = '"Olá, irmãos! Analisando as razões..."';
      expect(service.sanitizeAnswer(input1), equals('Analisando as razões...'));

      const input2 = '**Irmãos,** Jesus nos deu o melhor exemplo.';
      expect(service.sanitizeAnswer(input2), equals('Jesus nos deu o melhor exemplo.'));

      const input3 = 'Olá! Irmãos, bom dia a todos! Analisando o parágrafo...';
      expect(service.sanitizeAnswer(input3), equals('Analisando o parágrafo...'));
    });

    test('strips parenthetical mid-sentence vocatives like ", irmãos,"', () {
      const input = 'Devemos sempre lembrar, irmãos, que Jeová é o nosso Refúgio.';
      expect(service.sanitizeAnswer(input), equals('Devemos sempre lembrar, que Jeová é o nosso Refúgio.'));
    });
  });
}

