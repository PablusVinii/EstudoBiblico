import 'package:flutter/material.dart';
import '../services/jw_api_service.dart';
import '../widgets/watchtower_icon.dart';
import 'year_issues_screen.dart';
import 'issue_detail_screen.dart';
import 'article_reader_screen.dart';
import '../services/article_parser.dart';
import '../models/issue.dart';
import '../models/article.dart';

class IssuesListScreen extends StatefulWidget {
  const IssuesListScreen({super.key});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  final _apiService = JwApiService();
  List<int> _years = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _years = _apiService.getAvailableYears();
    _autoSyncWithOfficialSite();
  }

  /// Sincronização automática em segundo plano com o site oficial
  Future<void> _autoSyncWithOfficialSite() async {
    setState(() => _isSyncing = true);
    try {
      final newReleases = await _apiService.syncLatestReleases();
      if (mounted && newReleases > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Text('$newReleases novas edições sincronizadas!'),
              ],
            ),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Calcula o estudo da semana atual com base na data do dispositivo
  Map<String, dynamic> _getCurrentWeekStudyInfo() {
    final now = DateTime.now();
    // Encontra a segunda-feira da semana atual
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    const monthsPt = [
      '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];

    final weekRange = '${monday.day} A ${sunday.day} DE ${monthsPt[sunday.month].toUpperCase()} DE ${sunday.year}';

    // A Sentinela de estudo é de 2 meses antes
    int issueMonth = now.month - 2;
    int issueYear = now.year;
    if (issueMonth <= 0) {
      issueMonth += 12;
      issueYear -= 1;
    }

    final issueMonthName = monthsPt[issueMonth];
    final issueCode = '$issueYear${issueMonth.toString().padLeft(2, '0')}';

    return {
      'weekRange': weekRange,
      'issueTitle': 'A Sentinela, $issueMonthName de $issueYear',
      'issueCode': issueCode,
      'year': issueYear,
    };
  }

  /// Baixa e abre diretamente o artigo de estudo da semana atual
  Future<void> _openCurrentWeekStudy(Map<String, dynamic> currentStudy) async {
    final year = currentStudy['year'] as int;
    final issueCode = currentStudy['issueCode'] as String;
    final weekRange = currentStudy['weekRange'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      ),
    );

    try {
      final issues = await _apiService.getIssuesForYear(year);
      WatchtowerIssue? targetIssue;
      for (final iss in issues) {
        if (iss.issueCode == issueCode) {
          targetIssue = iss;
          break;
        }
      }

      if (targetIssue == null && issues.isNotEmpty) {
        targetIssue = issues.first;
      }

      if (targetIssue == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edição da semana não encontrada no catálogo.')),
          );
        }
        return;
      }

      if (!targetIssue.isDownloaded || targetIssue.localPath == null) {
        final downloadedPath = await _apiService.downloadIssue(targetIssue);
        targetIssue.localPath = downloadedPath;
        targetIssue.isDownloaded = true;
      }

      final parsed = await ArticleParser.parseIssue(targetIssue.localPath!, targetIssue.issueCode);

      if (mounted) Navigator.pop(context); // Fecha loading

      if (parsed.articles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum artigo de estudo encontrado nesta edição.')),
          );
        }
        return;
      }

      // Procura o artigo da semana comparando datas
      StudyArticle? matchingArticle;
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final targetNorm = norm(weekRange);

      for (final art in parsed.articles) {
        if (art.weekDate != null) {
          final artNorm = norm(art.weekDate!);
          if (artNorm.contains(targetNorm) || targetNorm.contains(artNorm)) {
            matchingArticle = art;
            break;
          }
          final days = RegExp(r'\d+').allMatches(weekRange).map((m) => m.group(0)!).toList();
          if (days.length >= 2 && art.weekDate!.contains(days[0]) && art.weekDate!.contains(days[1])) {
            matchingArticle = art;
            break;
          }
        }
      }

      if (matchingArticle != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleReaderScreen(article: matchingArticle!),
          ),
        );
      } else if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IssueDetailScreen(issue: parsed),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Erro ao abrir estudo da semana: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStudy = _getCurrentWeekStudyInfo();

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // AMOLED puro idêntico ao original
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A Sentinela',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Português (Brasil)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate, color: Colors.white70),
            tooltip: 'Idioma',
            onPressed: () {},
          ),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                : const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Sincronizar lançamentos',
            onPressed: _autoSyncWithOfficialSite,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _autoSyncWithOfficialSite,
        color: const Color(0xFF7C4DFF),
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Card de Destaque: Estudo Desta Semana
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.6), width: 1.2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openCurrentWeekStudy(currentStudy),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today, color: Color(0xFFFFA726), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESTUDO DESTA SEMANA',
                              style: TextStyle(
                                color: Color(0xFFFFA726),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentStudy['weekRange'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentStudy['issueTitle'] as String,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Text(
                'TODOS OS ANOS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Lista de Anos com Ícone da Torre Oficial
            ..._years.map((year) {
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: const WatchtowerIcon(size: 26, color: Colors.white60),
                    title: Text(
                      '$year',
                      style: const TextStyle(
                        fontSize: 21,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => YearIssuesScreen(year: year),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 72, color: Color(0xFF1C1C1C)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
