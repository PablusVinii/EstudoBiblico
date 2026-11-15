import 'package:flutter/material.dart';
import '../models/article.dart';

/// Caixa de resposta e comentários para cada parágrafo de A Sentinela
class ParagraphAnswerBox extends StatelessWidget {
  final String articleId;
  final StudyParagraph paragraph;
  final TextEditingController? controller;
  final VoidCallback onGenerate;
  final void Function(String text) onAnswerChanged;
  final void Function(String text) onSelectComment;

  const ParagraphAnswerBox({
    super.key,
    required this.articleId,
    required this.paragraph,
    required this.controller,
    required this.onGenerate,
    required this.onAnswerChanged,
    required this.onSelectComment,
  });

  @override
  Widget build(BuildContext context) {
    final isGenerating = paragraph.isGenerating;
    final hasDirect = paragraph.directComment != null && paragraph.directComment!.isNotEmpty;
    final hasAddit = paragraph.additionalComment != null && paragraph.additionalComment!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDirect || hasAddit)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (hasDirect)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => onSelectComment(paragraph.directComment!),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (controller?.text.trim() == paragraph.directComment?.trim())
                                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.35)
                                  : const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (controller?.text.trim() == paragraph.directComment?.trim())
                                    ? const Color(0xFFB388FF)
                                    : const Color(0xFF3E3E3E),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('?', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  'Direto (1-2 frases)',
                                  style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hasAddit)
                      InkWell(
                        onTap: () => onSelectComment(paragraph.additionalComment!),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (controller?.text.trim() == paragraph.additionalComment?.trim())
                                ? const Color(0xFF7C4DFF).withValues(alpha: 0.35)
                                : const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (controller?.text.trim() == paragraph.additionalComment?.trim())
                                  ? const Color(0xFFB388FF)
                                  : const Color(0xFF3E3E3E),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('??', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                'Aprofundado / Aplicação',
                                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (hasDirect && hasAddit)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: InkWell(
                          onTap: () {
                            final fullText = '?? Comentário Direto:\n${paragraph.directComment!}\n\n?? Comentário Adicional:\n${paragraph.additionalComment!}';
                            onSelectComment(fullText);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (controller?.text.trim().contains('?? Comentário Direto:') ?? false)
                                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.35)
                                  : const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (controller?.text.trim().contains('?? Comentário Direto:') ?? false)
                                    ? const Color(0xFFB388FF)
                                    : const Color(0xFF3E3E3E),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('??', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  'Completo',
                                  style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 2,
            style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
            decoration: const InputDecoration(
              hintText: 'Escreva seu comentário...',
              hintStyle: TextStyle(color: Color(0xFF757575)),
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
            onChanged: onAnswerChanged,
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
                    onTap: onGenerate,
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
                          const Text('?', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            (controller?.text.trim().isNotEmpty ?? false) ? 'Regenerar' : 'Gerar Resposta',
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
}
