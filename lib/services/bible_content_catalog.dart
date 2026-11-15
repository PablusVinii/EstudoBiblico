import '../models/bible_model.dart';

class BibleContentCatalog {
static const List<BibleBook> books = [
    // 1-5 Pentateuco / Lei
    BibleBook(id: 1, name: 'Gênesis', abbreviation: 'Gên', totalChapters: 50, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 2, name: 'Êxodo', abbreviation: 'Êx', totalChapters: 40, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 3, name: 'Levítico', abbreviation: 'Le', totalChapters: 27, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 4, name: 'Números', abbreviation: 'Núm', totalChapters: 36, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 5, name: 'Deuteronômio', abbreviation: 'De', totalChapters: 34, isHebrew: true, category: 'pentateuch'),

    // 6-17 Livros Históricos
    BibleBook(id: 6, name: 'Josué', abbreviation: 'Jos', totalChapters: 24, isHebrew: true, category: 'history'),
    BibleBook(id: 7, name: 'Juízes', abbreviation: 'Jz', totalChapters: 21, isHebrew: true, category: 'history'),
    BibleBook(id: 8, name: 'Rute', abbreviation: 'Ru', totalChapters: 4, isHebrew: true, category: 'history'),
    BibleBook(id: 9, name: '1 Samuel', abbreviation: '1Sa', totalChapters: 31, isHebrew: true, category: 'history'),
    BibleBook(id: 10, name: '2 Samuel', abbreviation: '2Sa', totalChapters: 24, isHebrew: true, category: 'history'),
    BibleBook(id: 11, name: '1 Reis', abbreviation: '1Rs', totalChapters: 22, isHebrew: true, category: 'history'),
    BibleBook(id: 12, name: '2 Reis', abbreviation: '2Rs', totalChapters: 25, isHebrew: true, category: 'history'),
    BibleBook(id: 13, name: '1 Crônicas', abbreviation: '1Cr', totalChapters: 29, isHebrew: true, category: 'history'),
    BibleBook(id: 14, name: '2 Crônicas', abbreviation: '2Cr', totalChapters: 36, isHebrew: true, category: 'history'),
    BibleBook(id: 15, name: 'Esdras', abbreviation: 'Esd', totalChapters: 10, isHebrew: true, category: 'history'),
    BibleBook(id: 16, name: 'Neemias', abbreviation: 'Ne', totalChapters: 13, isHebrew: true, category: 'history'),
    BibleBook(id: 17, name: 'Ester', abbreviation: 'Est', totalChapters: 10, isHebrew: true, category: 'history'),

    // 18-22 Livros Poéticos
    BibleBook(id: 18, name: 'Jó', abbreviation: 'Jó', totalChapters: 42, isHebrew: true, category: 'poetry'),
    BibleBook(id: 19, name: 'Salmos', abbreviation: 'Sal', totalChapters: 150, isHebrew: true, category: 'poetry'),
    BibleBook(id: 20, name: 'Provérbios', abbreviation: 'Pr', totalChapters: 31, isHebrew: true, category: 'poetry'),
    BibleBook(id: 21, name: 'Eclesiastes', abbreviation: 'Ec', totalChapters: 12, isHebrew: true, category: 'poetry'),
    BibleBook(id: 22, name: 'Cântico de Salomão', abbreviation: 'Cân', totalChapters: 8, isHebrew: true, category: 'poetry'),

    // 23-39 Profetas Maiores e Menores
    BibleBook(id: 23, name: 'Isaías', abbreviation: 'Is', totalChapters: 66, isHebrew: true, category: 'prophets'),
    BibleBook(id: 24, name: 'Jeremias', abbreviation: 'Je', totalChapters: 52, isHebrew: true, category: 'prophets'),
    BibleBook(id: 25, name: 'Lamentações', abbreviation: 'La', totalChapters: 5, isHebrew: true, category: 'prophets'),
    BibleBook(id: 26, name: 'Ezequiel', abbreviation: 'Ez', totalChapters: 48, isHebrew: true, category: 'prophets'),
    BibleBook(id: 27, name: 'Daniel', abbreviation: 'Da', totalChapters: 12, isHebrew: true, category: 'prophets'),
    BibleBook(id: 28, name: 'Oseias', abbreviation: 'Os', totalChapters: 14, isHebrew: true, category: 'prophets'),
    BibleBook(id: 29, name: 'Joel', abbreviation: 'Jl', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 30, name: 'Amós', abbreviation: 'Am', totalChapters: 9, isHebrew: true, category: 'prophets'),
    BibleBook(id: 31, name: 'Obadias', abbreviation: 'Ob', totalChapters: 1, isHebrew: true, category: 'prophets'),
    BibleBook(id: 32, name: 'Jonas', abbreviation: 'Jon', totalChapters: 4, isHebrew: true, category: 'prophets'),
    BibleBook(id: 33, name: 'Miqueias', abbreviation: 'Miq', totalChapters: 7, isHebrew: true, category: 'prophets'),
    BibleBook(id: 34, name: 'Naum', abbreviation: 'Na', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 35, name: 'Habacuque', abbreviation: 'Hab', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 36, name: 'Sofonias', abbreviation: 'Sof', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 37, name: 'Ageu', abbreviation: 'Ag', totalChapters: 2, isHebrew: true, category: 'prophets'),
    BibleBook(id: 38, name: 'Zacarias', abbreviation: 'Za', totalChapters: 14, isHebrew: true, category: 'prophets'),
    BibleBook(id: 39, name: 'Malaquias', abbreviation: 'Mal', totalChapters: 4, isHebrew: true, category: 'prophets'),

    // 40-43 Evangelhos
    BibleBook(id: 40, name: 'Mateus', abbreviation: 'Mt', totalChapters: 28, isHebrew: false, category: 'gospels'),
    BibleBook(id: 41, name: 'Marcos', abbreviation: 'Mr', totalChapters: 16, isHebrew: false, category: 'gospels'),
    BibleBook(id: 42, name: 'Lucas', abbreviation: 'Lu', totalChapters: 24, isHebrew: false, category: 'gospels'),
    BibleBook(id: 43, name: 'João', abbreviation: 'Jo', totalChapters: 21, isHebrew: false, category: 'gospels'),

    // 44 Atos
    BibleBook(id: 44, name: 'Atos', abbreviation: 'At', totalChapters: 28, isHebrew: false, category: 'acts'),

    // 45-65 Cartas
    BibleBook(id: 45, name: 'Romanos', abbreviation: 'Ro', totalChapters: 16, isHebrew: false, category: 'letters'),
    BibleBook(id: 46, name: '1 Coríntios', abbreviation: '1Co', totalChapters: 16, isHebrew: false, category: 'letters'),
    BibleBook(id: 47, name: '2 Coríntios', abbreviation: '2Co', totalChapters: 13, isHebrew: false, category: 'letters'),
    BibleBook(id: 48, name: 'Gálatas', abbreviation: 'Gál', totalChapters: 6, isHebrew: false, category: 'letters'),
    BibleBook(id: 49, name: 'Efésios', abbreviation: 'Ef', totalChapters: 6, isHebrew: false, category: 'letters'),
    BibleBook(id: 50, name: 'Filipenses', abbreviation: 'Fil', totalChapters: 4, isHebrew: false, category: 'letters'),
    BibleBook(id: 51, name: 'Colossenses', abbreviation: 'Col', totalChapters: 4, isHebrew: false, category: 'letters'),
    BibleBook(id: 52, name: '1 Tessalonicenses', abbreviation: '1Te', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 53, name: '2 Tessalonicenses', abbreviation: '2Te', totalChapters: 3, isHebrew: false, category: 'letters'),
    BibleBook(id: 54, name: '1 Timóteo', abbreviation: '1Ti', totalChapters: 6, isHebrew: false, category: 'letters'),
    BibleBook(id: 55, name: '2 Timóteo', abbreviation: '2Ti', totalChapters: 4, isHebrew: false, category: 'letters'),
    BibleBook(id: 56, name: 'Tito', abbreviation: 'Tit', totalChapters: 3, isHebrew: false, category: 'letters'),
    BibleBook(id: 57, name: 'Filêmon', abbreviation: 'Flm', totalChapters: 1, isHebrew: false, category: 'letters'),
    BibleBook(id: 58, name: 'Hebreus', abbreviation: 'Heb', totalChapters: 13, isHebrew: false, category: 'letters'),
    BibleBook(id: 59, name: 'Tiago', abbreviation: 'Tg', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 60, name: '1 Pedro', abbreviation: '1Pe', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 61, name: '2 Pedro', abbreviation: '2Pe', totalChapters: 3, isHebrew: false, category: 'letters'),
    BibleBook(id: 62, name: '1 João', abbreviation: '1Jo', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 63, name: '2 João', abbreviation: '2Jo', totalChapters: 1, isHebrew: false, category: 'letters'),
    BibleBook(id: 64, name: '3 João', abbreviation: '3Jo', totalChapters: 1, isHebrew: false, category: 'letters'),
    BibleBook(id: 65, name: 'Judas', abbreviation: 'Jd', totalChapters: 1, isHebrew: false, category: 'letters'),

    // 66 Apocalipse
    BibleBook(id: 66, name: 'Apocalipse', abbreviation: 'Re', totalChapters: 22, isHebrew: false, category: 'revelation'),
  ];

  static const List<BibleVerseItem> genesis1FallbackVerses = [
    BibleVerseItem(
      verseNumber: 1,
      text: 'No princípio Deus criou os céus e a terra.',
      tokens: [
        BibleVerseToken.text('No princípio Deus criou os céus e a terra. '),
        BibleVerseToken.crossRef(crossRefTarget: 'nwt:1:1:1', text: 'a'),
      ],
    ),
    BibleVerseItem(
      verseNumber: 2,
      text: 'A terra era vazia e deserta, e havia escuridão sobre as águas profundas; e a força ativa de Deus movia-se sobre as águas.',
      tokens: [
        BibleVerseToken.text('A terra era vazia'),
        BibleVerseToken.footnote(footnoteId: 'fn1', footnoteText: 'Vazia: Sem forma e desolada, aguardando a preparação para a vida.', text: '*'),
        BibleVerseToken.text(' e deserta, e havia escuridão sobre as águas profundas; '),
        BibleVerseToken.crossRef(crossRefTarget: 'nwt:1:1:2', text: 'b'),
        BibleVerseToken.text(' e a força ativa '),
        BibleVerseToken.crossRef(crossRefTarget: 'nwt:1:1:2c', text: 'c'),
        BibleVerseToken.text(' de Deus movia-se sobre as águas. '),
        BibleVerseToken.crossRef(crossRefTarget: 'nwt:1:1:2d', text: 'd'),
      ],
    ),
    BibleVerseItem(
      verseNumber: 3,
      text: 'E Deus disse: "Que haja luz." Então houve luz.',
      tokens: [
        BibleVerseToken.text('E Deus disse: “Que haja luz.” Então houve luz. '),
        BibleVerseToken.crossRef(crossRefTarget: 'nwt:1:1:3', text: 'e'),
      ],
    ),
    BibleVerseItem(
      verseNumber: 4,
      text: 'Depois disso Deus viu que a luz era boa, e Deus começou a separar a luz da escuridão.',
      tokens: [
        BibleVerseToken.text('Depois disso Deus viu que a luz era boa, e Deus começou a separar a luz da escuridão. '),
      ],
    ),
    BibleVerseItem(
      verseNumber: 5,
      text: 'Deus chamou a luz de "dia", mas a escuridão chamou de "noite". Houve noite e houve manhã, primeiro dia.',
      tokens: [
        BibleVerseToken.text('Deus chamou a luz de “dia”, mas a escuridão chamou de “noite”. '),
        BibleVerseToken.crossRef(crossRefTarget: 'nwt:1:1:5', text: 'f'),
        BibleVerseToken.text(' Houve noite e houve manhã, primeiro dia.'),
      ],
    ),
    BibleVerseItem(
      verseNumber: 6,
      text: 'Então Deus disse: "Haja uma expansão no meio das águas, e haja separação entre águas e águas."',
    ),
    BibleVerseItem(
      verseNumber: 7,
      text: 'Deus passou então a fazer a expansão e a fazer separação entre as águas que deviam ficar debaixo da expansão e as águas que deviam ficar por cima da expansão. E assim se fez.',
    ),
    BibleVerseItem(
      verseNumber: 8,
      text: 'E Deus começou a chamar a expansão de "Céus". E veio a ser noitinha e veio a ser manhã, segundo dia.',
    ),
  ];

  /// Artigos de Introdução completos (20 Perguntas Canônicas + Visões Gerais de Estudo)
  static const List<BibleArticleDocument> introductionArticles = [
    BibleArticleDocument(
      id: 'intro_overview',
      title: 'Visão Geral da Edição de Estudo',
      subtitle: 'A Bíblia é a Palavra inspirada de Deus para a humanidade',
      category: 'intro',
      content: 'A Bíblia Sagrada é uma coletânea de 66 livros inspirados por Deus, divididos em duas partes principais: Escrituras Hebraico-Aramaicas (39 livros) e Escrituras Gregas Cristãs (27 livros).\n\nA Edição de Estudo da Tradução do Novo Mundo inclui notas explicativas ricas, referências marginais em cadeia, introduções temáticas e mapas detalhados.',
    ),
    BibleArticleDocument(
      id: 'intro_canon',
      title: 'O Cânon Bíblico e sua Preservação',
      subtitle: 'Como os textos sagrados foram preservados através dos séculos',
      category: 'intro',
      content: 'A palavra cânon refere-se à coleção de livros autênticos e inspirados que servem como padrão de adoração. Os copistas massoretas preservaram o texto hebraico com precisão absoluta, como comprovado pelos Rolos do Mar Morto.',
    ),
    BibleArticleDocument(
      id: 'intro_divine_name',
      title: 'O Nome Divino na Bíblia',
      subtitle: 'O significado do sagrado Tetragrama YHWH (Jeová)',
      category: 'intro',
      content: 'O nome pessoal de Deus ocorre quase 7.000 vezes no texto hebraico original. Significa "Ele Faz com que Venha a Ser", destacando que Ele cumpre infalivelmente todas as suas promessas (Salmos 83:18).',
    ),
    BibleArticleDocument(
      id: 'intro_theme',
      title: 'O Tema Central das Escrituras',
      subtitle: 'A vindicação da soberania divina e o Reino celestial',
      category: 'intro',
      content: 'Do Gênesis ao Apocalipse, a Bíblia desenvolve um tema central harmonioso: a vindicação da soberania de Jeová e a realização de seu propósito eterno por meio de Jesus Cristo (Gênesis 3:15; Daniel 2:44).',
    ),
    BibleArticleDocument(
      id: 'q1',
      title: '1. Quem é Deus?',
      subtitle: 'O Criador Supremo, seu nome e suas qualidades sublimes',
      category: 'intro',
      content: 'O Deus verdadeiro é o Criador de todas as coisas. Ele não teve princípio e nunca terá fim (Salmo 90:2). Ele é a Fonte de toda a vida e tem poder ilimitado (Revelação [Apocalipse] 4:11).\n\nDeus é uma pessoa espiritual com sentimentos. Suas qualidades principais são o amor, a justiça, a sabedoria e o poder (1 João 4:8; Salmo 83:18). Seu nome sagrado é Jeová.',
    ),
    BibleArticleDocument(
      id: 'q2',
      title: '2. Como podemos conhecer a Deus?',
      subtitle: 'Por meio da criação e do estudo da Palavra escrita',
      category: 'intro',
      content: 'A criação revela o imenso poder e a sabedoria de Deus (Romanos 1:20). No entanto, a forma principal de conhecê-lo é lendo a Bíblia, onde Ele revela seu nome, sua personalidade e como podemos nos tornar seus amigos íntimos (João 17:3; Tiago 4:8).',
    ),
    BibleArticleDocument(
      id: 'q3',
      title: '3. Quem escreveu a Bíblia?',
      subtitle: 'Homens fiéis inspirados pelo espírito santo de Deus',
      category: 'intro',
      content: 'A Bíblia foi escrita por cerca de 40 homens fiéis ao longo de 1.600 anos. Embora tenham vivido em épocas diferentes, seus escritos têm harmonia absoluta porque foram inspirados pelo espírito santo de Deus (2 Pedro 1:21; 2 Timóteo 3:16). O Autor supremo é Jeová.',
    ),
    BibleArticleDocument(
      id: 'q4',
      title: '4. A Bíblia é exata do ponto de vista científico?',
      subtitle: 'Harmonia com a ciência comprovada antes do tempo',
      category: 'intro',
      content: 'A Bíblia mencionou a Terra suspensa sobre o nada (Jó 26:7), o formato esférico do planeta (Isaías 40:22) e o ciclo hidrológico das águas (Eclesiastes 1:7) séculos antes de serem descobertos pela ciência moderna.',
    ),
    BibleArticleDocument(
      id: 'q5',
      title: '5. Qual é a mensagem da Bíblia?',
      subtitle: 'A soberania de Jeová e o propósito do Reino',
      category: 'intro',
      content: 'O tema central é a santificação do nome de Deus e a realização de seu propósito eterno para a Terra por meio do Reino celestial de Jesus Cristo (Gênesis 3:15; Daniel 2:44; Mateus 6:10).',
    ),
    BibleArticleDocument(
      id: 'q6',
      title: '6. O que a Bíblia predisse sobre o Messias?',
      subtitle: 'Dezenas de profecias cumpridas em Jesus Cristo',
      category: 'intro',
      content: 'Predisse o local exato do nascimento em Belém (Miqueias 5:2), a linhagem de Davi (Isaías 11:1), a traição por 30 moedas de prata (Zacarias 11:12) e que suas vestes seriam sorteadas (Salmo 22:18).',
    ),
    BibleArticleDocument(
      id: 'q7',
      title: '7. O que a Bíblia predisse sobre os nossos dias?',
      subtitle: 'O sinal composto dos últimos dias',
      category: 'intro',
      content: 'Jesus predisse guerras em escala global, terremotos, pestes, fomes e desamor nas famílias (Mateus 24:3-14; 2 Timóteo 3:1-5), além da pregação mundial do Reino de Deus em toda a Terra.',
    ),
    BibleArticleDocument(
      id: 'q8',
      title: '8. É Deus o culpado pelo sofrimento?',
      subtitle: 'Deus nunca causa o mal nem as tragédias humanas',
      category: 'intro',
      content: 'Com coisas más Deus não prova a ninguém (Tiago 1:13). O sofrimento resulta das escolhas erradas dos humanos, imprevistos (Eclesiastes 9:11) e do governo de Satanás sobre o mundo (1 João 5:19).',
    ),
    BibleArticleDocument(
      id: 'q9',
      title: '9. Por que o sofrimento existe?',
      subtitle: 'A questão levantada no Éden e a resposta divina',
      category: 'intro',
      content: 'No Éden, Satanás questionou a soberania divina. Deus concedeu tempo aos humanos para governarem a si mesmos, provando definitivamente que o homem precisa da orientação do Criador (Jeremias 10:23).',
    ),
    BibleArticleDocument(
      id: 'q10',
      title: '10. Que esperança há para os mortos?',
      subtitle: 'A maravilhosa garantia da ressurreição',
      category: 'intro',
      content: 'Os mortos estão inconscientes e não sofrem (Eclesiastes 9:5, 10). Jesus garantiu que todos os que estão nos túmulos memoriais ouvirão a sua voz e sairão para a ressurreição na Terra (João 5:28, 29).',
    ),
    BibleArticleDocument(
      id: 'q11',
      title: '11. O que é o Reino de Deus?',
      subtitle: 'Um governo celestial real estabelecido por Deus',
      category: 'intro',
      content: 'É um governo real nos céus com Jesus Cristo como Rei e 144.000 corregentes escolhidos dentre a humanidade fiel (Daniel 2:44; Revelação 14:1-4).',
    ),
    BibleArticleDocument(
      id: 'q12',
      title: '12. O que o Reino fará no futuro?',
      subtitle: 'Fim das guerras, doenças e da morte',
      category: 'intro',
      content: 'Eliminará todos os governos corruptos, acabará com as guerras (Salmo 46:9), curará todas as enfermidades (Isaías 35:5, 6) e eliminará para sempre a morte e a dor (Revelação 21:3, 4).',
    ),
    BibleArticleDocument(
      id: 'q13',
      title: '13. O que a Bíblia diz sobre a oração?',
      subtitle: 'Como falar com o Ouvinte de Oração',
      category: 'intro',
      content: 'Devemos orar exclusivamente a Jeová por meio de Jesus Cristo (João 14:6), com fé e de acordo com a sua vontade soberana (1 João 5:14; Filipenses 4:6, 7).',
    ),
    BibleArticleDocument(
      id: 'q14',
      title: '14. Como ter uma família feliz?',
      subtitle: 'Princípios bíblicos práticos para o lar',
      category: 'intro',
      content: 'Maridos devem amar as esposas com ternura, esposas devem demonstrar profundo respeito e pais devem educar seus filhos com carinho e paciência (Efésios 5:25, 33; 6:1-4).',
    ),
    BibleArticleDocument(
      id: 'q15',
      title: '15. Como escolher a religião verdadeira?',
      subtitle: 'Amor fraternal genuíno e fidelidade à Bíblia',
      category: 'intro',
      content: 'Reconhece-se pelos frutos: baseia ensinos unicamente na Bíblia, honra o nome Jeová, pratica o amor sincero e recusa-se a participar de guerras (João 13:34, 35; Mateus 24:14).',
    ),
    BibleArticleDocument(
      id: 'q16',
      title: '16. Por que obedecer às leis de Deus?',
      subtitle: 'Proteção, paz interior e verdadeira liberdade',
      category: 'intro',
      content: 'Os mandamentos de Deus não são pesados (1 João 5:3). Eles nos protegem de perigos morais e físicos e resultam em verdadeira paz interior (Isaías 48:17, 18).',
    ),
    BibleArticleDocument(
      id: 'q17',
      title: '17. Como lidar com a ansiedade?',
      subtitle: 'Paz mental confiando nos cuidados de Jeová',
      category: 'intro',
      content: 'Entregar as ansiedades a Deus por meio de oração confiante e lançar sobre Ele todo o nosso fardo, sabendo que Ele cuida de nós com ternura (Filipenses 4:6, 7; 1 Pedro 5:7).',
    ),
    BibleArticleDocument(
      id: 'q18',
      title: '18. O que é o Dia do Julgamento?',
      subtitle: 'Período de mil anos de bênçãos e restauração',
      category: 'intro',
      content: 'Não é uma catástrofe de 24 horas, mas um período milenar de justiça sob Cristo que transformará a Terra em paraíso após a eliminação da maldade no Armagedom (Revelação 20:11-13).',
    ),
    BibleArticleDocument(
      id: 'q19',
      title: '19. Como se aproximar de Deus?',
      subtitle: 'Cultivar uma amizade pessoal diária com o Criador',
      category: 'intro',
      content: 'Achegar-se a Deus por meio da oração diária, da leitura e meditação na Bíblia e da associação regular com outros que O servem (Tiago 4:8; Salmo 73:28).',
    ),
    BibleArticleDocument(
      id: 'q20',
      title: '20. Como a Bíblia pode ajudar você?',
      subtitle: 'Orientação segura para a vida e esperança eterna',
      category: 'intro',
      content: 'A Bíblia ilumina nosso caminho (Salmo 119:105), dá consolo nas aflições e proporciona a esperança firme da vida eterna sem lágrimas nem dor (Revelação 21:4).',
    ),
  ];

  /// Tópicos Temáticos para Busca Rápida no Índice de Palavras
  static const List<BibleIndexTopic> indexTopics = [
    BibleIndexTopic(title: 'Amor', category: 'Qualidades', scriptures: ['1 Coríntios 13:4-8', '1 João 4:8', 'João 3:16', 'Mateus 22:37-39']),
    BibleIndexTopic(title: 'Oração', category: 'Adoração', scriptures: ['Filipenses 4:6, 7', 'Mateus 6:9-13', 'Salmos 65:2', '1 Tessalonicenses 5:17']),
    BibleIndexTopic(title: 'Fé', category: 'Qualidades', scriptures: ['Hebreus 11:1', 'Hebreus 11:6', 'Tiago 2:17', 'Romanos 10:17']),
    BibleIndexTopic(title: 'Reino de Deus', category: 'Profecias', scriptures: ['Mateus 6:10', 'Mateus 24:14', 'Daniel 2:44', 'Apocalipse 11:15']),
    BibleIndexTopic(title: 'Ressurreição', category: 'Esperança', scriptures: ['João 5:28, 29', 'Atos 24:15', '1 Coríntios 15:20-22', 'Apocalipse 20:13']),
    BibleIndexTopic(title: 'Esperança', category: 'Esperança', scriptures: ['Apocalipse 21:3, 4', 'Salmos 37:11', 'Jeremias 29:11', 'Romanos 15:13']),
    BibleIndexTopic(title: 'Paz', category: 'Qualidades', scriptures: ['Salmos 37:11', 'Filipenses 4:7', 'Isaías 9:6', 'João 14:27']),
    BibleIndexTopic(title: 'Criação', category: 'História', scriptures: ['Gênesis 1:1', 'Salmos 104:24', 'Romanos 1:20', 'Apocalipse 4:11']),
    BibleIndexTopic(title: 'Perdão', category: 'Qualidades', scriptures: ['Salmos 86:5', 'Mateus 6:14, 15', 'Colossenses 3:13', '1 João 1:9']),
    BibleIndexTopic(title: 'Sabedoria', category: 'Qualidades', scriptures: ['Provérbios 3:13-18', 'Tiago 1:5', 'Provérbios 2:6', 'Salmos 111:10']),
    BibleIndexTopic(title: 'Consolo', category: 'Esperança', scriptures: ['2 Coríntios 1:3, 4', 'Salmos 34:18', 'Salmos 23:1-4', 'Mateus 11:28-30']),
    BibleIndexTopic(title: 'Família', category: 'Vida Cristã', scriptures: ['Efésios 5:22-33', 'Efésios 6:1-4', 'Colossenses 3:18-21', 'Provérbios 22:6']),
    BibleIndexTopic(title: 'Paciência', category: 'Qualidades', scriptures: ['Gálatas 5:22', 'Tiago 5:7, 8', '1 Coríntios 13:4', 'Colossenses 3:12']),
    BibleIndexTopic(title: 'Justiça', category: 'Qualidades', scriptures: ['Miqueias 6:8', 'Salmos 37:28', 'Isaías 32:1', 'Mateus 6:33']),
  ];

  /// Apêndices Canônicos da Edição de Estudo (A1 a A7 e B1 a B16)
  static const List<BibleArticleDocument> appendixArticles = [
    BibleArticleDocument(
      id: 'app_a1',
      title: 'A1: Princípios de Tradução da Bíblia',
      subtitle: 'Exatidão, clareza e fidelidade aos manuscritos mais antigos',
      category: 'appendix_a',
      content: 'A Tradução do Novo Mundo visa transmitir com fidelidade e clareza os pensamentos originais:\n\n- Tradução literal sempre que possível sem comprometer a clareza.\n- Equivalência idiomática fiel para termos hebraicos e gregos.\n- Linguagem moderna e acessível para o leitor de hoje.',
    ),
    BibleArticleDocument(
      id: 'app_a2',
      title: 'A2: Características desta Edição de Estudo',
      subtitle: 'Notas de rodapé, notas de estudo e referências cruzadas',
      category: 'appendix_a',
      content: 'Esta edição traz notas explicativas de termos originais ("Lit.:"), referências marginais que ligam profecias aos cumprimentos e notas contextuais detalhadas sobre história e geografia.',
    ),
    BibleArticleDocument(
      id: 'app_a3',
      title: 'A3: Como a Bíblia Chegou Até Nós',
      subtitle: 'Transmissão manuscrita meticulosa e preservação divina',
      category: 'appendix_a',
      content: 'Dos escribas massoretas aos Rolos do Mar Morto e mais de 5.000 manuscritos gregos antigos (como os Códices Sinaítico e Vaticano), a Bíblia possui a história de preservação mais bem documentada da antiguidade.',
    ),
    BibleArticleDocument(
      id: 'app_a4',
      title: 'A4: O Nome Divino nas Escrituras Hebraicas',
      subtitle: 'Restauração do sagrado Tetragrama nas 6.973 ocorrências',
      category: 'appendix_a',
      content: 'O Tetragrama YHWH (יהוה) é a palavra mais frequente na Bíblia hebraica. A Tradução do Novo Mundo restaura reverentemente o nome Jeová em todas as suas ocorrências originais (Salmo 83:18).',
    ),
    BibleArticleDocument(
      id: 'app_a5',
      title: 'A5: O Nome Divino nas Escrituras Gregas',
      subtitle: 'Evidências textuais e históricas do uso do nome Jeová',
      category: 'appendix_a',
      content: 'Fragmentos antigos da Septuaginta grega continham o Tetragrama hebraico. Jesus e seus apóstolos pronunciavam o nome divino ao ler profecias, motivando a restauração de Jeová 237 vezes no Novo Testamento.',
    ),
    BibleArticleDocument(
      id: 'app_a6',
      title: 'A6: Cronologia dos Reis e Profetas',
      subtitle: 'Tabela cronológica de Saul ao cativeiro babilônico',
      category: 'appendix_a',
      content: 'Abrange a monarquia unida sob Saul, Davi e Salomão, a divisão em Judá e Israel em 997 AEC, e a atuação dos profetas Elias, Isaías e Jeremias até o retorno do exílio em 537 AEC.',
    ),
    BibleArticleDocument(
      id: 'app_a7',
      title: 'A7: Panorama da Vida Terrestre de Jesus',
      subtitle: 'Harmonia cronológica dos quatro relatos evangélicos',
      category: 'appendix_a',
      content: 'Sintetiza as fases fundamentais: nascimento em Belém, início do ministério no batismo, grande ministério na Galileia, viagens na Pereia e a semana final redentora em Jerusalém.',
    ),
    BibleArticleDocument(
      id: 'app_b1',
      title: 'B1: A Mensagem da Bíblia em Panorama',
      subtitle: 'A narrativa dos propósitos divinos de Gênesis a Apocalipse',
      category: 'appendix_b',
      content: 'Do Éden à Nova Jerusalém: a promessa de Gênesis 3:15, as alianças patriarcais, a redenção por Cristo e a restauração do Paraíso terrestre.',
    ),
    BibleArticleDocument(
      id: 'app_b2',
      title: 'B2: O Tabernáculo e o Sumo Sacerdote',
      subtitle: 'A tenda portátil de adoração no deserto e vestes sagradas',
      category: 'appendix_b',
      content: 'Detalha o Pátio com o altar de cobre, o Santo com o candelabro de ouro e o Santíssimo com a sagrada Arca do Pacto e o peitoral sacerdotal com 12 pedras preciosas.',
    ),
    BibleArticleDocument(
      id: 'app_b3',
      title: 'B3: O Templo de Salomão',
      subtitle: 'O centro sagrado de adoração construído no Monte Moriá',
      category: 'appendix_b',
      content: 'Edificado com pedras lavradas, cedro e ouro puro, apresentando as colunas Jaquim e Boaz e o grande mar de cobre fundido para purificação.',
    ),
    BibleArticleDocument(
      id: 'app_b4',
      title: 'B4: O Templo Reconstruído por Herodes',
      subtitle: 'O complexo de adoração visitado por Jesus e seus discípulos',
      category: 'appendix_b',
      content: 'A grande ampliação da esplanada, o pátio dos gentios e a imensa cortina do templo que se rasgou ao meio por ocasião da morte de Cristo.',
    ),
    BibleArticleDocument(
      id: 'app_b5',
      title: 'B5: Jerusalém nos Dias de Jesus',
      subtitle: 'Muralhas, colinas históricas e locais do ministério de Cristo',
      category: 'appendix_b',
      content: 'O Monte das Oliveiras, Getsêmani, Vale do Cedrom, Vale de Hinom (Geena), Tanques de Betesda e Siloé e o Monte Gólgota.',
    ),
    BibleArticleDocument(
      id: 'app_b6',
      title: 'B6: A Terra Prometida e as 12 Tribos',
      subtitle: 'A partilha territorial liderada por Josué',
      category: 'appendix_b',
      content: 'A divisão territorial das tribos entre o Rio Jordão e o Grande Mar, destacando os territórios de Judá, Benjamim e as tribos galileias.',
    ),
    BibleArticleDocument(
      id: 'app_b7',
      title: 'B7: O Mundo das Escrituras Hebraicas',
      subtitle: 'As grandes superpotências antigas e rotas comerciais',
      category: 'appendix_b',
      content: 'O contexto geopolítico do Crescente Fértil: Egito, Assíria, Babilônia e Medo-Pérsia em cumprimento às profecias de Daniel.',
    ),
    BibleArticleDocument(
      id: 'app_b8',
      title: 'B8: A Terra Prometida nos Dias de Jesus',
      subtitle: 'Divisões administrativas: Galileia, Samaria e Judeia',
      category: 'appendix_b',
      content: 'A organização provincial sob o domínio romano com os procuradores e a região da Decápole e Pereia.',
    ),
    BibleArticleDocument(
      id: 'app_b9',
      title: 'B9: Ministério de Jesus na Galileia',
      subtitle: 'Cidades ao redor do Mar da Galileia: Cafarnaum e Caná',
      category: 'appendix_b',
      content: 'Os locais dos maiores milagres e ensinos de Jesus, incluindo o Sermão do Monte e a chamada dos apóstolos pescadores.',
    ),
    BibleArticleDocument(
      id: 'app_b10',
      title: 'B10: Viagens na Pereia e Judeia',
      subtitle: 'Pregação itinerante final antes da Páscoa de 33 EC',
      category: 'appendix_b',
      content: 'Visitas a Jericó, encontro com Zaqueu e a ressurreição triunfal de Lázaro em Betânia.',
    ),
    BibleArticleDocument(
      id: 'app_b11',
      title: 'B11: O Ministério Final em Jerusalém',
      subtitle: 'Cronologia dia a dia da última semana terrestre de Jesus',
      category: 'appendix_b',
      content: 'Entrada triunfal, expulsão dos cambistas, a profecia no Monte das Oliveiras, a Ceia do Senhor, o julgamento e a ressurreição.',
    ),
    BibleArticleDocument(
      id: 'app_b12',
      title: 'B12: O Mundo das Escrituras Gregas',
      subtitle: 'O Império Romano e a expansão rápida do evangelho',
      category: 'appendix_b',
      content: 'A vasta malha viária romana e a segurança naval que permitiram a rápida propagação das boas novas por todo o mundo mediterrâneo.',
    ),
    BibleArticleDocument(
      id: 'app_b13',
      title: 'B13: As Viagens Missionárias de Paulo',
      subtitle: 'As viagens evangelizadoras pela Ásia Menor, Grécia e Roma',
      category: 'appendix_b',
      content: 'As três grandes jornadas apostólicas fundando congregações em Filipos, Tessalônica, Corinto e Éfeso, culminando em Roma.',
    ),
    BibleArticleDocument(
      id: 'app_b14',
      title: 'B14: Moedas e Dinheiro no Mundo Bíblico',
      subtitle: 'Lépton, quadrante, denário, dracma e talento',
      category: 'appendix_b',
      content: 'Tabela comparativa do valor do dinheiro no primeiro século: desde o lépton da viúva até o denário diário e o talento de prata.',
    ),
    BibleArticleDocument(
      id: 'app_b15',
      title: 'B15: Pesos e Medidas no Mundo Bíblico',
      subtitle: 'Côvado, estádio, ômer, efa, bato e hine',
      category: 'appendix_b',
      content: 'Equivalências métricas das medidas de comprimento, secos e líquidos utilizadas nas Escrituras.',
    ),
    BibleArticleDocument(
      id: 'app_b16',
      title: 'B16: O Calendário Bíblico e as Estações',
      subtitle: 'Meses lunares, colheitas agrícolas e festividades sagradas',
      category: 'appendix_b',
      content: 'O ciclo agrícola desde a cevada em Nisã até as uvas e azeitonas no outono, com as três grandes festividades anuais de Jeová.',
    ),
  ];

  /// Introdução com ficha técnica oficial para cada livro bíblico
  static BibleArticleDocument getBookIntroduction(BibleBook book) {
    final meta = _bookMetadata[book.id] ?? _defaultMeta(book);
    return BibleArticleDocument(
      id: 'intro_book_${book.id}',
      title: 'Introdução a ${book.name}',
      subtitle: '${meta.writer} • Concluído em ${meta.writtenCompleted}',
      category: 'intro',
      content: 'FICHA TÉCNICA:\n\n'
          '• Escritor: ${meta.writer}\n'
          '• Lugar da escrita: ${meta.writtenPlace}\n'
          '• Escrita completada: ${meta.writtenCompleted}\n'
          '• Período abrangido: ${meta.periodCovered}\n'
          '• Total de capítulos: ${book.totalChapters}\n\n'
          'VISÃO GERAL DO LIVRO:\n\n'
          '${meta.summary}',
    );
  }

  static _BookIntroMeta _defaultMeta(BibleBook book) {
    return _BookIntroMeta(
      writer: book.isHebrew ? 'Profeta e servo fiel inspirado' : 'Apóstolo ou discípulo de Cristo',
      writtenPlace: 'Israel e terras bíblicas',
      writtenCompleted: 'Preservado no Cânon Sagrado',
      periodCovered: 'História sagrada e profética',
      summary: 'O livro de ${book.name} faz parte integrante da Palavra inspirada de Deus (2 Timóteo 3:16), '
          'harmonizando-se perfeitamente com a vindicação da soberania de Jeová e o Reino Messiânico.',
    );
  }

  static const Map<int, _BookIntroMeta> _bookMetadata = {
    1: _BookIntroMeta(writer: 'Moisés', writtenPlace: 'Ermo', writtenCompleted: 'c. 1513 AEC', periodCovered: 'No princípio até 1657 AEC', summary: 'Gênesis significa Origem. Relata a criação divina, a queda no Éden, a profecia em Gênesis 3:15, o Dilúvio global e a aliança com os patriarcas Abraão, Isaque, Jacó e José.'),
    2: _BookIntroMeta(writer: 'Moisés', writtenPlace: 'Ermo', writtenCompleted: '1512 AEC', periodCovered: '1657 a 1512 AEC', summary: 'Êxodo significa Saída. Narra a libertação de Israel do Egito por meio das dez pragas, a travessia do Mar Vermelho, a revelação do nome Jeová e o pacto da Lei no Monte Sinai com o Tabernáculo.'),
    19: _BookIntroMeta(writer: 'Davi e outros', writtenPlace: 'Israel', writtenCompleted: 'c. 460 AEC', periodCovered: 'História poética e profética', summary: 'Salmos é uma coletânea inspirada de 150 cânticos sagrados de louvor, oração e consolo a Jeová, com ricas profecias sobre o Messias como o Bom Pastor.'),
    39: _BookIntroMeta(writer: 'Malaquias', writtenPlace: 'Jerusalém', writtenCompleted: 'depois de 443 AEC', periodCovered: 'Restauração pós-exílica', summary: 'Malaquias significa Meu Mensageiro. Alerta contra a corrupção sacerdotal e culmina com profecias radiantes sobre a vinda do profeta Elias e o brilho do sol da justiça.'),
    40: _BookIntroMeta(writer: 'Mateus (Levi)', writtenPlace: 'Judeia', writtenCompleted: 'c. 41 EC', periodCovered: '2 AEC a 33 EC', summary: 'Mateus demonstra que Jesus é o Messias prometido e herdeiro do trono de Davi, destacando o Sermão do Monte e a comissão de fazer discípulos.'),
    43: _BookIntroMeta(writer: 'Apóstolo João', writtenPlace: 'Éfeso', writtenCompleted: 'c. 98 EC', periodCovered: '29 a 33 EC', summary: 'João foi escrito para que creiamos que Jesus é o Cristo, Filho de Deus. Destaca o amor fraternal, a união com o Pai e a promessa do consolador.'),
    66: _BookIntroMeta(writer: 'Apóstolo João', writtenPlace: 'Patmos', writtenCompleted: 'c. 96 EC', periodCovered: 'Visões proféticas até a eternidade', summary: 'Apocalipse desvenda a vitória do Cordeiro, a derrota de Satanás no Armagedom e a promessa de que a morte e a dor não existirão mais (Revelação 21:4).'),
  };

  static const List<BibleVersion> defaultVersions = [
    BibleVersion(
      id: 'nwtsty_t',
      pubCode: 'nwtsty',
      title: 'Tradução do Novo Mundo da Bíblia Sagrada (Edição de Estudo)',
      shortTitle: 'Bíblia de Estudo',
      languageName: 'Português (Brasil)',
      langCode: 'T',
      sizeLabel: '120 MB',
      sizeBytes: 126325128,
      directUrl: 'https://cfp2.jw-cdn.org/a/5faae3/12/o/nwtsty_T.jwpub',
    ),
    BibleVersion(
      id: 'nwt_t',
      pubCode: 'nwt',
      title: 'Tradução do Novo Mundo da Bíblia Sagrada',
      shortTitle: 'Tradução do Novo Mundo...',
      languageName: 'Português (Brasil)',
      langCode: 'T',
      sizeLabel: '36 MB',
      sizeBytes: 14846651,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_T.epub',
    ),
    BibleVersion(
      id: 'bi12_t',
      pubCode: 'bi12',
      title: 'Tradução do Novo Mundo das Escrituras Sagradas com Referências',
      shortTitle: 'Bíblia com Referências',
      languageName: 'Português (Brasil)',
      langCode: 'T',
      sizeLabel: '28 MB',
      sizeBytes: 3686238,
      directUrl: 'https://cfp2.jw-cdn.org/a/94ab7c/1/o/bi12_T.epub',
    ),
    BibleVersion(
      id: 'nwt_abk',
      pubCode: 'nwt',
      title: 'Аитага «Адунеи ҫыц»',
      shortTitle: 'Аитага «Адунеи ҫыц»',
      languageName: 'Abcázio',
      langCode: 'ABK',
      sizeLabel: '25 MB',
      sizeBytes: 25000000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_ABK.epub',
    ),
    BibleVersion(
      id: 'bi12_abk',
      pubCode: 'bi12',
      title: 'Абиблиатә жәеинраалақәа',
      shortTitle: 'Абиблиатә жәеинраа...',
      languageName: 'Abcázio',
      langCode: 'ABK',
      sizeLabel: '791 KB',
      sizeBytes: 791000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/bi12_ABK.epub',
    ),
    BibleVersion(
      id: 'nwt_abu',
      pubCode: 'nwt',
      title: 'Egbaam Omhoom Abirin',
      shortTitle: 'Egbaam Omhoom Abirin...',
      languageName: 'Abua',
      langCode: 'ABU',
      sizeLabel: '5 MB',
      sizeBytes: 5242880,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_ABU.epub',
    ),
    BibleVersion(
      id: 'nwt_acr',
      pubCode: 'nwt',
      title: 'Ri Utzilaj Tzij re ri Qanimajawal',
      shortTitle: 'Ri Utzilaj Tzij re ri Qanim...',
      languageName: 'Achi (Rabinal)',
      langCode: 'ACR',
      sizeLabel: '5 MB',
      sizeBytes: 5120000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_ACR.epub',
    ),
    BibleVersion(
      id: 'nwt_ach',
      pubCode: 'nwt',
      title: 'Jiri ma Matayo Ocoyo',
      shortTitle: 'Jiri ma Matayo Ocoyo',
      languageName: 'Acholi',
      langCode: 'ACH',
      sizeLabel: '1 MB',
      sizeBytes: 1048576,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_ACH.epub',
    ),
    BibleVersion(
      id: 'nwt_acu',
      pubCode: 'nwt',
      title: 'Yuse Chichame Aarmauri',
      shortTitle: 'Yuse Chichame Aarmauri',
      languageName: 'Achuar-Shiwiar',
      langCode: 'ACU',
      sizeLabel: '7 MB',
      sizeBytes: 7340032,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_ACU.epub',
    ),
    BibleVersion(
      id: 'bi12_acu',
      pubCode: 'bi12',
      title: 'TNM nuya uchichiri irunu',
      shortTitle: 'TNM nuya uchichiri irunu',
      languageName: 'Achuar-Shiwiar',
      langCode: 'ACU',
      sizeLabel: '78 KB',
      sizeBytes: 79872,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/bi12_ACU.epub',
    ),
    BibleVersion(
      id: 'nwt_orm',
      pubCode: 'nwt',
      title: 'Macaafa Qulqulluu Hiika Addunyaa Haaraa',
      shortTitle: 'Hiika Addunyaa Haaraa',
      languageName: 'Afan Oromo',
      langCode: 'ORM',
      sizeLabel: '36 MB',
      sizeBytes: 37748736,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_ORM.epub',
    ),
    BibleVersion(
      id: 'nwt_tpo',
      pubCode: 'nwt',
      title: 'Tradução do Novo Mundo da Bíblia Sagrada',
      shortTitle: 'Tradução do Novo Mundo (Portugal)',
      languageName: 'Português (Portugal)',
      langCode: 'TPO',
      sizeLabel: '15 MB',
      sizeBytes: 15825045,
      directUrl: 'https://cfp2.jw-cdn.org/a/9f7dec4/3/o/nwt_TPO.epub',
    ),
    BibleVersion(
      id: 'nwt_e',
      pubCode: 'nwt',
      title: 'New World Translation of the Holy Scriptures',
      shortTitle: 'New World Translation',
      languageName: 'English',
      langCode: 'E',
      sizeLabel: '15 MB',
      sizeBytes: 15600000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_E.epub',
    ),
    BibleVersion(
      id: 'nwt_s',
      pubCode: 'nwt',
      title: 'Traducción del Nuevo Mundo de las Santas Escrituras',
      shortTitle: 'Traducción del Nuevo Mundo',
      languageName: 'Español',
      langCode: 'S',
      sizeLabel: '15 MB',
      sizeBytes: 15900000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_S.epub',
    ),
  ];

  static const Map<int, String> bi12BookAbbr = {
    1: 'GE', 2: 'EX', 3: 'LE', 4: 'NU', 5: 'DE',
    6: 'JOS', 7: 'JG', 8: 'RU', 9: '1SA', 10: '2SA',
    11: '1KI', 12: '2KI', 13: '1CH', 14: '2CH', 15: 'EZR',
    16: 'NE', 17: 'ES', 18: 'JOB', 19: 'PS', 20: 'PR',
    21: 'EC', 22: 'CA', 23: 'ISA', 24: 'JER', 25: 'LA',
    26: 'EZE', 27: 'DA', 28: 'HO', 29: 'JOE', 30: 'AM',
    31: 'OB', 32: 'JON', 33: 'MIC', 34: 'NA', 35: 'HAB',
    36: 'ZEP', 37: 'HAG', 38: 'ZEC', 39: 'MAL', 40: 'MT',
    41: 'MR', 42: 'LU', 43: 'JOH', 44: 'AC', 45: 'RO',
    46: '1CO', 47: '2CO', 48: 'GA', 49: 'EPH', 50: 'PHP',
    51: 'COL', 52: '1TH', 53: '2TH', 54: '1TI', 55: '2TI',
    56: 'TIT', 57: 'PHM', 58: 'HEB', 59: 'JAS', 60: '1PE',
    61: '2PE', 62: '1JO', 63: '2JO', 64: '3JO', 65: 'JUDE',
    66: 'RE',
  };
}

class _BookIntroMeta {
  final String writer;
  final String writtenPlace;
  final String writtenCompleted;
  final String periodCovered;
  final String summary;

  const _BookIntroMeta({
    required this.writer,
    required this.writtenPlace,
    required this.writtenCompleted,
    required this.periodCovered,
    required this.summary,
  });
}
