import 'dart:convert';
import 'package:flutter/material.dart';

/// Modelo imutável que representa uma marcação de texto do usuário
/// compatível com a paleta oficial do JW Library (6 cores canônicas).
class UserHighlight {
  final String id;
  final String sourceType; // 'bible' ou 'sentinela'
  final String referenceKey; // ex: 'bible_40_5' (Mateus 5) ou 'art_202601_1'
  final int blockIndex; // verseNumber ou paragraphNumber
  final int startOffset;
  final int endOffset;
  final int colorIndex; // 1 a 6
  final String selectedText;
  final String? noteText;
  final String updatedAt;

  const UserHighlight({
    required this.id,
    required this.sourceType,
    required this.referenceKey,
    required this.blockIndex,
    required this.startOffset,
    required this.endOffset,
    required this.colorIndex,
    required this.selectedText,
    this.noteText,
    required this.updatedAt,
  });

  /// Paleta oficial de 6 cores do JW Library (cores de ícone e botão)
  static const Map<int, Color> officialColors = {
    1: Color(0xFFFFF37A), // Amarelo (yellow_200)
    2: Color(0xFFB7E492), // Verde (green_200)
    3: Color(0xFF9FB9E3), // Azul (blue_200)
    4: Color(0xFFC1A7E2), // Roxo/Violeta (violet_200)
    5: Color(0xFFF698BC), // Rosa (pink_200)
    6: Color(0xFFFFBA8A), // Laranja (orange_200)
  };

  /// Cores de fundo semi-transparentes para renderização em tema escuro
  static const Map<int, Color> officialHighlightColors = {
    1: Color(0x66FFF37A),
    2: Color(0x66B7E492),
    3: Color(0x669FB9E3),
    4: Color(0x66C1A7E2),
    5: Color(0x66F698BC),
    6: Color(0x66FFBA8A),
  };

  /// Nomes descritivos das cores em português
  static const Map<int, String> colorNames = {
    1: 'Amarelo',
    2: 'Verde',
    3: 'Azul',
    4: 'Roxo',
    5: 'Rosa',
    6: 'Laranja',
  };

  Color get color => officialColors[colorIndex] ?? officialColors[1]!;
  Color get highlightColor => officialHighlightColors[colorIndex] ?? officialHighlightColors[1]!;

  UserHighlight copyWith({
    String? id,
    String? sourceType,
    String? referenceKey,
    int? blockIndex,
    int? startOffset,
    int? endOffset,
    int? colorIndex,
    String? selectedText,
    String? noteText,
    String? updatedAt,
  }) {
    return UserHighlight(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      referenceKey: referenceKey ?? this.referenceKey,
      blockIndex: blockIndex ?? this.blockIndex,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      colorIndex: colorIndex ?? this.colorIndex,
      selectedText: selectedText ?? this.selectedText,
      noteText: noteText ?? this.noteText,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceType': sourceType,
      'referenceKey': referenceKey,
      'blockIndex': blockIndex,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'colorIndex': colorIndex,
      'selectedText': selectedText,
      'noteText': noteText,
      'updatedAt': updatedAt,
    };
  }

  factory UserHighlight.fromMap(Map<String, dynamic> map) {
    return UserHighlight(
      id: map['id']?.toString() ?? '',
      sourceType: map['sourceType']?.toString() ?? 'bible',
      referenceKey: map['referenceKey']?.toString() ?? '',
      blockIndex: (map['blockIndex'] as num?)?.toInt() ?? 0,
      startOffset: (map['startOffset'] as num?)?.toInt() ?? 0,
      endOffset: (map['endOffset'] as num?)?.toInt() ?? 0,
      colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 1,
      selectedText: map['selectedText']?.toString() ?? '',
      noteText: map['noteText']?.toString(),
      updatedAt: map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserHighlight.fromJson(String source) =>
      UserHighlight.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
