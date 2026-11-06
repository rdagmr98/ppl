import 'dart:math';
import 'package:flutter/material.dart';
import 'ads_service.dart';
import 'builder.dart';
import 'models.dart';
import 'quiz_screen.dart';

/// Bignami PPL(A): promemoria di formule/regole ricorrenti, una scheda per
/// materia ufficiale, argomenti richiudibili, calcolatori "Prova tu" sulle
/// formule e accesso diretto a 10 domande della materia. Nativo Flutter,
/// sempre disponibile offline.
class BignamiScreen extends StatelessWidget {
  final QuizDb db;
  final int? initialParte; // apre la scheda di questa materia (da Statistiche)
  const BignamiScreen({super.key, required this.db, this.initialParte});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _sections.length,
      initialIndex:
          max(0, _sections.indexWhere((s) => s.partes.contains(initialParte))),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bignami PPL(A)'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final s in _sections) Tab(text: s.label)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final s in _sections) _SectionView(section: s, db: db),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String label; // etichetta corta della tab
  final List<int> partes; // materie ufficiali coperte
  final List<_Topic> topics;
  const _Section(this.label, this.partes, this.topics);
}

class _Topic {
  final String title;
  final List<Widget> children;
  const _Topic(this.title, this.children);
}

class _SectionView extends StatelessWidget {
  final _Section section;
  final QuizDb db;
  const _SectionView({required this.section, required this.db});

  void _drill(BuildContext context, Subject s) {
    final questions = buildStudy(s, limit: 10);
    if (questions.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(questions: questions, title: s.name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = [for (final p in section.partes) ?db.byParte(p)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            [for (final p in section.partes) 'P$p ${subjectNames[p]}']
                .join(' · '),
            style: TextStyle(
                fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        for (final t in section.topics) _TopicCard(topic: t),
        const SizedBox(height: 8),
        for (final s in subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _drill(context, s),
                icon: const Icon(Icons.quiz_outlined),
                label: Text('Allenati: 10 domande di ${s.name}'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'Estratto dai pattern ricorrenti nelle domande ufficiali ENAC/EASA PPL(A): promemoria, non unica fonte di studio.',
            style: TextStyle(
                fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const PplNativeAd(adUnitId: AdIds.nativeFooter),
        const SizedBox(height: 8),
        const Center(child: PplBannerAd()),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _Topic topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCalc = topic.children.any((w) => w is _Calc);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // niente linee di divisione di ExpansionTile sopra/sotto
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(children: [
            Expanded(
              child: Text(topic.title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ),
            if (hasCalc)
              Icon(Icons.calculate_outlined, size: 18, color: theme.colorScheme.primary),
          ]),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: topic.children,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenuti
// ---------------------------------------------------------------------------

final _livelliSemicircolari = _Topic('Livelli semicircolari VFR', [
  const _P('Sopra i 3000ft AGL/AMSL, in base alla rotta MAGNETICA:'),
  const _Bullet('000°–179° → migliaia dispari + 500ft: FL35, 55, 75, 95…'),
  const _Bullet('180°–359° → migliaia pari + 500ft: FL45, 65, 85, 105…'),
  const _Mnemo(
      'tutti i livelli VFR finiscono per 5; con rotta vera e declinazione, prima ricava la rotta magnetica.'),
  _Calc(
    labels: const ['Rotta magnetica (°)'],
    initial: const [30],
    compute: (v) {
      final t = v[0] % 360;
      return t < 180
          ? 'Serie dispari: FL35, 55, 75, 95, 115…'
          : 'Serie pari: FL45, 65, 85, 105, 125…';
    },
  ),
]);

final _sections = <_Section>[
  _Section('Regolamentazione', const [1], [
    const _Topic('Spazi aerei', [
      _P('A = solo IFR, controllato, separazione totale → G = non controllato, nessuna autorizzazione richiesta. B/C/D/E scalano nel mezzo il livello di controllo e i requisiti di contatto radio.'),
    ]),
    const _Topic('Precedenze', [
      _P("In convergenza dà precedenza chi ha l'altro aeromobile alla propria destra."),
      _P('Per categoria ha precedenza il meno manovrabile: pallone > aliante > dirigibile > aeroplano/elicottero.'),
    ]),
    const _Topic('Minimi VMC', [
      _VmcTable(),
      _Mnemo(
          '*5 km scende a 1500 m se IAS ≤ 140kt (dove previsto dall\'autorità): l\'unica eccezione alla regola dei 5 km.'),
    ]),
    const _Topic('Limiti di velocità', [
      _Formula(
          'Sotto FL100 (10.000ft): IAS max 250kt\nClasse C/D, entro 4NM dall\'ARP, sotto 2500ft AGL: IAS max 200kt'),
    ]),
    _livelliSemicircolari,
  ]),
  _Section('Aeromobili', const [2], [
    const _Topic('Catena delle velocità', [
      _Formula(
          'IAS → (errore strumentale/di posizione) → CAS\nCAS → (comprimibilità, alta quota/velocità) → EAS\nEAS → (densità dell\'aria) → TAS'),
      _Mnemo('salendo di quota, a parità di IAS la TAS è sempre maggiore (aria meno densa).'),
    ]),
    const _Topic('Altimetro: QNH, QFE, 1013', [
      _Bullet('QNH → indica la quota sul livello del mare'),
      _Bullet('QFE → indica l\'altezza sul campo (0 in pista)'),
      _Bullet('1013 (standard) → indica il livello di volo (FL)'),
    ]),
    const _Topic('Errori della bussola magnetica', [
      _P('In virata (solo su prue N/S, emisfero nord):'),
      _Bullet('Verso Nord la bussola resta indietro: esci dalla virata prima che indichi N'),
      _Bullet('Verso Sud la bussola anticipa: esci dalla virata dopo che ha superato S'),
      _Mnemo('UNOS: Undershoot North, Overshoot South.'),
      _P('In accelerazione/decelerazione (solo su prue E/O, volo livellato):'),
      _Bullet('Accelerando la bussola vira apparentemente verso Nord'),
      _Bullet('Decelerando la bussola vira apparentemente verso Sud'),
      _Mnemo('ANDS: Accelerate North, Decelerate South.'),
    ]),
    const _Topic('Precessione giroscopica', [
      _P('Una forza applicata a una massa rotante (girobussola, orizzonte artificiale) si manifesta 90° più avanti nel senso di rotazione, non nel punto di applicazione.'),
    ]),
    const _Topic('Velocità limite e archi dell\'anemometro', [
      _Bullet('Vs0/Vs1 stallo (configurazione di atterraggio/pulita)'),
      _Bullet('Vfe max con flap · Va manovra (sotto: comandi a fondo corsa sicuri)'),
      _Bullet('Vno max normale (inizio arco giallo) · Vne mai da superare'),
      _Mnemo('arco bianco = flap estraibili, verde = normale operativo, giallo = solo aria calma, linea rossa = Vne.'),
    ]),
  ]),
  _Section('Prestazioni', const [3], [
    const _Topic('Pesi', [
      _Bullet('Peso a vuoto (a secco): struttura + motore + equipaggiamento fisso, senza fluidi consumabili'),
      _Bullet('Peso base a vuoto (BEW): a vuoto + olio + liquidi non scaricabili'),
      _Bullet('Peso a vuoto equipaggiato: BEW + dotazioni standard (estintore, kit…)'),
      _Bullet('Peso operativo a vuoto (OEW): + equipaggio e bagagli, senza pax/carico/carburante'),
      _Bullet('Peso a zero carburante (ZFW): tutto il carico ma senza carburante'),
      _Bullet('MTOW/MLW: peso massimo al decollo / all\'atterraggio (MLW può essere < MTOW)'),
      _Formula(
          'Carico utile = MTOW − peso a vuoto equipaggiato\nZFW = OEW + carico pagante\nPeso al decollo = ZFW + carburante'),
      _Mnemo('"a secco" è sempre il numero più basso; il carburante è l\'ultimo addendo di ogni catena di pesi.'),
    ]),
    _Topic('Centraggio', [
      const _Formula('Momento = Peso × Braccio\nCG = Σ Momenti / Σ Pesi'),
      _Calc(
        labels: const [
          'Peso a vuoto (kg)', 'Braccio (m)',
          'Equipaggio (kg)', 'Braccio (m)',
          'Carburante (kg)', 'Braccio (m)',
        ],
        initial: const [700, 1.0, 160, 0.9, 70, 1.2],
        compute: (v) {
          final w = v[0] + v[2] + v[4];
          final m = v[0] * v[1] + v[2] * v[3] + v[4] * v[5];
          return 'Peso ${_f(w)} kg · momento ${_f(m)} kg·m · CG ${_f(m / w, 3)} m';
        },
      ),
    ]),
    _Topic('Corsa di decollo e quota densità', [
      const _P('Allungano la corsa di decollo/atterraggio:'),
      const _Bullet('quota densità alta (caldo, umido, alta quota)'),
      const _Bullet('pista in salita, bagnata, erba/sterrata'),
      const _Bullet('vento in coda, peso elevato'),
      const _Mnemo('"caldo, umido, alto, pesante, in coda" = pista più lunga, sempre.'),
      const _Formula('Quota densità ≈ Quota pressione + 120 × (OAT − T ISA)'),
      _Calc(
        labels: const ['Quota pressione (ft)', 'OAT (°C)'],
        initial: const [3000, 25],
        compute: (v) {
          final isa = 15 - 2 * v[0] / 1000;
          return 'T ISA ${_f(isa)} °C · quota densità ≈ ${_f(v[0] + 120 * (v[1] - isa), 0)} ft';
        },
      ),
    ]),
  ]),
  _Section('Fattori umani', const [4], [
    const _Topic('Ipossia e tempo di coscienza utile', [
      _P('Il TUC in ipossia acuta crolla con la quota:'),
      _Bullet('18.000ft ≈ 20-30 min'),
      _Bullet('25.000ft ≈ 3-5 min'),
      _Bullet('35.000ft+ ≈ 30-60 s'),
    ]),
    const _Topic('Illusioni vestibolari', [
      _Bullet('Somatogravica: accelerazione → falsa sensazione di cabrata'),
      _Bullet('Coriolis: movimento della testa in virata prolungata → vertigine'),
      _Bullet('Falso orizzonte: pendio o nubi inclinate scambiati per orizzonte'),
      _Mnemo('in dubbio: fidati sempre degli strumenti, mai delle sensazioni.'),
    ]),
  ]),
  _Section('Meteorologia', const [5], [
    _Topic('Atmosfera standard (ISA)', [
      const _Formula(
          'Livello del mare: 15°C · 1013,25 hPa\nGradiente termico: −2°C ogni 1000ft\nPressione: −1 hPa ogni ~27-30ft (bassa quota)'),
      _Calc(
        labels: const ['Quota (ft)'],
        initial: const [5000],
        compute: (v) => 'T ISA ${_f(15 - 2 * v[0] / 1000)} °C',
      ),
    ]),
    const _Topic('Nubi per famiglia', [
      _Bullet('Alte (CI, CC, CS): 6000-12000m, cristalli di ghiaccio'),
      _Bullet('Medie (AC, AS): 2000-6000m, prefisso "alto-"'),
      _Bullet('Basse (ST, SC, NS): suolo-2000m, NS = precipitazione continua'),
      _Bullet('Sviluppo verticale (CU, CB): base bassa, sommità fino alla tropopausa; CB = turbolenza, grandine, wind shear'),
      _Mnemo('"cirro-" = sempre quota alta; "nembo-" = sempre nube da precipitazione.'),
    ]),
    const _Topic('Precipitazioni', [
      _Bullet('ST → pioviggine leggera e continua'),
      _Bullet('NS/AS spessi → pioggia/neve continua su area estesa'),
      _Bullet('CU/CB → rovesci intensi, localizzati e intermittenti'),
      _Bullet('CB maturo → possibile grandine e virga'),
      _Mnemo('nube stratificata = precipitazione continua; sviluppo verticale = rovescio intenso e breve.'),
    ]),
    const _Topic('Fronti', [
      _Bullet('Freddo: triangoli verso l\'avanzamento; avanza veloce, temporali e rovesci brevi'),
      _Bullet('Caldo: semicerchi verso l\'avanzamento; pendenza dolce, nubi stratificate e pioggia continua anche ore prima'),
      _Bullet('Occluso: triangoli e semicerchi alternati sullo stesso lato; il freddo ha raggiunto il caldo'),
      _Bullet('Stazionario: triangoli e semicerchi su lati opposti; il fronte non avanza'),
      _Mnemo('il simbolo sta dalla parte verso cui il fronte si muove; freddo = spigoloso e veloce, caldo = arrotondato e lento.'),
    ]),
    const _Topic('Vento sulle carte', [
      _Bullet('la freccia "vola con il vento": punta verso dove il vento soffia, i segni stanno sulla coda'),
      _Bullet('barba corta 5kt · barba lunga 10kt · triangolo pieno 50kt, si sommano'),
      _Example('due barbe lunghe + una corta = 25kt'),
      _Mnemo('in METAR e fraseologia il vento è invece sempre indicato con la direzione di provenienza.'),
    ]),
    _Topic('Base delle nubi', [
      const _Formula('base nubi (ft) ≈ (T − Td) × 400'),
      _Calc(
        labels: const ['T (°C)', 'Td (°C)'],
        initial: const [22, 14],
        compute: (v) => 'Base nubi ≈ ${_f((v[0] - v[1]) * 400, 0)} ft',
      ),
      const _Mnemo('più T−Td si avvicina a 0, più sono probabili nebbia e nubi basse.'),
    ]),
    const _Topic('METAR essenziale', [
      _Example('LIRF 121030Z 24012G22KT 210V270 9999 FEW030 SCT090 22/14 Q1015'),
      _Bullet('vento: direzione° velocità KT [G raffica]'),
      _Bullet('visibilità in metri (9999 = ≥10 km)'),
      _Bullet('nubi: FEW < SCT < BKN < OVC, altezza in centinaia di ft (030 = 3000ft)'),
      _Bullet('T/Td in °C, QNH in hPa dopo Q'),
    ]),
  ]),
  _Section('Navigazione', const [6], [
    const _Topic('Da rotta vera a prua bussola', [
      _Formula(
          'TC rotta vera ± WCA = TH prua vera\nTH ± declinazione = MH prua magnetica\nMH ± deviazione = CH prua bussola'),
      _Bullet('Declinazione: angolo tra Nord vero e magnetico, dipende dal luogo'),
      _Bullet('Deviazione: errore della bussola di bordo (cartellino di deviazione)'),
      _Bullet('WCA: correzione verso il lato da cui soffia il vento'),
      _Mnemo('da vero a magnetico: declinazione Est si sottrae, Ovest si somma ("East is least, West is best").'),
    ]),
    _Topic('Triangolo del vento', [
      const _Formula(
          'GS = TAS ± componente di vento lungo la rotta\nWCA(°) ≈ 60 × vento al traverso / TAS'),
      _Calc(
        labels: const ['TAS (kt)', 'Vento (kt)', 'Angolo vento-rotta (°)'],
        initial: const [100, 20, 30],
        compute: (v) {
          final a = v[2] * pi / 180;
          final x = v[1] * sin(a) / v[0];
          if (x.abs() > 1) return 'Vento troppo forte per tenere la rotta';
          final wca = asin(x);
          final gs = v[0] * cos(wca) - v[1] * cos(a);
          return 'WCA ${_f(wca * 180 / pi)}° · GS ${_f(gs, 0)} kt';
        },
      ),
      const _Example('angolo 0° = vento in prua · 90° = al traverso · 180° = in coda'),
    ]),
    _Topic('Regola dell\'1 in 60', [
      const _Formula('angolo(°) = fuori rotta (NM) / distanza percorsa (NM) × 60'),
      _Calc(
        labels: const ['Fuori rotta (NM)', 'Distanza percorsa (NM)'],
        initial: const [3, 30],
        compute: (v) => 'Errore angolare ${_f(v[0] / v[1] * 60)}°',
      ),
    ]),
    _Topic('Tempo alla stazione (VOR/NDB)', [
      const _P('Accosta di 90° rispetto alla radiale e cronometra quanto impiega a variare:'),
      const _Formula('tempo alla stazione (min) = T × 60 / D\nT = minuti trascorsi, D = variazione di radiale (°)'),
      _Calc(
        labels: const ['T trascorso (min)', 'Variazione (°)'],
        initial: const [4, 10],
        compute: (v) => 'Tempo alla stazione ${_f(v[0] * 60 / v[1])} min',
      ),
    ]),
    _Topic('Autonomia e carburante', [
      const _Formula(
          'tempo = distanza / GS\nconsumato = consumo orario × tempo\nresiduo = imbarcato − consumato'),
      _Calc(
        labels: const ['Distanza (NM)', 'GS (kt)', 'Consumo (l/h)', 'Imbarcato (l)'],
        initial: const [120, 100, 30, 100],
        compute: (v) {
          final h = v[0] / v[1];
          final used = v[2] * h;
          return 'Tempo ${_hm(h)} · consumati ${_f(used)} l · residuo ${_f(v[3] - used)} l';
        },
      ),
    ]),
    _livelliSemicircolari,
  ]),
  _Section('Procedure', const [7], [
    const _Topic('Circuito di traffico', [
      _P('Virate a sinistra salvo indicazione contraria, quote tipiche AGL:'),
      _Bullet('decollo → salita in asse fino a ~500ft → virata di crosswind'),
      _Bullet('sottovento a quota di circuito (spesso 1000ft) → base → finale'),
      _P('Chiamate radio: sottovento → base → finale → "pista libera" dopo l\'atterraggio.'),
      _Mnemo('chi è in finale o più basso in atterraggio ha precedenza su chi decolla o è a terra.'),
    ]),
    const _Topic('Riattaccata', [
      _P('Motore avanti, assetto di salita, flap ridotti per gradi, richiudere il circuito senza tagliare la strada a chi è in finale.'),
    ]),
  ]),
  _Section('Principi del volo', const [8], [
    const _Topic('Stallo', [
      _P("Distacco del flusso oltre l'angolo d'attacco critico: dipende dall'angolo, non dalla velocità, e può avvenire a qualsiasi IAS (virata stretta, manovra brusca)."),
    ]),
    _Topic('Fattore di carico in virata', [
      const _Formula('n = 1 / cos(bank)\nVs in virata = Vs livellato × √n'),
      _Calc(
        labels: const ['Bank (°)', 'Vs livellato (kt)'],
        initial: const [60, 50],
        compute: (v) {
          if (v[0].abs() >= 90) return 'Bank deve essere < 90°';
          final n = 1 / cos(v[0] * pi / 180);
          return 'n = ${_f(n, 2)} g · Vs in virata ${_f(v[1] * sqrt(n), 0)} kt';
        },
      ),
    ]),
    const _Topic('Le 4 forze', [
      _P('Portanza ↕ peso, spinta ↔ resistenza: in volo livellato stabilizzato sono in equilibrio.'),
    ]),
  ]),
  _Section('Comunicazioni', const [9, 10], [
    const _Topic('Numeri in fraseologia inglese', [
      _Example('tree = 3 · fower = 4 · fife = 5 · niner = 9 · decimal = punto'),
    ]),
    const _Topic('Readback', [
      _P('Ripeti sempre il valore numerico ricevuto (frequenza, livello, QNH, transponder) seguito dal nominativo: "wilco" non basta se il dato è un numero.'),
      _Mnemo('se la torre dà un numero, nella risposta quel numero deve ricomparire.'),
    ]),
  ]),
];

/// Numero in formato italiano, senza zeri decimali inutili.
String _f(num x, [int d = 1]) {
  var s = x.toStringAsFixed(d);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return s.replaceAll('.', ',');
}

String _hm(double h) {
  final m = (h * 60).round();
  return m < 60 ? '$m min' : '${m ~/ 60} h ${m % 60} min';
}

// ---------------------------------------------------------------------------
// Widget di contenuto
// ---------------------------------------------------------------------------

/// Calcolatore "Prova tu": campi numerici con etichetta sopra, risultato
/// ricalcolato a ogni tasto.
class _Calc extends StatefulWidget {
  final List<String> labels;
  final List<double> initial;
  final String Function(List<double> v) compute;
  const _Calc({required this.labels, required this.initial, required this.compute});

  @override
  State<_Calc> createState() => _CalcState();
}

class _CalcState extends State<_Calc> {
  late final _ctrl = [for (final x in widget.initial) TextEditingController(text: _f(x, 3))];

  @override
  void dispose() {
    for (final c in _ctrl) {
      c.dispose();
    }
    super.dispose();
  }

  String get _result {
    final v = [for (final c in _ctrl) double.tryParse(c.text.trim().replaceAll(',', '.'))];
    if (v.contains(null)) return '—';
    final r = widget.compute(v.cast<double>());
    return r.contains('NaN') || r.contains('Infinity') ? '—' : r;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calculate_outlined, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Prova tu',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (var i = 0; i < _ctrl.length; i++)
                SizedBox(
                  width: 128,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.labels[i],
                          style: TextStyle(
                              fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 3),
                      TextField(
                        controller: _ctrl[i],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_result,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
        ],
      ),
    );
  }
}

class _P extends StatelessWidget {
  final String text;
  const _P(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.32)),
      );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ', style: TextStyle(fontSize: 13)),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.3)),
            ),
          ],
        ),
      );
}

class _Formula extends StatelessWidget {
  final String text;
  const _Formula(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
      ),
      child: Text(text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.45)),
    );
  }
}

class _Example extends StatelessWidget {
  final String text;
  const _Example(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _Mnemo extends StatelessWidget {
  final String text;
  const _Mnemo(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 15, color: Color(0xFFFFB300)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _VmcTable extends StatelessWidget {
  const _VmcTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headStyle = TextStyle(
        fontSize: 10.5, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary);
    const cellStyle = TextStyle(fontSize: 11.5, height: 1.3);
    Widget cell(String s, TextStyle style, {int flex = 1}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Text(s, style: style),
          ),
        );
    Widget row(String a, String b, String c, {bool head = false}) => Container(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.6)),
          ),
          child: Row(
            children: [
              cell(a, head ? headStyle : cellStyle, flex: 3),
              cell(b, head ? headStyle : cellStyle, flex: 2),
              cell(c, head ? headStyle : cellStyle, flex: 3),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          row('Dove', 'Visibilità', 'Da nubi', head: true),
          row('<3000ft AMSL o <1000ft AGL', '5 km*', 'fuori nubi, suolo in vista'),
          row('≥3000ft, sotto FL100', '5 km', '1500m orizz. / 300m (1000ft) vert.'),
          row('a/sopra FL100', '8 km', '1500m orizz. / 300m (1000ft) vert.'),
        ],
      ),
    );
  }
}
