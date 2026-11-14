class ParsedIssue {
  final String issueCode;
  final String title;
  final String? studyPeriod;
  final String? coverImagePath;
  final List<StudyArticle> articles;

  ParsedIssue({
    required this.issueCode,
    required this.title,
    this.studyPeriod,
    this.coverImagePath,
    required this.articles,
  });
}

class StudyArticle {
  final String id;
  final String title;
  final String? weekDate;
  final String? song;
  final String? themeScripture;
  final String? objective;
  final String? leadImagePath;
  final List<StudyParagraph> paragraphs;

  StudyArticle({
    required this.id,
    required this.title,
    this.weekDate,
    this.song,
    this.themeScripture,
    this.objective,
    this.leadImagePath,
    required this.paragraphs,
  });
}

class StudyParagraph {
  final int number;
  final String text;
  final String? questionNumber;
  final String? question;
  final String? headingBefore;
  final String? illustrationPath;
  final String? illustrationCaption;
  String userAnswer;
  String? highlightedKeyPoint;
  bool isGenerating;

  StudyParagraph({
    required this.number,
    required this.text,
    this.questionNumber,
    this.question,
    this.headingBefore,
    this.illustrationPath,
    this.illustrationCaption,
    this.userAnswer = '',
    this.highlightedKeyPoint,
    this.isGenerating = false,
  });
}
