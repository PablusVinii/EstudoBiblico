import 'package:flutter/material.dart';
import '../models/bible_model.dart';
import '../services/bible_service.dart';
import '../services/bible_content_catalog.dart';
import '../services/bible_citation_parser.dart';
import 'bible_chapters_screen.dart';
import 'bible_reader_screen.dart';
import 'bible_languages_dialog.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final _bibleService = BibleService();
  final _indexSearchController = TextEditingController();
  BibleVersion? _activeVersion;
  bool _isLoading = true;
  String _indexSearchQuery = '';
  String _selectedAppendixCategory = 'appendix_a';

  @override
  void initState() {
    super.initState();
    _loadActiveVersion();
    _indexSearchController.addListener(() {
      setState(() {
        _indexSearchQuery = _indexSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _indexSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveVersion() async {
    final v = await _bibleService.getActiveVersion();
    if (!mounted) return;
    setState(() {
      _activeVersion = v;
      _isLoading = false;
    });
  }

  void _openLanguagesDialog() {
    showDialog(
      context: context,
      builder: (_) => BibleLanguagesDialog(
        bibleService: _bibleService,
        onVersionChanged: () {
          _loadActiveVersion();
        },
      ),
    );
  }

  void _openArticleSheet(BibleArticleDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                doc.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                doc.subtitle,
                style: const TextStyle(
                  color: Color(0xFFB388FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(color: Color(0xFF333333), height: 24),
              Text(
                doc.content,
                style: const TextStyle(
                  color: Color(0xFFD6D6D6),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _openScriptureRef(String citation) {
    final parsed = BibleCitationParser.parse(citation);
    if (parsed == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReaderScreen(
          book: parsed.book,
          initialChapter: parsed.chapter,
          version: _activeVersion!,
          bibleService: _bibleService,
          targetVerse: parsed.startVerse,
          targetEndVerse: parsed.endVerse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _activeVersion == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB388FF))),
      );
    }

    final hebrewBooks = BibleService.books.where((b) => b.isHebrew).toList();
    final greekBooks = BibleService.books.where((b) => !b.isHebrew).toList();

    return DefaultTabController(
      length: 4,
      initialIndex: 1, // 'LIVROS' é a aba ativa padrão
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          titleSpacing: 16,
          title: InkWell(
            onTap: _openLanguagesDialog,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeVersion!.shortTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _activeVersion!.languageName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Color(0xFFB388FF),
            indicatorWeight: 3,
            labelColor: Color(0xFFB388FF),
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'INTRODUÇÃO'),
              Tab(text: 'LIVROS'),
              Tab(text: 'ÍNDICE'),
              Tab(text: 'APÊNDICE'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildIntroductionTab(),
            _buildBooksTab(hebrewBooks, greekBooks),
            _buildIndexTab(),
            _buildAppendixTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionTab() {
    final articles = BibleContentCatalog.introductionArticles;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: articles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = articles[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF333333)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openArticleSheet(doc),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2638),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories, color: Color(0xFFB388FF), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooksTab(List<BibleBook> hebrewBooks, List<BibleBook> greekBooks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Text(
              'ESCRITURAS HEBRAICO-ARAMAICAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildBooksGrid(hebrewBooks),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Text(
              'ESCRITURAS GREGAS CRISTÃS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildBooksGrid(greekBooks),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBooksGrid(List<BibleBook> booksList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: booksList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.95,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final book = booksList[index];
        return Material(
          color: const Color(0xFF433E4F),
          borderRadius: BorderRadius.circular(2),
          child: InkWell(
            borderRadius: BorderRadius.circular(2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BibleChaptersScreen(
                    book: book,
                    version: _activeVersion!,
                    bibleService: _bibleService,
                  ),
                ),
              );
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  book.abbreviation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndexTab() {
    final filteredTopics = _indexSearchQuery.isEmpty
        ? BibleContentCatalog.indexTopics
        : BibleContentCatalog.indexTopics.where((t) {
            return t.title.toLowerCase().contains(_indexSearchQuery) ||
                t.category.toLowerCase().contains(_indexSearchQuery);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: TextField(
              controller: _indexSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Color(0xFFB388FF)),
                hintText: 'Buscar tópicos e palavras bíblicas...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: filteredTopics.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final topic = filteredTopics[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          topic.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            topic.category,
                            style: const TextStyle(color: Color(0xFFB388FF), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: topic.scriptures.map((ref) {
                        return ActionChip(
                          label: Text(
                            ref,
                            style: const TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color(0xFF2A2A2A),
                          side: const BorderSide(color: Color(0xFF383838)),
                          onPressed: () => _openScriptureRef(ref),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppendixTab() {
    final articles = BibleContentCatalog.appendixArticles
        .where((a) => a.category == _selectedAppendixCategory)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Apêndice A (Tradução)')),
                  selected: _selectedAppendixCategory == 'appendix_a',
                  selectedColor: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(
                    color: _selectedAppendixCategory == 'appendix_a' ? const Color(0xFFB388FF) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _selectedAppendixCategory == 'appendix_a' ? const Color(0xFFB388FF) : const Color(0xFF333333),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedAppendixCategory = 'appendix_a');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Apêndice B (Mapas/Medidas)')),
                  selected: _selectedAppendixCategory == 'appendix_b',
                  selectedColor: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(
                    color: _selectedAppendixCategory == 'appendix_b' ? const Color(0xFFB388FF) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _selectedAppendixCategory == 'appendix_b' ? const Color(0xFFB388FF) : const Color(0xFF333333),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedAppendixCategory = 'appendix_b');
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: articles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = articles[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF333333)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openArticleSheet(doc),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF262E38),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedAppendixCategory == 'appendix_a' ? Icons.translate : Icons.map_outlined,
                            color: const Color(0xFF64B5F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doc.subtitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
