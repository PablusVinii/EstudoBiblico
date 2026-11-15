import 'dart:io';
import 'package:flutter/material.dart';

/// Widget de exibição de imagens e ilustrações internas do artigo
class ArticleIllustrationBox extends StatelessWidget {
  final String path;
  final String? caption;

  const ArticleIllustrationBox({
    super.key,
    required this.path,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          if (caption != null && caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFCCCCCC),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2.5,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
