import '../models/issue.dart';

class SeedCatalog {
  static const Map<int, String> monthNames = {
    1: 'janeiro',
    2: 'fevereiro',
    3: 'março',
    4: 'abril',
    5: 'maio',
    6: 'junho',
    7: 'julho',
    8: 'agosto',
    9: 'setembro',
    10: 'outubro',
    11: 'novembro',
    12: 'dezembro',
  };

  /// Retorna o período de estudo de A Sentinela.
  /// As edições de estudo são estudadas 2 meses após o mês da edição.
  static String calculateStudyPeriod(int year, int month) {
    // Mês em que os artigos começam a ser estudados (2 meses após a edição)
    int studyStartMonth = month + 2;
    int studyYear = year;
    if (studyStartMonth > 12) {
      studyStartMonth -= 12;
      studyYear += 1;
    }

    final startMonthName = monthNames[studyStartMonth] ?? '';
    final endMonth = studyStartMonth;
    final endMonthName = monthNames[endMonth] ?? '';

    // Intervalo aproximado padrão exibido pelo app oficial
    if (month == 1) return 'Estudos para as semanas de 2 a 29 de março';
    if (month == 2) return 'Estudos para as semanas de 30 de março a 3 de maio';
    if (month == 3) return 'Estudos para as semanas de 4 a 31 de maio';
    if (month == 4) return 'Estudos para as semanas de 1 a 28 de junho';
    if (month == 5) return 'Estudos para as semanas de 29 de junho a 2 de agosto';
    if (month == 6) return 'Estudos para as semanas de 3 a 30 de agosto';
    if (month == 7) return 'Estudos para as semanas de 7 de setembro a 4 de outubro';
    if (month == 8) return 'Estudos para as semanas de 5 de outubro a 1 de novembro';
    if (month == 9) return 'Estudos para as semanas de 2 a 29 de novembro';
    if (month == 10) return 'Estudos para as semanas de 30 de novembro a 3 de janeiro';
    if (month == 11) return 'Estudos para as semanas de 4 a 31 de janeiro';
    if (month == 12) return 'Estudos para as semanas de 1 a 28 de fevereiro';

    return 'Estudos para as semanas de $startMonthName a $endMonthName de $studyYear';
  }

  /// Tamanho típico em MB das edições da Sentinela em EPUB
  static String calculateTypicalSize(int month) {
    final sizes = ['3 MB', '4 MB', '3 MB', '4 MB', '3 MB', '4 MB', '3 MB', '3 MB', '4 MB', '3 MB', '4 MB', '3 MB'];
    return sizes[(month - 1) % sizes.length];
  }

  /// Gera a lista oficial de edições de estudo para um determinado ano
  static List<WatchtowerIssue> getStudyIssuesForYear(int year) {
    final list = <WatchtowerIssue>[];

    // De janeiro a dezembro (1 a 12)
    for (int month = 1; month <= 12; month++) {
      final monthStr = month.toString().padLeft(2, '0');
      final issueCode = '$year$monthStr';
      final monthName = monthNames[month] ?? monthStr;

      list.add(WatchtowerIssue(
        issueCode: issueCode,
        title: 'A Sentinela, $monthName de $year',
        studyPeriod: calculateStudyPeriod(year, month),
        fileSize: calculateTypicalSize(month),
        isPublicEdition: false,
      ));
    }

    return list;
  }
}
