import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_explanation_service.dart';

/// Modal inferior estilizado que exibe a explicação bíblica confinada às fontes oficiais
class ExplanationSheet extends StatefulWidget {
  final String selectedText;
  final String contextText;
  final AiExplanationService? explanationService;

  const ExplanationSheet({
    super.key,
    required this.selectedText,
    required this.contextText,
    this.explanationService,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedText,
    required String contextText,
    AiExplanationService? explanationService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExplanationSheet(
        selectedText: selectedText,
        contextText: contextText,
        explanationService: explanationService,
      ),
    );
  }

  @override
  State<ExplanationSheet> createState() => _ExplanationSheetState();
}

class _ExplanationSheetState extends State<ExplanationSheet> {
  late final AiExplanationService _service;
  bool _isLoading = true;
  String? _errorMessage;
  AiExplanationResult? _result;

  @override
  void initState() {
    super.initState();
    _service = widget.explanationService ?? AiExplanationService();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.explainSelection(
        selectedText: widget.selectedText,
        contextText: widget.contextText,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String feedback) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF7C4DFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFFB388FF), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Explicação Bíblica Oficial',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3E3E3E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRECHO SELECIONADO:',
                      style: TextStyle(
                        color: Color(0xFFB388FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“${widget.selectedText}”',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Color(0xFFB388FF)),
                            SizedBox(height: 16),
                            Text(
                              'Consultando wol.jw.org e analisando...',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchExplanation,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tentar Novamente'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C4DFF),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              const Text(
                                'Significado Bíblico:',
                                style: TextStyle(
                                  color: Color(0xFFB388FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _result!.explanation,
                                style: const TextStyle(
                                  color: Color(0xFFE6E6E6),
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_result!.application != null && _result!.application!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B3A27),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2E693F)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.lightbulb_outline, color: Color(0xFF81C784), size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'Aplicação para a Reunião / Dia a Dia:',
                                            style: TextStyle(
                                              color: Color(0xFF81C784),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _result!.application!,
                                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_result!.officialSource != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.verified, color: Color(0xFF64B5F6), size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Fonte: ${_result!.officialSource!}',
                                        style: const TextStyle(
                                          color: Color(0xFF64B5F6),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (_result!.sources.isNotEmpty) ...[
                                const Divider(color: Color(0xFF333333)),
                                const Text(
                                  'Artigos Oficiais no wol.jw.org:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._result!.sources.map(
                                  (src) => Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF262626),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.link, color: Color(0xFFB388FF), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            src.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 16, color: Colors.white60),
                                          tooltip: 'Copiar Link Oficial',
                                          onPressed: () => _copyToClipboard(
                                            src.url,
                                            'Link do wol.jw.org copiado!',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final appStr = _result!.application != null ? '\nAplicação: ${_result!.application!}' : '';
                                  final fullText = 'Explicação (${widget.selectedText}):\n${_result!.explanation}$appStr\nFonte: ${_result!.officialSource ?? 'wol.jw.org'}';
                                  _copyToClipboard(fullText, 'Explicação copiada com sucesso!');
                                },
                                icon: const Icon(Icons.content_copy),
                                label: const Text('Copiar Explicação para Notas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF333333),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 44),
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
