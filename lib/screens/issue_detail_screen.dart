import 'dart:io';
import 'package:flutter/material.dart';
import '../models/article.dart';
import 'article_reader_screen.dart';

class IssueDetailScreen extends StatelessWidget {
  final ParsedIssue issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Português (Brasil)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Imagem principal no topo (ex: Jeremias sendo resgatado da cisterna)
          if (issue.coverImagePath != null && File(issue.coverImagePath!).existsSync())
            Image.file(
              File(issue.coverImagePath!),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),

          if (issue.studyPeriod != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                issue.studyPeriod!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),

          const Divider(height: 16, color: Color(0xFF262626)),

          // Lista de Artigos de Estudo com thumbnail na esquerda
          ...issue.articles.map((article) {
            final hasThumbnail = article.leadImagePath != null &&
                File(article.leadImagePath!).existsSync();

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleReaderScreen(article: article),
                  ),
                );
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFF262626),
                  child: hasThumbnail
                      ? Image.file(
                          File(article.leadImagePath!),
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.article, color: Color(0xFF90CAF9), size: 28),
                ),
              ),
              title: article.weekDate != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.weekDate!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB0BEC5),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          article.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF90CAF9),
                            height: 1.25,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              trailing: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

