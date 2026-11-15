import '../models/bible_model.dart';

class BibleContentCatalog {
  static const List<BibleArticleDocument> introductionArticles = [
    BibleArticleDocument(
      id: 'intro_overview',
      title: 'Visão Geral da Bíblia Sagrada',
      subtitle: 'A Bíblia é a Palavra inspirada de Deus para a humanidade',
      category: 'intro',
      content: 'A Bíblia Sagrada é uma coletânea de 66 livros inspirados por Deus, divididos em duas partes principais: Escrituras Hebraico-Aramaicas (39 livros, de Gênesis a Malaquias) e Escrituras Gregas Cristãs (27 livros, de Mateus a Apocalipse).\n\nFoi escrita ao longo de cerca de 1.600 anos por mais de 40 homens fiéis sob inspiração divina. Apesar de ter sido escrita por pessoas de diversas épocas e formações, apresenta uma harmonia perfeita e um único Autor supremo: Jeová Deus (2 Timóteo 3:16).',
    ),
    BibleArticleDocument(
      id: 'intro_canon',
      title: 'O Cânon Bíblico e sua Preservação',
      subtitle: 'Como os textos sagrados foram preservados através dos séculos',
      category: 'intro',
      content: 'A palavra "cânon" vem de um termo que originalmente significava "cana de medir". No contexto bíblico, refere-se à coleção de livros autênticos e inspirados que servem como padrão fiel de adoração e fé.\n\nOs copistas hebraicos (soferins e massoretas) contavam cada letra e cada palavra para garantir que nenhum erro entrasse no texto. A descoberta dos Rolos do Mar Morto em 1947 comprovou que o texto de Isaías transmitido mil anos mais tarde permaneceu essencialmente inalterado.\n\nPara as Escrituras Gregas Cristãs, existem mais de 5.000 manuscritos em grego antigo, demonstrando uma confiabilidade textual sem paralelo na literatura antiga.',
    ),
    BibleArticleDocument(
      id: 'intro_divine_name',
      title: 'O Nome de Deus na Bíblia',
      subtitle: 'O significado e a importância do Tetragrama Sagrado YHWH (Jeová)',
      category: 'intro',
      content: 'Nas línguas originais da Bíblia, o Deus Todo-Poderoso revela a si mesmo por um nome pessoal sagrado. Nas Escrituras Hebraicas, esse nome aparece representado pelas quatro consoantes YHWH (conhecidas como o Tetragrama).\n\nO nome próprio de Deus ocorre quase 7.000 vezes no texto hebraico original — muito mais do que qualquer outro título como "Senhor" ou "Deus".\n\nO nome significa "Ele Faz com que Venha a Ser", destacando que Ele sempre cumpre todas as suas promessas e se torna tudo o que for necessário para salvar seu povo (Êxodo 3:14; Salmos 83:18).',
    ),
    BibleArticleDocument(
      id: 'intro_theme',
      title: 'O Tema Central da Bíblia',
      subtitle: 'A vindicação da soberania divina e o propósito para a humanidade',
      category: 'intro',
      content: 'Do Gênesis ao Apocalipse, a Bíblia desenvolve um tema central harmonioso: a vindicação da soberania de Deus e a realização de seu propósito para a Terra e a humanidade por meio de seu Reino celestial governado por Jesus Cristo (Gênesis 3:15; Daniel 2:44; Mateus 6:10; Apocalipse 21:3, 4).',
    ),
  ];

  static const List<BibleIndexTopic> indexTopics = [
    BibleIndexTopic(
      title: 'Amor',
      category: 'Qualidades',
      scriptures: ['1 Coríntios 13:4-8', '1 João 4:8', 'João 3:16', 'Mateus 22:37-39', 'Romanos 13:10'],
    ),
    BibleIndexTopic(
      title: 'Oração',
      category: 'Adoração',
      scriptures: ['Filipenses 4:6, 7', 'Mateus 6:9-13', 'Salmos 65:2', '1 Tessalonicenses 5:17', 'Tiago 1:5, 6'],
    ),
    BibleIndexTopic(
      title: 'Fé',
      category: 'Qualidades',
      scriptures: ['Hebreus 11:1', 'Hebreus 11:6', 'Tiago 2:17', 'Romanos 10:17', '2 Coríntios 5:7'],
    ),
    BibleIndexTopic(
      title: 'Reino de Deus',
      category: 'Profecias',
      scriptures: ['Mateus 6:10', 'Mateus 24:14', 'Daniel 2:44', 'Apocalipse 11:15', 'Isaías 9:6, 7'],
    ),
    BibleIndexTopic(
      title: 'Ressurreição',
      category: 'Esperança',
      scriptures: ['João 5:28, 29', 'Atos 24:15', '1 Coríntios 15:20-22', 'Apocalipse 20:13', 'João 11:25'],
    ),
    BibleIndexTopic(
      title: 'Esperança',
      category: 'Esperança',
      scriptures: ['Apocalipse 21:3, 4', 'Salmos 37:11', 'Jeremias 29:11', 'Romanos 15:13', 'Isaías 65:21-23'],
    ),
    BibleIndexTopic(
      title: 'Paz',
      category: 'Qualidades',
      scriptures: ['Salmos 37:11', 'Filipenses 4:7', 'Isaías 9:6', 'João 14:27', 'Romanos 12:18'],
    ),
    BibleIndexTopic(
      title: 'Criação',
      category: 'História',
      scriptures: ['Gênesis 1:1', 'Salmos 104:24', 'Romanos 1:20', 'Apocalipse 4:11', 'Isaías 40:26'],
    ),
    BibleIndexTopic(
      title: 'Perdão',
      category: 'Qualidades',
      scriptures: ['Salmos 86:5', 'Mateus 6:14, 15', 'Colossenses 3:13', '1 João 1:9', 'Isaías 55:7'],
    ),
    BibleIndexTopic(
      title: 'Sabedoria',
      category: 'Qualidades',
      scriptures: ['Provérbios 3:13-18', 'Tiago 1:5', 'Provérbios 2:6', 'Salmos 111:10', 'Tiago 3:17'],
    ),
    BibleIndexTopic(
      title: 'Consolo',
      category: 'Esperança',
      scriptures: ['2 Coríntios 1:3, 4', 'Salmos 34:18', 'Salmos 23:1-4', 'Isaías 41:10', 'Mateus 11:28-30'],
    ),
    BibleIndexTopic(
      title: 'Família',
      category: 'Vida Cristã',
      scriptures: ['Efésios 5:22-33', 'Efésios 6:1-4', 'Colossenses 3:18-21', 'Provérbios 22:6', 'Gênesis 2:24'],
    ),
    BibleIndexTopic(
      title: 'Paciência',
      category: 'Qualidades',
      scriptures: ['Gálatas 5:22', 'Tiago 5:7, 8', '1 Coríntios 13:4', 'Colossenses 3:12', 'Eclesiastes 7:8'],
    ),
    BibleIndexTopic(
      title: 'Justiça',
      category: 'Qualidades',
      scriptures: ['Miqueias 6:8', 'Salmos 37:28', 'Isaías 32:1', 'Provérbios 21:3', 'Mateus 6:33'],
    ),
  ];

  static const List<BibleArticleDocument> appendixArticles = [
    BibleArticleDocument(
      id: 'app_a1',
      title: 'A1: Princípios de Tradução da Bíblia',
      subtitle: 'Exatidão, clareza e fidelidade aos manuscritos mais antigos',
      category: 'appendix_a',
      content: 'A Tradução do Novo Mundo da Bíblia Sagrada é produzida com o compromisso de transmitir com exatidão os pensamentos e o espírito do texto original hebraico, aramaico e grego.\n\nPrincípios:\n- Literal sempre que possível sem obscurecer o sentido.\n- Equivalência exata para expressões idiomáticas antigas.\n- Coerência terminológica para permitir estudos aprofundados.\n- Linguagem moderna e acessível no cotidiano.',
    ),
    BibleArticleDocument(
      id: 'app_a2',
      title: 'A2: O Nome Divino nas Escrituras Hebraicas',
      subtitle: 'A restauração do nome Jeová nos quase 7.000 locais originais',
      category: 'appendix_a',
      content: 'O Tetragrama YHWH (יהוה) é a palavra mais frequente em toda a Bíblia hebraica, aparecendo 6.973 vezes nas Escrituras Hebraico-Aramaicas.\n\nA Tradução do Novo Mundo restaura com coragem e reverência o nome pessoal de Deus em todas as passagens em que o texto original o contém, cumprindo o mandamento de santificar o nome do Altíssimo (Salmos 83:18; Mateus 6:9).',
    ),
    BibleArticleDocument(
      id: 'app_a3',
      title: 'A3: O Nome Divino nas Escrituras Gregas Cristãs',
      subtitle: 'Razões históricas e textuais para o uso de Jeová no Novo Testamento',
      category: 'appendix_a',
      content: 'Fragmentos antigos da Septuaginta grega do tempo de Jesus trazem o Tetragrama em caracteres hebraicos incrustado no texto grego.\n\nQuando Jesus leu profecias como Isaías 61:1 na sinagoga (Lucas 4:18), ele leu o nome sagrado. Com base nisso, o nome Jeová foi restaurado 237 vezes nas Escrituras Gregas Cristãs, especialmente em citações proféticas (João 17:26).',
    ),
    BibleArticleDocument(
      id: 'app_a4',
      title: 'A4: Manuscritos Antigos e Crítica Textual',
      subtitle: 'O Códice de Leningrado, os Rolos de Qumran e a Septuaginta',
      category: 'appendix_a',
      content: 'O texto hebraico básico usado para a Tradução do Novo Mundo é a Biblia Hebraica Stuttgartensia, baseada no Códice de Leningrado B19A (1008 EC).\n\nPara as Escrituras Gregas, o texto mestre de Westcott e Hort (1881) foi extensamente comparado com os Rolos do Mar Morto e papiros antigos, confirmando a fidelidade extraordinária dos textos preservados.',
    ),
    BibleArticleDocument(
      id: 'app_b1',
      title: 'B1: A Mensagem da Bíblia em Panorama',
      subtitle: 'Linha do tempo resumida dos propósitos divinos',
      category: 'appendix_b',
      content: 'A Bíblia narra a grande história do relacionamento de Deus com a humanidade:\n\n- Criação e Éden (c. 4026 AEC): início da vida e a promessa do descendente em Gênesis 3:15.\n- O Dilúvio (2370 AEC): novo começo com a família de Noé.\n- Patriarcas e Israel (1943–1513 AEC): aliança com Abraão e a Lei no Sinai.\n- Reino Messiânico e Triunfo Final: a redenção por Jesus Cristo e o Reino eterno (Apocalipse 21:3-4).',
    ),
    BibleArticleDocument(
      id: 'app_b14',
      title: 'B14: Moedas e Dinheiro no Mundo Bíblico',
      subtitle: 'Lépton, Quadrante, Asse, Denário, Dracma e Talento',
      category: 'appendix_b',
      content: 'Moedas no 1º Século:\n- Lépton (cobre): menor moeda judaica; as duas moedas da viúva (Marcos 12:42).\n- Denário (prata): salário diário de um trabalhador agrícola (Mateus 20:2).\n- Dracma (prata): equivalente grego ao denário (Lucas 15:8).\n- Estáter / Tetradracma: moeda encontrada na boca do peixe para pagar imposto por Jesus e Pedro (Mateus 17:27).\n- Talento: 6.000 denários (trabalho de 20 anos de um homem).',
    ),
    BibleArticleDocument(
      id: 'app_b15',
      title: 'B15: Pesos e Medidas de Comprimento e Volume',
      subtitle: 'Côvado, Braça, Estádio, Efa, Ômer e Bato',
      category: 'appendix_b',
      content: 'Comprimento:\n- Dedo: ~1,85 cm | Palma: ~7,4 cm | Palmo: ~22,2 cm\n- Côvado: ~44,5 cm (do cotovelo à ponta do dedo médio)\n- Estádio: ~185 m (1/8 de milha romana)\n\nSecos e Líquidos:\n- Ômer: ~2,2 L (porção diária de maná por pessoa)\n- Efa / Bato: ~22 L\n- Hine: ~3,67 L de azeite ou vinho',
    ),
    BibleArticleDocument(
      id: 'app_b16',
      title: 'B16: O Calendário Bíblico e as Estações',
      subtitle: 'Meses lunares, colheitas agrícolas e festividades sagradas de Israel',
      category: 'appendix_b',
      content: 'O calendário sagrado começava no mês de Nisã (março-abril) na primavera com a Páscoa e a colheita da cevada.\n\nSeguia-se Sivã (maio-junho) com a colheita do trigo e o Pentecostes, e no outono o mês de Tisri (setembro-outubro) com o Dia da Expiação e a Festividade das Barracas.',
    ),
  ];
}
