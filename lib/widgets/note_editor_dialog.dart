import 'package:flutter/material.dart';

/// Diálogo reutilizável para criar ou editar notas de estudo vinculadas a marcações
class NoteEditorDialog {
  static Future<void> show({
    required BuildContext context,
    required String selectedText,
    required String? initialNote,
    required Future<void> Function(String note) onSave,
  }) async {
    final clean = selectedText.trim();
    final ctrl = TextEditingController(text: initialNote ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Color(0xFFB388FF)),
            SizedBox(width: 8),
            Text('Anotação de Estudo', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“$clean”',
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Escreva sua anotação...',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB388FF))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onSave(ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
