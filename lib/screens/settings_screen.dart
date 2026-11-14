import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/jw_backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _geminiService = GeminiService();
  bool _obscureText = true;
  bool _isSaving = false;
  bool _isBackingUp = false;
  String? _statusMessage;
  bool _statusIsSuccess = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _geminiService.getApiKey();
    if (mounted && key != null) {
      setState(() {
        _apiKeyController.text = key;
      });
    }
  }

  Future<void> _saveKey() async {
    final cleanKey = _apiKeyController.text.trim();
    if (cleanKey.isEmpty) {
      setState(() {
        _statusIsSuccess = false;
        _statusMessage = 'Por favor, digite sua Chave API do Google AI Studio.';
      });
      return;
    }

    setState(() => _isSaving = true);
    await _geminiService.saveApiKey(cleanKey);
    await _geminiService.saveActiveModel(GeminiService.defaultModel);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _statusIsSuccess = true;
        _statusMessage = 'Chave salva com sucesso! O modelo padrão Gemini 3.5 Flash-Lite está ativo permanentemente.';
      });
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  Future<void> _handleExportBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final path = await JwBackupService.exportToJwLibrary();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent),
                SizedBox(width: 10),
                Text('Backup Concluído', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suas anotações e comentários foram exportados com sucesso no formato oficial .jwlibrary!',
                  style: TextStyle(color: Color(0xFFE0E0E0), height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Salvo em:\n$path',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Color(0xFF7C4DFF))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Erro ao exportar backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // AMOLED puro
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Configurações',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Inteligência Artificial (Google Gemini)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF9E86FF)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Insira sua Chave de API do Google AI Studio (aistudio.google.com). O aplicativo utiliza por padrão o modelo Gemini 3.5 Flash-Lite para gerar respostas e destacar os pontos no estudo.',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Chave API Gemini (AI Studio)',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'AIzaSy...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF7C4DFF)),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão único de Salvar Chave
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveKey,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Salvando...' : 'Salvar Chave',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusIsSuccess
                    ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
                    : const Color(0xFFB71C1C).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusIsSuccess ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusIsSuccess ? Icons.check_circle : Icons.error,
                    color: _statusIsSuccess ? Colors.greenAccent : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusIsSuccess ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 40, color: Color(0xFF262626)),

          // Seção: Backup & Interoperabilidade Oficial
          const Text(
            'Backup & Interoperabilidade (.jwlibrary)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Exporte seus comentários e estudos preparados em formato de backup oficial .jwlibrary para transferir para outros aparelhos.',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isBackingUp ? null : _handleExportBackup,
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.backup_outlined, color: Colors.white70),
              label: Text(
                _isBackingUp ? 'Exportando backup...' : 'Exportar Backup (.jwlibrary)',
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF444444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const Divider(height: 40, color: Color(0xFF262626)),

          const Text(
            'Sobre o Aplicativo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente de Estudo de A Sentinela',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Versão 1.1.0 (Clean-Room Engine)\n\n'
                  'Aviso Legal / Isenção de Responsabilidade:\n'
                  'Este é um aplicativo independente concebido para fins educacionais e estudo pessoal da Bíblia. '
                  'Não é um aplicativo oficial nem é patrocinado pela Watch Tower Bible and Tract Society. '
                  'Todas as publicações e textos baixados são obtidos diretamente dos canais públicos oficiais.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
