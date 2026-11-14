import 'package:flutter/material.dart';
import '../models/bible_model.dart';
import '../services/bible_service.dart';
import 'bible_chapters_screen.dart';
import 'bible_languages_dialog.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final _bibleService = BibleService();
  BibleVersion? _activeVersion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveVersion();
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
            _buildInfoTab('Introdução à Bíblia Sagrada e visões gerais dos livros inspirados.'),
            _buildBooksTab(hebrewBooks, greekBooks),
            _buildInfoTab('Índice de palavras e tópicos bíblicos.'),
            _buildInfoTab('Apêndice com tabelas cronológicas, pesos, medidas e mapas.'),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksTab(List<BibleBook> hebrewBooks, List<BibleBook> greekBooks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção Hebraico-Aramaicas
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

          // Seção Gregas Cristãs
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
          color: const Color(0xFF433E4F), // Tom ardósia-púrpura oficial idêntico ao original
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

  Widget _buildInfoTab(String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
