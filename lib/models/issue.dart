class WatchtowerIssue {
  final String issueCode; // e.g. "202609"
  final String title; // e.g. "A Sentinela, setembro de 2026"
  final String? coverUrl;
  String? fileUrl;
  String format; // "EPUB" or "JWPUB"
  bool isDownloaded;
  String? localPath;
  final String? studyPeriod; // e.g. "Estudos para as semanas de 2 a 29 de março"
  final String? fileSize; // e.g. "3 MB", "4 MB"
  final String? checksum; // SHA-256 integridade
  final bool isPublicEdition; // true se for "Edição para o Público", false se for "Edição de Estudo"

  WatchtowerIssue({
    required this.issueCode,
    required this.title,
    this.coverUrl,
    this.fileUrl,
    this.format = 'EPUB',
    this.isDownloaded = false,
    this.localPath,
    this.studyPeriod,
    this.fileSize,
    this.checksum,
    this.isPublicEdition = false,
  });

  Map<String, dynamic> toJson() => {
    'issueCode': issueCode,
    'title': title,
    'coverUrl': coverUrl,
    'fileUrl': fileUrl,
    'format': format,
    'isDownloaded': isDownloaded,
    'localPath': localPath,
    'studyPeriod': studyPeriod,
    'fileSize': fileSize,
    'checksum': checksum,
    'isPublicEdition': isPublicEdition,
  };

  factory WatchtowerIssue.fromJson(Map<String, dynamic> json) => WatchtowerIssue(
    issueCode: json['issueCode'] ?? '',
    title: json['title'] ?? '',
    coverUrl: json['coverUrl'],
    fileUrl: json['fileUrl'],
    format: json['format'] ?? 'EPUB',
    isDownloaded: json['isDownloaded'] ?? false,
    localPath: json['localPath'],
    studyPeriod: json['studyPeriod'],
    fileSize: json['fileSize'],
    checksum: json['checksum'],
    isPublicEdition: json['isPublicEdition'] ?? false,
  );
}
