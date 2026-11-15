import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_highlight_model.dart';

/// Barra de ferramentas contextual flutuante que replica a toolbar de marcação do JW Library oficial
class JwTextSelectionToolbar extends StatelessWidget {
  final SelectableRegionState selectableRegionState;
  final String selectedText;
  final void Function(int colorIndex, String selectedText) onColorSelected;
  final void Function(String selectedText)? onDeleteHighlight;
  final void Function(String selectedText)? onExplainWithAi;
  final void Function(String selectedText)? onAddNote;

  const JwTextSelectionToolbar({
    super.key,
    required this.selectableRegionState,
    required this.selectedText,
    required this.onColorSelected,
    this.onDeleteHighlight,
    this.onExplainWithAi,
    this.onAddNote,
  });

  void _closeToolbar() {
    selectableRegionState.hideToolbar();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextSelectionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // As 6 cores oficiais de marca-texto do JW Library
              for (int colorIdx = 1; colorIdx <= 6; colorIdx++) ...[
                _buildColorCircle(
                  colorIdx: colorIdx,
                  text: selectedText,
                ),
                if (colorIdx < 6) const SizedBox(width: 6),
              ],

              const SizedBox(width: 6),
              Container(width: 1, height: 22, color: const Color(0xFF444444)),
              const SizedBox(width: 6),

              // Botão de Borracha / Desmarcar (se aplicável)
              if (onDeleteHighlight != null) ...[
                IconButton(
                  icon: const Icon(Icons.format_color_reset, size: 18, color: Colors.white70),
                  tooltip: 'Desmarcar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    onDeleteHighlight!(selectedText);
                    _closeToolbar();
                  },
                ),
              ],

              // Botão de Adicionar Nota
              if (onAddNote != null) ...[
                IconButton(
                  icon: const Icon(Icons.note_add_outlined, size: 18, color: Colors.white70),
                  tooltip: 'Adicionar Nota',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    onAddNote!(selectedText);
                    _closeToolbar();
                  },
                ),
              ],

              // Botão Copiar
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                tooltip: 'Copiar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: selectedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Texto copiado com sucesso!'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xFF7C4DFF),
                    ),
                  );
                  _closeToolbar();
                },
              ),

              // Botão "Explicar com IA" (Diferencial com RAG wol.jw.org)
              if (onExplainWithAi != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: () {
                    onExplainWithAi!(selectedText);
                    _closeToolbar();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB388FF), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, size: 15, color: Color(0xFFB388FF)),
                        SizedBox(width: 4),
                        Text(
                          'Explicar',
                          style: TextStyle(
                            color: Color(0xFFB388FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle({
    required int colorIdx,
    required String text,
  }) {
    final color = UserHighlight.officialColors[colorIdx] ?? Colors.yellow;
    final name = UserHighlight.colorNames[colorIdx] ?? '';

    return InkWell(
      onTap: () {
        onColorSelected(colorIdx, text);
        _closeToolbar();
      },
      borderRadius: BorderRadius.circular(14),
      child: Tooltip(
        message: 'Marcar com $name',
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
