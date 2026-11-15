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

class ReviewQuestion {
  final int index;
  final String question;
  String userAnswer;
  bool isGenerating;

  ReviewQuestion({
    required this.index,
    required this.question,
    this.userAnswer = '',
    this.isGenerating = false,
  });
}

class StudyArticle {
  final String id;
  final String title;
  final String? weekDate;
  final String? song;
  final String? closingSong;
  final String? themeScripture;
  final String? objective;
  final String? leadImagePath;
  final List<StudyParagraph> paragraphs;
  final List<ReviewQuestion> reviewQuestions;

  StudyArticle({
    required this.id,
    required this.title,
    this.weekDate,
    this.song,
    this.closingSong,
    this.themeScripture,
    this.objective,
    this.leadImagePath,
    required this.paragraphs,
    this.reviewQuestions = const [],
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
  String? directComment;
  String? additionalComment;
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
    this.directComment,
    this.additionalComment,
    this.isGenerating = false,
  });
}
