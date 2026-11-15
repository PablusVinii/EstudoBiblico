import 'package:flutter/gestures.dart';
import '../services/bible_service.dart';
import '../services/bible_citation_parser.dart';
import 'bible_reader_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/gemini_service.dart';
import '../services/study_storage_service.dart';
import 'settings_screen.dart';

class ArticleReaderScreen extends StatefulWidget {
  final StudyArticle article;

  const ArticleReaderScreen({super.key, required this.article});

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  final _geminiService = GeminiService();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _reviewControllers = {};
  final List<TapGestureRecognizer> _scriptureRecognizers = [];

  void _clearScriptureRecognizers() {
    for (final r in _scriptureRecognizers) {
      r.dispose();
    }
    _scriptureRecognizers.clear();
  }

  void _openScripture(String citation) async {
    final parsed = BibleCitationParser.parse(citation);
    if (parsed == null) return;

    final bibleService = BibleService();
    final activeVersion = await bibleService.getActiveVersion();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReaderScreen(
          book: parsed.book,
          initialChapter: parsed.chapter,
          version: activeVersion,
          bibleService: bibleService,
          targetVerse: parsed.startVerse,
          targetEndVerse: parsed.endVerse,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    for (final p in widget.article.paragraphs) {
      _controllers[p.number] = TextEditingController(text: p.userAnswer);
    }
    for (final rq in widget.article.reviewQuestions) {
      _reviewControllers[rq.index] = TextEditingController(text: rq.userAnswer);
    }
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final savedData = await StudyStorageService.loadArticleData(widget.article.id);

    for (final p in widget.article.paragraphs) {
      final pSaved = savedData[p.number];
      if (pSaved != null) {
        if (pSaved['answer'] != null && pSaved['answer']!.isNotEmpty) {
          p.userAnswer = pSaved['answer']!;
          _controllers[p.number]?.text = p.userAnswer;
        }
        if (pSaved['keyPoint'] != null && pSaved['keyPoint']!.isNotEmpty) {
          p.highlightedKeyPoint = pSaved['keyPoint']!;
        }
      }
    }

    final savedReviews = await StudyStorageService.loadReviewAnswers(widget.article.id);
    for (final rq in widget.article.reviewQuestions) {
      final savedAns = savedReviews[rq.index];
      if (savedAns != null && savedAns.isNotEmpty) {
        rq.userAnswer = savedAns;
        _reviewControllers[rq.index]?.text = savedAns;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clearScriptureRecognizers();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in _reviewControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleGenerateAnswer(StudyParagraph paragraph) async {
    final question = paragraph.question;
    if (question == null || question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este parágrafo não possui pergunta associada.')),
      );
      return;
    }

    setState(() {
      paragraph.isGenerating = true;
    });

    try {
      // Agrupa todos os parágrafos cobertos por esta pergunta
      final paragraphsForQuestion = widget.article.paragraphs
          .where((p) => p.question == paragraph.question)
          .toList();

      final fullContext = paragraphsForQuestion.isNotEmpty
          ? paragraphsForQuestion.map((p) => '${p.number}. ${p.text}').join('\n\n')
          : paragraph.text;

      final result = await _geminiService.generateAnswer(
        paragraphText: fullContext,
        questionText: question,
      );

      if (!mounted) return;
      setState(() {
        paragraph.userAnswer = result.answer;
        paragraph.highlightedKeyPoint = result.keyPoint;
        _controllers[paragraph.number]?.text = result.answer;
      });

      // Salva persistentemente
      await StudyStorageService.saveParagraphData(
        articleId: widget.article.id,
        paragraphNumber: paragraph.number,
        answer: result.answer,
        keyPoint: result.keyPoint,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            content: Text(
              'Erro ao gerar resposta: ${e.toString().replaceAll('Exception: ', '')}',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            action: SnackBarAction(
              label: 'CONFIGURAR',
              textColor: Colors.yellowAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          paragraph.isGenerating = false;
        });
      }
    }
  }

  Future<void> _handleGenerateReviewAnswer(ReviewQuestion reviewQ) async {
    setState(() {
      reviewQ.isGenerating = true;
    });

    try {
      final fullArticleText = widget.article.paragraphs
          .map((p) => '${p.number}. ${p.text}')
          .join('\n\n');

      final answer = await _geminiService.generateReviewAnswer(
        articleTitle: widget.article.title,
        fullArticleText: fullArticleText,
        questionText: reviewQ.question,
      );

      if (!mounted) return;
      setState(() {
        reviewQ.userAnswer = answer;
        _reviewControllers[reviewQ.index]?.text = answer;
      });

      await StudyStorageService.saveReviewAnswer(
        articleId: widget.article.id,
        questionIndex: reviewQ.index,
        answer: answer,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            content: Text(
              'Erro ao gerar resposta: ${e.toString().replaceAll('Exception: ', '')}',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            action: SnackBarAction(
              label: 'CONFIGURAR',
              textColor: Colors.yellowAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          reviewQ.isGenerating = false;
        });
      }
    }
  }

  static String _toSuperscript(int number) {
    const superscripts = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };
    return number.toString().split('').map((d) => superscripts[d] ?? d).join();
  }

  Widget _buildParagraphText(StudyParagraph paragraph) {
    final fullText = paragraph.text;
    final numPrefix = '${_toSuperscript(paragraph.number)} ';
    final keyPoint = paragraph.highlightedKeyPoint;

    if (keyPoint == null || keyPoint.trim().isEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: numPrefix,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8AB4F8),
              ),
            ),
            ..._formatTextWithScriptures(fullText),
          ],
        ),
        style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
      );
    }

    final String cleanKey = keyPoint.trim().replaceAll(RegExp(r'^[^\wÀ-ÿ]+|[^\wÀ-ÿ]+$'), '');

    int matchIndex = fullText.indexOf(cleanKey);
    int matchLength = cleanKey.length;

    // Busca insensível a maiúsculas e minúsculas diretamente no fullText
    if (matchIndex == -1) {
      final lowerFull = fullText.toLowerCase();
      final lowerKey = cleanKey.toLowerCase();
      matchIndex = lowerFull.indexOf(lowerKey);
      if (matchIndex != -1) {
        matchLength = cleanKey.length;
      }
    }

    // Busca com expressão regular flexível para variações de espaçamento/pontuação diretamente no fullText
    if (matchIndex == -1 && cleanKey.isNotEmpty) {
      try {
        final escapedKey = RegExp.escape(cleanKey).replaceAll(RegExp(r'\\s+'), r'\s+');
        final regExp = RegExp(escapedKey, caseSensitive: false);
        final m = regExp.firstMatch(fullText);
        if (m != null) {
          matchIndex = m.start;
          matchLength = m.end - m.start;
        }
      } catch (_) {}
    }

    // Se ainda não encontrou e a chave for longa, busca por trechos/cláusulas
    if (matchIndex == -1 && cleanKey.length > 20) {
      final parts = cleanKey.split(RegExp(r'[,;]'));
      for (final part in parts) {
        final pClean = part.trim();
        if (pClean.length > 15) {
          final idx = fullText.toLowerCase().indexOf(pClean.toLowerCase());
          if (idx != -1) {
            matchIndex = idx;
            matchLength = pClean.length;
            break;
          }
        }
      }
    }

    if (matchIndex == -1) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: numPrefix,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8AB4F8),
              ),
            ),
            ..._formatTextWithScriptures(fullText),
          ],
        ),
        style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
      );
    }

    final before = fullText.substring(0, matchIndex);
    final match = fullText.substring(matchIndex, (matchIndex + matchLength).clamp(0, fullText.length));
    final after = fullText.substring((matchIndex + matchLength).clamp(0, fullText.length));

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: numPrefix,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF8AB4F8),
            ),
          ),
          ..._formatTextWithScriptures(before),
          ..._formatTextWithScriptures(match, isHighlighted: true),
          ..._formatTextWithScriptures(after),
        ],
      ),
      style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
    );
  }

  List<InlineSpan> _formatTextWithScriptures(String text, {bool isHighlighted = false}) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    final defaultTextStyle = isHighlighted
        ? const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            backgroundColor: Color(0x59FFD54F),
          )
        : null;

    for (final m in BibleCitationParser.citationRegex.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: defaultTextStyle,
        ));
      }

      final matchedText = text.substring(m.start, m.end);
      final parsed = BibleCitationParser.parse(matchedText);

      if (parsed != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _openScripture(matchedText);
        _scriptureRecognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: matchedText,
            style: TextStyle(
              color: isHighlighted ? const Color(0xFF90CAF9) : const Color(0xFF8AB4F8),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: isHighlighted ? const Color(0xFF90CAF9) : const Color(0x668AB4F8),
              backgroundColor: isHighlighted ? const Color(0x59FFD54F) : null,
            ),
            recognizer: recognizer,
          ),
        );
      } else {
        spans.add(TextSpan(
          text: matchedText,
          style: defaultTextStyle,
        ));
      }
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultTextStyle,
      ));
    }

    return spans;
  }

  Widget _buildIllustration(String path, String? caption) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFCCCCCC),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2.5,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _clearScriptureRecognizers();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Preto puro AMOLED idêntico ao original
        appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (widget.article.weekDate != null)
              Text(
                widget.article.weekDate!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.zero,
        children: [
          // 1. Faixa Laranja Oficial com a Data do Estudo
          if (widget.article.weekDate != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFE65100),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.article.weekDate!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Cântico de Abertura
                if (widget.article.song != null) ...[
                  Text(
                    widget.article.song!,
                    style: const TextStyle(
                      color: Color(0xFF689FBD),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 3. Título do Artigo em Ciano
                Text(
                  widget.article.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF90CAF9),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Texto Temático em Itálico
                if (widget.article.themeScripture != null) ...[
                  Text.rich(
                    TextSpan(
                      children: _formatTextWithScriptures(widget.article.themeScripture!),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFB0BEC5),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 5. Bloco de OBJETIVO com barra lateral laranja
                if (widget.article.objective != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      border: Border(
                        left: BorderSide(color: Color(0xFFE65100), width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OBJETIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.article.objective!,
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 6. Lista Estruturada de Parágrafos de Estudo e Ilustrações
                ..._buildStudyItems(),

                // 7. Seção COMO RESPONDERIA? e Cântico Final
                if (widget.article.reviewQuestions.isNotEmpty || widget.article.closingSong != null)
                  _buildReviewSection(),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}

  List<Widget> _buildStudyItems() {
    final widgets = <Widget>[];

    // Agrupa parágrafos por pergunta
    final paragraphs = widget.article.paragraphs;
    int i = 0;

    while (i < paragraphs.length) {
      final currentPara = paragraphs[i];

      // Subtítulo de Seção
      if (currentPara.headingBefore != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 12),
            child: Text(
              currentPara.headingBefore!.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF90CAF9),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }

      final groupQuestion = currentPara.question;

      // 1. Renderiza a pergunta oficial no topo do grupo
      if (groupQuestion != null && groupQuestion.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              groupQuestion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        );

        // 2. O box de texto e botão de gerar resposta fica IMEDIATAMENTE ABAIXO da pergunta
        widgets.add(const SizedBox(height: 4));
        widgets.add(_buildAnswerBox(currentPara));
        widgets.add(const SizedBox(height: 12));
      }

      // 3. Renderiza todos os parágrafos que pertencem a este grupo de pergunta
      while (i < paragraphs.length && paragraphs[i].question == groupQuestion) {
        final p = paragraphs[i];

        // Texto do Parágrafo com número sobrescrito
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _buildParagraphText(p),
          ),
        );

        // Ilustração interna associada a este parágrafo
        if (p.illustrationPath != null) {
          widgets.add(_buildIllustration(p.illustrationPath!, p.illustrationCaption));
        }

        i++;
      }
    }

    return widgets;
  }

  Widget _buildAnswerBox(StudyParagraph paragraph) {
    final ctrl = _controllers[paragraph.number];
    final isGenerating = paragraph.isGenerating;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        children: [
          TextField(
            controller: ctrl,
            maxLines: null,
            minLines: 2,
            style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
            decoration: const InputDecoration(
              hintText: 'Escreva seu comentário...',
              hintStyle: TextStyle(color: Color(0xFF757575)),
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
            onChanged: (val) {
              paragraph.userAnswer = val;
              StudyStorageService.saveParagraphData(
                articleId: widget.article.id,
                paragraphNumber: paragraph.number,
                answer: val,
                keyPoint: paragraph.highlightedKeyPoint,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8, left: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isGenerating)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Gerando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _handleGenerateAnswer(paragraph),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            (ctrl?.text.trim().isNotEmpty ?? false) ? 'Regenerar' : 'Gerar Resposta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.article.reviewQuestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2C2C2C), thickness: 1, height: 32),
          const SizedBox(height: 8),
          const Text(
            'COMO RESPONDERIA?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.article.reviewQuestions.map((q) => _buildReviewQuestionItem(q)),
        ],

        if (widget.article.closingSong != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.article.closingSong!,
            style: const TextStyle(
              color: Color(0xFF689FBD),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2C2C2C), thickness: 1, height: 24),
        ],
      ],
    );
  }

  Widget _buildReviewQuestionItem(ReviewQuestion q) {
    final ctrl = _reviewControllers[q.index];
    final isGenerating = q.isGenerating;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ${q.question}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: null,
                  minLines: 2,
                  style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Escreva sua resposta...',
                    hintStyle: TextStyle(color: Color(0xFF757575)),
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    q.userAnswer = val;
                    StudyStorageService.saveReviewAnswer(
                      articleId: widget.article.id,
                      questionIndex: q.index,
                      answer: val,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8, left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isGenerating)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Gerando...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _handleGenerateReviewAnswer(q),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  (ctrl?.text.trim().isNotEmpty ?? false) ? 'Regenerar' : 'Gerar Resposta',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
