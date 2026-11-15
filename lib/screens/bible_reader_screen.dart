import 'package:flutter/material.dart';
import '../models/bible_model.dart';
import '../services/bible_service.dart';
import 'bible_languages_dialog.dart';

class BibleReaderScreen extends StatefulWidget {
  final BibleBook book;
  final int initialChapter;
  final BibleVersion version;
  final BibleService bibleService;
  final int? targetVerse;
  final int? targetEndVerse;

  const BibleReaderScreen({
    super.key,
    required this.book,
    required this.initialChapter,
    required this.version,
    required this.bibleService,
    this.targetVerse,
    this.targetEndVerse,
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  late int _currentChapter;
  late BibleVersion _currentVersion;
  final Map<int, GlobalKey> _verseKeys = {};
  BibleChapterContent? _content;
  bool _isLoading = true;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _currentVersion = widget.version;
    _loadChapterData();
  }

  Future<void> _loadChapterData() async {
    _verseKeys.clear();
    setState(() => _isLoading = true);
    try {
      final activeVersion = await widget.bibleService.getActiveVersion();
      final downloaded = await widget.bibleService.isVersionDownloaded(activeVersion.id);
      final content = await widget.bibleService.loadChapter(widget.book, _currentChapter);
      if (!mounted) return;
      setState(() {
        _currentVersion = activeVersion;
        _content = content;
        _isDownloaded = downloaded;
      });

      if (widget.targetVerse != null && _currentChapter == widget.initialChapter) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final targetKey = _verseKeys[widget.targetVerse];
          if (targetKey?.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Erro ao carregar capítulo: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToPreviousChapter() {
    if (_currentChapter > 1) {
      setState(() => _currentChapter--);
      _loadChapterData();
    }
  }

  void _goToNextChapter() {
    if (_currentChapter < widget.book.totalChapters) {
      setState(() => _currentChapter++);
      _loadChapterData();
    }
  }

  void _openStudySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.diamond, color: Color(0xFFB388FF), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Painel de Estudo - ${widget.book.name} $_currentChapter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notas de estudo, referências marginais e mapas multimídia oficiais.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (_content != null && _content!.footnotes.isNotEmpty) ...[
                  const Divider(color: Color(0xFF333333)),
                  const Text(
                    'Notas de Rodapé:',
                    style: TextStyle(color: Color(0xFFB388FF), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ..._content!.footnotes.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${entry.value}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                if (!_isDownloaded)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showDialog(
                        context: context,
                        builder: (_) => BibleLanguagesDialog(
                          bibleService: widget.bibleService,
                          onVersionChanged: () {
                            _loadChapterData();
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Baixar Versão Completa para Estudo Offline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.book.name} $_currentChapter',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentVersion.shortTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headphones, color: Colors.white),
            tooltip: 'Áudio',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Áudio em streaming oficial.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB388FF),
        foregroundColor: const Color(0xFF1A1A1A),
        onPressed: _openStudySheet,
        child: const Icon(Icons.diamond, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB388FF)))
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -300) {
                    _goToNextChapter();
                  } else if (details.primaryVelocity! > 300) {
                    _goToPreviousChapter();
                  }
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aviso se offline sem o pacote completo baixado
                    if (!_isDownloaded)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF232323),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF383838)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_download_outlined, color: Color(0xFFB388FF), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bíblia Completa Disponível',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Baixe os 66 livros da ${_currentVersion.shortTitle} para leitura rápida offline.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => BibleLanguagesDialog(
                                    bibleService: widget.bibleService,
                                    onVersionChanged: () {
                                      _loadChapterData();
                                    },
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFFB388FF)),
                              child: const Text('BAIXAR', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // Título em caixa alta do Livro
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        widget.book.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Versículos renderizados com realce visual inteligente
                    if (_content != null && _content!.verses.isNotEmpty)
                      ..._content!.verses.map((verse) {
                        final isTarget = widget.targetVerse != null &&
                            _currentChapter == widget.initialChapter &&
                            verse.verseNumber >= widget.targetVerse! &&
                            verse.verseNumber <= (widget.targetEndVerse ?? widget.targetVerse!);
                        final vKey = _verseKeys.putIfAbsent(verse.verseNumber, () => GlobalKey());

                        return Container(
                          key: vKey,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: isTarget
                              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                              : const EdgeInsets.symmetric(vertical: 4),
                          decoration: isTarget
                              ? BoxDecoration(
                                  color: const Color(0xFF64B5F6).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: const Border(
                                    left: BorderSide(color: Color(0xFF64B5F6), width: 3.5),
                                  ),
                                )
                              : null,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 19,
                                height: 1.5,
                                color: Color(0xFFE6E6E6),
                              ),
                              children: [
                                TextSpan(
                                  text: '${verse.verseNumber} ',
                                  style: TextStyle(
                                    color: verse.verseNumber == 1
                                        ? const Color(0xFF64B5F6)
                                        : const Color(0xFF4A88C5),
                                    fontSize: verse.verseNumber == 1 ? 26 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: verse.text,
                                  style: isTarget
                                      ? const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Capítulo não encontrado.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Navegação entre capítulos no rodapé
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentChapter > 1)
                          OutlinedButton.icon(
                            onPressed: _goToPreviousChapter,
                            icon: const Icon(Icons.arrow_back),
                            label: Text('Capítulo ${_currentChapter - 1}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        if (_currentChapter < widget.book.totalChapters)
                          ElevatedButton.icon(
                            onPressed: _goToNextChapter,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text('Capítulo ${_currentChapter + 1}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C2C2C),
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
