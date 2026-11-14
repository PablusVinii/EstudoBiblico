# Sentinela Study

<p align="center">
  <strong>Assistente pessoal de estudo bíblico com inteligência artificial, leitura offline e navegação integrada de textos sagrados.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Plataforma-Android-3DDC84?logo=android" alt="Android">
  <img src="https://img.shields.io/badge/Vers%C3%A3o-1.4.0-blueviolet" alt="Versão">
  <img src="https://img.shields.io/badge/Licen%C3%A7a-MIT-green" alt="Licença">
</p>

---

## 📌 Visão Geral

O **Sentinela Study** é um aplicativo móvel desenvolvido em **Flutter** voltado para auxiliar no estudo pessoal aprofundado dos artigos de estudo da revista *A Sentinela*. 

O aplicativo combina um leitor de publicações em formato EPUB, persistência local de comentários, integração inteligente com a API do **Google Gemini** para auxílio em raciocínios e respostas objetivas, além de um módulo completo de Bíblia offline com referências cruzadas e citações interativas.

---

## ✨ Principais Funcionalidades

### 📖 Leitor de Artigos de Estudo
- **Acesso Direto à Semana Atual:** O card *"Estudo desta semana"* identifica e abre automaticamente o artigo programado para a semana corrente.
- **Suporte Amplo a Edições (2018 a 2027):** Parser flexível compatível com o formato moderno (com tags `data-pnum`) e formatos legado (anteriores a 2022, com extração de sumários e numeração contextual).
- **Estrutura Visual Completa:** Exibição do tema oficial, data de estudo em faixa contrastante, texto temático, objetivo do estudo, subtítulos de seção e ilustrações internas com legendas.
- **Destaque de Ponto-Chave:** Realce visual em tom amarelo que preserva a tipografia e legibilidade do texto original.

### 🤖 Assistente de Estudo com IA (Google Gemini)
- **Geração de Comentários Objetivos:** Elabora respostas focadas na pergunta do parágrafo, sem saudações ou preâmbulos desnecessários.
- **Seleção Dinâmica de Modelos:** Pré-configurado para o modelo ultrarrápido e econômico `gemini-3.5-flash-lite`, com descoberta automática e fallback para `gemini-2.5-flash`, `gemini-2.0-flash` e `gemini-1.5-flash`.
- **Privacidade da Chave de API:** A chave do usuário é salva estritamente no armazenamento seguro local do dispositivo via `SharedPreferences`.

### 📜 Reconhecimento Inteligente de Textos Bíblicos
- **Citações 100% Clicáveis:** Links em azul sublinhado para todos os livros da Bíblia (incluindo abreviações com e sem espaço como `2 Sam.`, `1 Cor.`, `Êxo.`, `Sal.`).
- **Intervalos entre Capítulos:** Suporte a intervalos compostos como `2 Sam. 16:23–17:2`.
- **Citações Encadeadas com Herança de Contexto:** Reconhecimento automático de versículos sem repetição do nome do livro (ex.: `(2 Sam. 15:13, 14; 18:33)` e `Sal. 38:5-10; 94:17-19`).
- **Navegação Direta:** Tocar na citação abre a Bíblia baixada diretamente no livro, capítulo e versículo com realce de foco.

### 📚 Módulo de Bíblia Completa Offline
- **66 Livros Canônicos:** Divisão em Escrituras Hebraico-Aramaicas (39 livros) e Gregas Cristãs (27 livros).
- **Catálogo de Versões em Português:**
  - Tradução do Novo Mundo da Bíblia Sagrada (nwt - 2015).
  - Tradução do Novo Mundo da Bíblia Sagrada com Referências (bi12 - 1986).
  - Tradução do Novo Mundo da Bíblia Sagrada - Edição de Estudo (nwtsty).
  - Outros idiomas disponíveis: Português (Portugal), Inglês e Espanhol.
- **Download Direto:** Download e extração segura das publicações oficiais públicas, prevenindo vulnerabilidades de *Path Traversal* (*Zip Slip*).
- **Navegação Rápida:** Gestos de deslizar para mudar de capítulo e grade com seletor de livros e capítulos.

### 💾 Persistência Local
- **Banco de Dados SQLite:** Todas as respostas geradas, notas pessoais e marcações são salvas localmente por artigo e número de parágrafo.

### 🎨 Design & Interface
- **Dark AMOLED:** Interface com fundo preto puro (`#000000`), economizando bateria em telas OLED/AMOLED.
- **Controle de Foco:** Toque em qualquer área fora dos campos de edição para recolher o teclado virtual.

---

## 🏗️ Arquitetura do Projeto

```
lib/
├── main.dart                  # Ponto de entrada, configuração de rotas e tema
├── models/
│   ├── article.dart           # Modelos de Artigo de Estudo e Parágrafos
│   ├── bible_model.dart       # Modelos de Livro, Versão, Capítulo e Versículos
│   └── issue.dart             # Modelo de Edição Mensal (ano, mês, url, epub)
├── screens/
│   ├── home_screen.dart       # Navegação principal por abas (Sentinela, Bíblia, Configurações)
│   ├── issues_list_screen.dart# Lista de anos e card "Estudo desta semana"
│   ├── year_issues_screen.dart# Grade de edições mensais do ano selecionado
│   ├── issue_detail_screen.dart# Sumário de artigos da edição baixada
│   ├── article_reader_screen.dart# Leitor do artigo com integração IA e citações
│   ├── bible_screen.dart      # Grade dos 66 livros da Bíblia e seletor de versão
│   ├── bible_chapters_screen.dart# Seletor de capítulos em grade
│   ├── bible_reader_screen.dart# Leitor do capítulo bíblico com realce de versículo
│   ├── bible_languages_dialog.dart# Diálogo de gerenciamento e download de Bíblias
│   └── settings_screen.dart   # Configuração da chave de API Gemini e modelos
├── services/
│   ├── article_parser.dart    # Parser de arquivos EPUB (modernos e legados)
│   ├── bible_citation_parser.dart# Engine de regex para detecção de citações bíblicas
│   ├── bible_service.dart     # Download, extração e carregamento da Bíblia
│   ├── gemini_service.dart    # Comunicação com a API do Google Gemini
│   ├── jw_api_service.dart    # Consulta de metadados públicos de edições
│   └── study_storage_service.dart# Banco de dados SQLite local
├── theme/
│   └── app_theme.dart         # Tema escuro AMOLED oficial
└── widgets/
    └── watchtower_icon.dart   # Ícone vetorial estilizado
```

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão 3.13 ou superior)
- [Dart SDK](https://dart.dev/get-dart) (versão 3.0 ou superior)
- [Android Studio](https://developer.android.com/studio) ou VS Code com extensão Flutter
- JDK 17+ e Android SDK configurado

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/SEU_USUARIO/sentinela_study.git
cd sentinela_study
```

2. Obtenha os pacotes e dependências:
```bash
flutter pub get
```

3. Execute o projeto em um emulador ou dispositivo conectado:
```bash
flutter run
```

4. Para compilar o APK Release:
```bash
flutter build apk --release
```
O arquivo final será gerado em `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Testes Automatizados

O projeto conta com ampla cobertura de testes unitários:

```bash
# Executa todos os testes
flutter test

# Executa a análise estática de código
flutter analyze
```

---

## 🔑 Configuração da Inteligência Artificial

Para habilitar a geração de respostas com IA:
1. Obtenha uma chave gratuita de API no [Google AI Studio](https://aistudio.google.com/).
2. Abra o aplicativo e acerte a aba **Configurações**.
3. Insira a sua chave no campo correspondente e toque em **Testar Conexão e Salvar**.
4. O app validará a chave e selecionará automaticamente o modelo ideal (`gemini-3.5-flash-lite`).

---

## 🛡️ Segurança e Privacidade

- **Armazenamento 100% Local:** Suas respostas, anotações de estudo e chave de API nunca saem do seu dispositivo para servidores terceiros, com exceção da chamada direta aos servidores da API do Google Gemini no momento de gerar uma resposta.
- **Proteção contra Zip Slip:** O módulo de descompactação de arquivos valida se todos os caminhos extraídos estão contidos no diretório de destino do aplicativo, prevenindo vulnerabilidades de path traversal.
- **Sem Rastreamento:** O aplicativo não contém ferramentas de análise, publicidade, rastreadores ou telemetria.

---

## ⚖️ Aviso Legal e Propriedade Intelectual

> [!IMPORTANT]
> **Este projeto é um assistente de estudo pessoal independente, educacional e de código aberto.**

1. **Ausência de Afiliação:** Este software **não** é afiliado, patrocinado, autorizado ou endossado pela *Watch Tower Bible and Tract Society of Pennsylvania*, pela *Associação Torre de Vigia de Bíblias e Tratados* ou por qualquer uma de suas entidades jurídicas ou pelo site [jw.org](https://www.jw.org).
2. **Propriedade Intelectual de Terceiros:** As marcas registradas, títulos de publicações (*A Sentinela* / *The Watchtower*), traduções bíblicas (*Tradução do Novo Mundo da Bíblia Sagrada*) e todas as ilustrações e textos contidos nas publicações pertencem exclusivamente aos seus respectivos detentores de direitos autorais (*Watch Tower Bible and Tract Society of Pennsylvania*).
3. **Sem Redistribuição de Conteúdo Proprietário:** Este repositório de código-fonte contém **exclusivamente código de desenvolvimento em Dart/Flutter**. Nenhuma publicação protegida por direitos autorais, imagem de capa, texto bíblico ou arquivo EPUB/JWPUB é redistribuída, hospedada ou empacotada dentro deste repositório.
4. **Origem dos Dados:** Todo conteúdo baixado no aplicativo é obtido pelo próprio usuário diretamente a partir dos servidores públicos disponibilizados pela respectiva organização, destinando-se ao uso pessoal e privado de estudo do próprio usuário.

---

## 📄 Licença

O código-fonte deste projeto é disponibilizado sob a licença **MIT**. Consulte o arquivo `LICENSE` para mais detalhes.
