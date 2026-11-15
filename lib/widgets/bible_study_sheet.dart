import 'package:flutter/material.dart';
import '../models/bible_model.dart';
import '../models/user_highlight_model.dart';

/// Modal inferior do Painel de Estudo Bíblico (Notas de Rodapé, Referências e Marcações Pessoais)
class BibleStudySheet extends StatelessWidget {
  final BibleBook book;
  final int currentChapter;
  final BibleChapterContent? content;
  final bool isDownloaded;
  final List<UserHighlight> highlights;
  final void Function(UserHighlight highlight) onDeleteHighlight;
  final void Function(int verseNumber, String ref) onShowCrossRef;
  final VoidCallback onDownloadFullBible;

  const BibleStudySheet({
    super.key,
    required this.book,
    required this.currentChapter,
    required this.content,
    required this.isDownloaded,
    required this.highlights,
    required this.onDeleteHighlight,
    required this.onShowCrossRef,
    required this.onDownloadFullBible,
  });

  static void show(
    BuildContext context, {
    required BibleBook book,
    required int currentChapter,
    required BibleChapterContent? content,
    required bool isDownloaded,
    required List<UserHighlight> highlights,
    required void Function(UserHighlight highlight) onDeleteHighlight,
    required void Function(int verseNumber, String ref) onShowCrossRef,
    required VoidCallback onDownloadFullBible,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => BibleStudySheet(
        book: book,
        currentChapter: currentChapter,
        content: content,
        isDownloaded: isDownloaded,
        highlights: highlights,
        onDeleteHighlight: onDeleteHighlight,
        onShowCrossRef: onShowCrossRef,
        onDownloadFullBible: onDownloadFullBible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Painel de Estudo — ${book.name} $currentChapter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Notas de rodapé explicativas, referências marginais e materiais complementares.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Seção 1: Notas de Rodapé do Capítulo
            if (content != null && content!.footnotes.isNotEmpty) ...[
              const Divider(color: Color(0xFF333333)),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD54F), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Notas de Rodapé (${content!.footnotes.length}):',
                    style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...content!.footnotes.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('* ', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Seção 2: Referências Marginais (Textos Cruzados)
            if (content != null && content!.verses.any((v) => v.crossRefs.isNotEmpty)) ...[
              const Divider(color: Color(0xFF333333)),
              Row(
                children: const [
                  Icon(Icons.link, color: Color(0xFF64B5F6), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Referências Marginais:',
                    style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...content!.verses.where((v) => v.crossRefs.isNotEmpty).map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text('v. ${v.verseNumber}: ', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            children: v.crossRefs.map((ref) {
                              return ActionChip(
                                label: Text(ref, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: const Color(0xFF2A2A2A),
                                onPressed: () {
                                  Navigator.pop(context);
                                  onShowCrossRef(v.verseNumber, ref);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Seção 3: Minhas Marcações e Notas do Capítulo
            if (highlights.isNotEmpty) ...[
              const Divider(color: Color(0xFF333333)),
              Row(
                children: [
                  const Icon(Icons.border_color, color: Color(0xFFB388FF), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Minhas Marcações e Notas (${highlights.length}):',
                    style: const TextStyle(color: Color(0xFFB388FF), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...highlights.map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: h.color, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'v. ${h.blockIndex} (${UserHighlight.colorNames[h.colorIndex]})',
                              style: TextStyle(color: h.color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context);
                                onDeleteHighlight(h);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '“${h.selectedText}”',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                        if (h.noteText != null && h.noteText!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Nota: ${h.noteText!}',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            if (!isDownloaded)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDownloadFullBible();
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
  }
}
