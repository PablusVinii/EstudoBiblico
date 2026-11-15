import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/article.dart';

/// Seção "COMO RESPONDERIA?" (perguntas de recapitulação) e cântico final
class ArticleReviewSection extends StatelessWidget {
  final StudyArticle article;
  final Map<int, TextEditingController> reviewControllers;
  final void Function(ReviewQuestion q) onGenerateReviewAnswer;
  final void Function(int index, String text) onSaveReviewAnswer;

  const ArticleReviewSection({
    super.key,
    required this.article,
    required this.reviewControllers,
    required this.onGenerateReviewAnswer,
    required this.onSaveReviewAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.reviewQuestions.isNotEmpty) ...[
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
          ...article.reviewQuestions.map((q) => _buildReviewQuestionItem(context, q)),
        ],

        if (article.closingSong != null) ...[
          const SizedBox(height: 20),
          Text(
            article.closingSong!,
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

  Widget _buildReviewQuestionItem(BuildContext context, ReviewQuestion q) {
    final ctrl = reviewControllers[q.index];
    final isGen = q.isGenerating;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF689FBD), width: 1.5),
                ),
                child: Text(
                  '${q.index}',
                  style: const TextStyle(
                    color: Color(0xFF689FBD),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF0F0F0),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isGen ? null : () => onGenerateReviewAnswer(q),
                icon: isGen
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(isGen ? 'Gerando...' : 'Gerar Resposta com IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const Spacer(),
              if (ctrl != null && ctrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                  tooltip: 'Copiar resposta',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ctrl.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resposta copiada!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Color(0xFF7C4DFF),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (ctrl != null)
            TextField(
              controller: ctrl,
              maxLines: null,
              onChanged: (val) => onSaveReviewAnswer(q.index, val),
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 15,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Escreva ou gere sua resposta para recapitulação...',
                hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF141414),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
