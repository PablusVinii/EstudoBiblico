import 'package:flutter/material.dart';
import '../models/bible_model.dart';
import '../services/bible_service.dart';

class BibleLanguagesDialog extends StatefulWidget {
  final BibleService bibleService;
  final VoidCallback onVersionChanged;

  const BibleLanguagesDialog({
    super.key,
    required this.bibleService,
    required this.onVersionChanged,
  });

  @override
  State<BibleLanguagesDialog> createState() => _BibleLanguagesDialogState();
}

class _BibleLanguagesDialogState extends State<BibleLanguagesDialog> {
  final _searchController = TextEditingController();
  List<BibleVersion> _allVersions = [];
  List<BibleVersion> _filteredVersions = [];
  String _activeVersionId = '';
  String? _downloadingVersionId;
  double _downloadProgress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVersions() async {
    final activeId = await widget.bibleService.getActiveVersionId();
    final versions = await widget.bibleService.getVersions();
    if (!mounted) return;
    setState(() {
      _allVersions = versions;
      _filteredVersions = versions;
      _activeVersionId = activeId;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVersions = _allVersions;
      } else {
        _filteredVersions = _allVersions.where((v) {
          return v.languageName.toLowerCase().contains(query) ||
              v.title.toLowerCase().contains(query) ||
              v.shortTitle.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleDownload(BibleVersion version) async {
    if (_downloadingVersionId != null) return;
    setState(() {
      _downloadingVersionId = version.id;
      _downloadProgress = 0.0;
    });

    try {
      await widget.bibleService.downloadVersion(
        version,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _downloadProgress = p;
            });
          }
        },
      );
      await widget.bibleService.setActiveVersionId(version.id);
      widget.onVersionChanged();
      await _loadVersions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Erro no download: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingVersionId = null;
        });
      }
    }
  }

  Future<void> _handleSelect(BibleVersion version) async {
    await widget.bibleService.setActiveVersionId(version.id);
    widget.onVersionChanged();
    setState(() {
      _activeVersionId = version.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho "Idiomas"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: const Text(
                'Idiomas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Campo de busca com contagem
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintText: 'Buscar idiomas (${_allVersions.length})',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const Divider(color: Color(0xFF333333), height: 16),

            // Lista de versões/idiomas
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFB388FF)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filteredVersions.length,
                      separatorBuilder: (_, _) => const Divider(color: Color(0xFF282828), height: 1),
                      itemBuilder: (context, index) {
                        final v = _filteredVersions[index];
                        final isDownloading = _downloadingVersionId == v.id;
                        final isSelected = _activeVersionId == v.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          onTap: _downloadingVersionId != null
                              ? null
                              : () {
                                  if (v.isDownloaded) {
                                    _handleSelect(v);
                                  } else {
                                    _handleDownload(v);
                                  }
                                },
                          title: Row(
                            children: [
                              Text(
                                v.languageName,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFB388FF) : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check, color: Color(0xFFB388FF), size: 18),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            v.shortTitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          trailing: isDownloading
                              ? SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _downloadProgress > 0 ? _downloadProgress : null,
                                        color: const Color(0xFFB388FF),
                                        strokeWidth: 3,
                                      ),
                                      Text(
                                        '${(_downloadProgress * 100).toInt()}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      v.sizeLabel,
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      v.isDownloaded ? Icons.download_done : Icons.cloud_download_outlined,
                                      color: v.isDownloaded ? const Color(0xFFB388FF) : Colors.white70,
                                      size: 22,
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
            ),

            const Divider(color: Color(0xFF333333), height: 1),

            // Botão "CONCLUÍDO"
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB388FF),
                  ),
                  child: const Text(
                    'CONCLUÍDO',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
