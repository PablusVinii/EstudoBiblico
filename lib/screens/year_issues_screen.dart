import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/issue.dart';
import '../services/jw_api_service.dart';
import '../services/article_parser.dart';
import 'issue_detail_screen.dart';

class YearIssuesScreen extends StatefulWidget {
  final int year;

  const YearIssuesScreen({super.key, required this.year});

  @override
  State<YearIssuesScreen> createState() => _YearIssuesScreenState();
}

class _YearIssuesScreenState extends State<YearIssuesScreen> {
  final _apiService = JwApiService();
  List<WatchtowerIssue> _studyIssues = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _localCoverMap = {};

  @override
  void initState() {
    super.initState();
    _loadYearIssues();
  }

  Future<void> _loadYearIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studyList = await _apiService.getIssuesForYear(widget.year);

      final appDir = await getApplicationDocumentsDirectory();
      for (final issue in studyList) {
        final extractedDir = Directory(p.join(appDir.path, 'issues', 'extracted_images', issue.issueCode));
        if (await extractedDir.exists()) {
          final files = await extractedDir.list().toList();
          for (final f in files) {
            if (f.path.contains('cvr') || f.path.contains('cover')) {
              _localCoverMap[issue.issueCode] = f.path;
              break;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _studyIssues = studyList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar edições: $e';
      });
    }
  }

  Future<void> _downloadIssue(WatchtowerIssue issue) async {
    setState(() {
      _downloadProgress[issue.issueCode] = 0.0;
    });

    try {
      await _apiService.downloadIssue(
        issue,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[issue.issueCode] = progress;
            });
          }
        },
      );

      // Extrai imagens e capas após o download
      if (issue.localPath != null) {
        await ArticleParser.parseIssue(issue.localPath!, issue.issueCode);
        final appDir = await getApplicationDocumentsDirectory();
        final extractedDir = Directory(p.join(appDir.path, 'issues', 'extracted_images', issue.issueCode));
        if (await extractedDir.exists()) {
          final files = await extractedDir.list().toList();
          for (final f in files) {
            if (f.path.contains('cvr') || f.path.contains('cover')) {
              _localCoverMap[issue.issueCode] = f.path;
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _downloadProgress.remove(issue.issueCode);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text('${issue.title} baixada com sucesso!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(issue.issueCode);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Falha no download: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteIssue(WatchtowerIssue issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Excluir publicação', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja remover o arquivo de "${issue.title}" do dispositivo?',
          style: const TextStyle(color: Color(0xFFCCCCCC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.deleteDownloadedIssue(issue);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicação excluída com sucesso.')),
        );
      }
    }
  }

  Future<void> _openIssue(WatchtowerIssue issue) async {
    if (!issue.isDownloaded || issue.localPath == null) {
      await _downloadIssue(issue);
      if (!issue.isDownloaded) return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      ),
    );

    try {
      final parsed = await ArticleParser.parseIssue(issue.localPath!, issue.issueCode);
      if (mounted) Navigator.pop(context); // Fecha o loading

      if (parsed.articles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum artigo de estudo encontrado nesta edição.')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IssueDetailScreen(issue: parsed),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Erro ao abrir publicação: $e')),
        );
      }
    }
  }

  void _showItemOptions(WatchtowerIssue issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFF90CAF9)),
                title: Text(issue.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(issue.studyPeriod ?? '', style: const TextStyle(color: Colors.grey)),
              ),
              const Divider(color: Color(0xFF333333)),
              if (issue.isDownloaded) ...[
                ListTile(
                  leading: const Icon(Icons.open_in_new, color: Colors.white),
                  title: const Text('Abrir', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openIssue(issue);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Excluir do dispositivo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteIssue(issue);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.cloud_download, color: Color(0xFF7C4DFF)),
                  title: const Text('Baixar publicação', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Tamanho: ${issue.fileSize ?? "3 MB"}', style: const TextStyle(color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _downloadIssue(issue);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverThumbnail(WatchtowerIssue issue) {
    final localCover = _localCoverMap[issue.issueCode];
    if (localCover != null && File(localCover).existsSync()) {
      return Image.file(
        File(localCover),
        fit: BoxFit.cover,
        width: 58,
        height: 58,
      );
    }

    if (issue.coverUrl != null && issue.coverUrl!.isNotEmpty) {
      return Image.network(
        issue.coverUrl!,
        fit: BoxFit.cover,
        width: 58,
        height: 58,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(),
      );
    }

    return _buildPlaceholderCover();
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFF262626),
      child: const Center(
        child: Icon(Icons.menu_book, color: Color(0xFF7C4DFF), size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fundo preto puro AMOLED idêntico ao original
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.year}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Português (Brasil)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Histórico',
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadYearIssues,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Seção: EDIÇÃO DE ESTUDO
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'EDIÇÃO DE ESTUDO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),

        ..._studyIssues.map((issue) {
          final progress = _downloadProgress[issue.issueCode];

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () => _openIssue(issue),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: _buildCoverThumbnail(issue),
                ),
                title: Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(
                      issue.studyPeriod ?? 'Estudos para as semanas...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: progress, color: const Color(0xFF7C4DFF)),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress != null)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C4DFF)),
                      )
                    else if (!issue.isDownloaded)
                      GestureDetector(
                        onTap: () => _downloadIssue(issue),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.file_download_outlined, color: Colors.white70, size: 24),
                              Text(
                                issue.fileSize ?? '3 MB',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () => _showItemOptions(issue),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 86, color: Color(0xFF1F1F1F)),
            ],
          );
        }),
      ],
    );
  }
}
