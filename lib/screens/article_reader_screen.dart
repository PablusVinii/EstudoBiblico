import 'package:flutter/gestures.dart';
import '../services/bible_service.dart';
import '../services/bible_citation_parser.dart';
import 'bible_reader_screen.dart';
import 'package:flutter/material.dart';
import '../models/user_highlight_model.dart';
import '../services/highlight_storage_service.dart';
import '../widgets/article_review_section.dart';
import '../widgets/explanation_sheet.dart';
import '../widgets/jw_text_selection_toolbar.dart';
import '../widgets/paragraph_answer_box.dart';
import '../widgets/article_illustration_box.dart';
import '../widgets/note_editor_dialog.dart';
import '../widgets/study_paragraph_text.dart';
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
  List<UserHighlight> _highlights = [];
  String _selectedText = '';

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
      final clean = _geminiService.sanitizeAnswer(p.userAnswer);
      p.userAnswer = clean;
      _controllers[p.number] = TextEditingController(text: clean);
    }
    for (final rq in widget.article.reviewQuestions) {
      final clean = _geminiService.sanitizeAnswer(rq.userAnswer);
      rq.userAnswer = clean;
      _reviewControllers[rq.index] = TextEditingController(text: clean);
    }
    _loadSavedData();
    _loadHighlights();
  }

  Future<void> _loadSavedData() async {
    final savedData = await StudyStorageService.loadArticleData(widget.article.id);

    for (final p in widget.article.paragraphs) {
      final pSaved = savedData[p.number];
      if (pSaved != null) {
        if (pSaved['answer'] != null && pSaved['answer']!.isNotEmpty) {
          final cleanAns = _geminiService.sanitizeAnswer(pSaved['answer']!);
          p.userAnswer = cleanAns;
          _controllers[p.number]?.text = cleanAns;
        }
        if (pSaved['keyPoint'] != null && pSaved['keyPoint']!.isNotEmpty) {
          p.highlightedKeyPoint = pSaved['keyPoint']!;
        }
        if (pSaved['directComment'] != null && pSaved['directComment']!.isNotEmpty) {
          p.directComment = _geminiService.sanitizeAnswer(pSaved['directComment']!);
        }
        if (pSaved['additionalComment'] != null && pSaved['additionalComment']!.isNotEmpty) {
          p.additionalComment = _geminiService.sanitizeAnswer(pSaved['additionalComment']!);
        }
      }
    }

    final savedReviews = await StudyStorageService.loadReviewAnswers(widget.article.id);
    for (final rq in widget.article.reviewQuestions) {
      final savedAns = savedReviews[rq.index];
      if (savedAns != null && savedAns.isNotEmpty) {
        final cleanReview = _geminiService.sanitizeAnswer(savedAns);
        rq.userAnswer = cleanReview;
        _reviewControllers[rq.index]?.text = cleanReview;
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

  Future<void> _loadHighlights() async {
    final refKey = 'sentinela_${widget.article.id}';
    final list = await HighlightStorageService.loadHighlights(
      sourceType: 'sentinela',
      referenceKey: refKey,
    );
    if (!mounted) return;
    setState(() => _highlights = list);
  }

  void _handleHighlightText(int colorIndex, String selectedText) async {
    final clean = selectedText.trim();
    if (clean.isEmpty) return;

    int targetParagraphNum = 1;
    int startOffset = 0;
    for (final p in widget.article.paragraphs) {
      final idx = p.text.indexOf(clean);
      if (idx != -1) {
        targetParagraphNum = p.number;
        startOffset = idx;
        break;
      }
    }

    final newHl = UserHighlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceType: 'sentinela',
      referenceKey: 'sentinela_${widget.article.id}',
      blockIndex: targetParagraphNum,
      startOffset: startOffset,
      endOffset: startOffset + clean.length,
      colorIndex: colorIndex,
      selectedText: clean,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await HighlightStorageService.saveHighlight(newHl);
    await _loadHighlights();
  }

  void _handleDeleteHighlight(String selectedText) async {
    final clean = selectedText.trim();
    final target = _highlights.firstWhere(
      (h) => h.selectedText.contains(clean) || clean.contains(h.selectedText),
      orElse: () => UserHighlight(
        id: '',
        sourceType: 'sentinela',
        referenceKey: '',
        blockIndex: 0,
        startOffset: 0,
        endOffset: 0,
        colorIndex: 1,
        selectedText: '',
        updatedAt: '',
      ),
    );

    if (target.id.isNotEmpty) {
      await HighlightStorageService.deleteHighlight(
        target.id,
        sourceType: 'sentinela',
        referenceKey: 'sentinela_${widget.article.id}',
      );
      await _loadHighlights();
    }
  }

  void _handleExplainSelection(String selectedText) {
    String contextText = '';
    for (final p in widget.article.paragraphs) {
      if (p.text.contains(selectedText.trim())) {
        contextText = 'Artigo: ${widget.article.title} — Parágrafo ${p.number}: ${p.text}';
        break;
      }
    }
    if (contextText.isEmpty) {
      contextText = 'Artigo: ${widget.article.title} — $selectedText';
    }

    ExplanationSheet.show(
      context,
      selectedText: selectedText.trim(),
      contextText: contextText,
    );
  }

  void _handleAddNote(String selectedText) {
    final clean = selectedText.trim();
    final target = _highlights.firstWhere(
      (h) => h.selectedText.contains(clean) || clean.contains(h.selectedText),
      orElse: () => UserHighlight(
        id: '',
        sourceType: 'sentinela',
        referenceKey: '',
        blockIndex: 0,
        startOffset: 0,
        endOffset: 0,
        colorIndex: 1,
        selectedText: '',
        updatedAt: '',
      ),
    );

    NoteEditorDialog.show(
      context: context,
      selectedText: clean,
      initialNote: target.noteText,
      onSave: (note) async {
        if (target.id.isNotEmpty) {
          await HighlightStorageService.updateHighlightNote(
            target.id,
            note,
            sourceType: 'sentinela',
            referenceKey: 'sentinela_${widget.article.id}',
          );
        } else {
          int targetParagraphNum = 1;
          for (final p in widget.article.paragraphs) {
            if (p.text.contains(clean)) {
              targetParagraphNum = p.number;
              break;
            }
          }
          final newHl = UserHighlight(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sourceType: 'sentinela',
            referenceKey: 'sentinela_${widget.article.id}',
            blockIndex: targetParagraphNum,
            startOffset: 0,
            endOffset: clean.length,
            colorIndex: 1,
            selectedText: clean,
            noteText: note.isNotEmpty ? note : null,
            updatedAt: DateTime.now().toIso8601String(),
          );
          await HighlightStorageService.saveHighlight(newHl);
        }
        await _loadHighlights();
      },
    );
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
        paragraph.directComment = result.directComment;
        paragraph.additionalComment = result.additionalComment;
        _controllers[paragraph.number]?.text = result.answer;
      });

      // Salva persistentemente
      await StudyStorageService.saveParagraphData(
        articleId: widget.article.id,
        paragraphNumber: paragraph.number,
        answer: result.answer,
        keyPoint: result.keyPoint,
        directComment: result.directComment,
        additionalComment: result.additionalComment,
      );

      // Salva no cache do Gemini (Skill cost-aware-llm-pipeline)
      await StudyStorageService.saveAiCommentCache(
        articleId: widget.article.id,
        paragraphNumber: paragraph.number,
        answer: result.answer,
        keyPoint: result.keyPoint,
        directComment: result.directComment,
        additionalComment: result.additionalComment,
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
      body: SelectionArea(
        onSelectionChanged: (content) => _selectedText = content?.plainText ?? '',
        contextMenuBuilder: (context, selectableRegionState) {
          return JwTextSelectionToolbar(
            selectableRegionState: selectableRegionState,
            selectedText: _selectedText,
            onColorSelected: _handleHighlightText,
            onDeleteHighlight: _handleDeleteHighlight,
            onExplainWithAi: _handleExplainSelection,
            onAddNote: _handleAddNote,
          );
        },
        child: ListView(
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
                      children: StudyParagraphText.formatTextWithScriptures(
                        text: widget.article.themeScripture!,
                        onOpenScripture: _openScripture,
                        scriptureRecognizers: _scriptureRecognizers,
                      ),
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
            child: StudyParagraphText(
              paragraph: p,
              highlights: _highlights,
              onOpenScripture: _openScripture,
              scriptureRecognizers: _scriptureRecognizers,
            ),
          ),
        );

        // Ilustração interna associada a este parágrafo
        if (p.illustrationPath != null) {
          widgets.add(ArticleIllustrationBox(
            path: p.illustrationPath!,
            caption: p.illustrationCaption,
          ));
        }

        i++;
      }
    }

    return widgets;
  }

  Widget _buildAnswerBox(StudyParagraph paragraph) {
    return ParagraphAnswerBox(
      articleId: widget.article.id,
      paragraph: paragraph,
      controller: _controllers[paragraph.number],
      onGenerate: () => _handleGenerateAnswer(paragraph),
      onAnswerChanged: (val) {
        paragraph.userAnswer = val;
        StudyStorageService.saveParagraphData(
          articleId: widget.article.id,
          paragraphNumber: paragraph.number,
          answer: val,
          keyPoint: paragraph.highlightedKeyPoint,
          directComment: paragraph.directComment,
          additionalComment: paragraph.additionalComment,
        );
      },
      onSelectComment: (text) {
        setState(() {
          paragraph.userAnswer = text;
          _controllers[paragraph.number]?.text = text;
        });
        StudyStorageService.saveParagraphData(
          articleId: widget.article.id,
          paragraphNumber: paragraph.number,
          answer: text,
          keyPoint: paragraph.highlightedKeyPoint,
          directComment: paragraph.directComment,
          additionalComment: paragraph.additionalComment,
        );
      },
    );
  }

  Widget _buildReviewSection() {
    return ArticleReviewSection(
      article: widget.article,
      reviewControllers: _reviewControllers,
      onGenerateReviewAnswer: (q) => _handleGenerateReviewAnswer(q),
      onSaveReviewAnswer: (index, val) {
        for (final q in widget.article.reviewQuestions) {
          if (q.index == index) {
            q.userAnswer = val;
            break;
          }
        }
        StudyStorageService.saveReviewAnswer(
          articleId: widget.article.id,
          questionIndex: index,
          answer: val,
        );
      },
    );
  }
}
