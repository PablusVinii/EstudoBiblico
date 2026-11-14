class BibleBook {
  final int id; // 1 to 66
  final String name; // e.g. "Gênesis"
  final String abbreviation; // e.g. "Gên"
  final int totalChapters; // e.g. 50
  final bool isHebrew; // true for 1..39, false for 40..66
  final String category; // 'pentateuch', 'history', 'poetry', 'prophets', 'gospels', 'acts', 'letters', 'revelation'

  const BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.totalChapters,
    required this.isHebrew,
    required this.category,
  });
}

class BibleVersion {
  final String id;
  final String pubCode;
  final String title;
  final String shortTitle;
  final String languageName;
  final String langCode;
  final String sizeLabel;
  final int sizeBytes;
  final String directUrl;
  final bool isDownloaded;

  const BibleVersion({
    required this.id,
    required this.pubCode,
    required this.title,
    required this.shortTitle,
    required this.languageName,
    required this.langCode,
    required this.sizeLabel,
    required this.sizeBytes,
    required this.directUrl,
    this.isDownloaded = false,
  });

  BibleVersion copyWith({
    String? id,
    String? pubCode,
    String? title,
    String? shortTitle,
    String? languageName,
    String? langCode,
    String? sizeLabel,
    int? sizeBytes,
    String? directUrl,
    bool? isDownloaded,
  }) {
    return BibleVersion(
      id: id ?? this.id,
      pubCode: pubCode ?? this.pubCode,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      languageName: languageName ?? this.languageName,
      langCode: langCode ?? this.langCode,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      directUrl: directUrl ?? this.directUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class BibleVerseItem {
  final int verseNumber;
  final String text;
  final List<String> footnotes;
  final List<String> crossRefs;

  const BibleVerseItem({
    required this.verseNumber,
    required this.text,
    this.footnotes = const [],
    this.crossRefs = const [],
  });
}

class BibleChapterContent {
  final int bookNumber;
  final String bookName;
  final int chapterNumber;
  final List<BibleVerseItem> verses;
  final Map<String, String> footnotes;

  const BibleChapterContent({
    required this.bookNumber,
    required this.bookName,
    required this.chapterNumber,
    required this.verses,
    this.footnotes = const {},
  });
}
