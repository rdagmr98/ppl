import 'package:flutter/material.dart';

/// Bignami PPL(A): promemoria sintetico di formule/regole ricorrenti,
/// nativo Flutter cosi' e' sempre disponibile offline (bundled nell'app,
/// nessuna rete richiesta). Contenuto allineato all'Artifact web omonimo.
class BignamiScreen extends StatelessWidget {
  const BignamiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bignami PPL(A)')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              "Le regole e le formule che ricorrono nella maggior parte delle domande d'esame. Non sostituisce lo studio completo: e' il minimo da sapere a memoria.",
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
          _Panel(
            title: 'Navigazione',
            tag: 'P6',
            children: [
              _P('Triangolo del vento — tre rotte da tenere separate:'),
              _Bullet(
                  'TC rotta vera → TH rotta bussola magnetica (TC ± WCA, poi ± variazione) → CH prua da tenere al compasso (± deviazione)'),
              _Mnemo(
                  'VADO A CASA: Vera → (± Deviazione magnetica) → Magnetica → (± dEviazione compasso) → Compasso, con la Correzione vento (WCA) inserita tra Vera e Magnetica.'),
              _Formula(
                  'GS = TAS ± componente vento lungo rotta\nWCA(°) ≈ 60 × (Wv × sin(angolo vento-rotta)) / TAS'),
              _P("Regola dell'1 in 60: errore laterale, distanza percorsa e angolo di correzione stanno in proporzione:"),
              _Formula('angolo(°) = errore fuori rotta (NM) / distanza percorsa (NM) × 60'),
              _P('Autonomia / carburante residuo:'),
              _Formula(
                  'tempo(h) = distanza / GS\nconsumato = consumo orario × tempo\nresiduo = carburante imbarcato − consumato'),
              _P('Livelli semicircolari VFR (rotta vera, non magnetica):'),
              _Bullet('000°–179° → serie dispari +500ft: FL35, 55, 75, 95…'),
              _Bullet('180°–359° → serie pari +500ft: FL45, 65, 85, 105…'),
              _Mnemo(
                  "tutti i livelli VFR finiscono per 5; sopra/sotto scelgo la parita' in base a dove punta la prua, non a dove sto andando \"in generale\"."),
            ],
          ),
          _Panel(
            title: 'Meteorologia',
            tag: 'P5',
            children: [
              _P('Atmosfera standard (ISA), riferimento per ogni calcolo di quota/temperatura:'),
              _Formula(
                  'Livello del mare: 15°C · 1013,25 hPa\nGradiente termico: −2°C ogni 1000ft\nGradiente di pressione: −1 hPa ogni ~27-30ft (bassa quota)'),
              _P('Base delle nubi (regola pratica, scarto termico T−Td):'),
              _Formula('base nubi (ft) ≈ (T − Td) × 400'),
              _P('METAR essenziale, ordine fisso dei gruppi:'),
              _Example('LIRF 121030Z 24012G22KT 210V270 9999 FEW030 SCT090 22/14 Q1015'),
              _Bullet('vento: dir° vel KT [G raffica]'),
              _Bullet('visibilita\' in metri (9999 = ≥10km)'),
              _Bullet('nubi: FEW < SCT < BKN < OVC, altezza in centinaia di ft (030=3000ft)'),
              _Bullet('T/Td in °C, QNH in hPa dopo Q'),
              _Mnemo("più lo scarto T−Td si avvicina a 0, più è probabile nebbia/nubi basse."),
            ],
          ),
          _Panel(
            title: 'Prestazioni e centraggio',
            tag: 'P3',
            children: [
              _Formula('Momento = Peso × Braccio\nCG = Σ Momenti / Σ Pesi'),
              _P('Allungano la corsa di decollo/atterraggio (ognuno peggiora le prestazioni):'),
              _Bullet('quota densita\' alta (caldo, umido, alta quota)'),
              _Bullet('pista in salita, bagnata, erba/sterrata'),
              _Bullet('vento in coda, peso elevato'),
              _Formula('Quota densita\' ≈ Quota pressione + 120 × (OAT − ISA a quella quota)'),
              _Mnemo('"caldo, umido, alto, pesante, in coda" = pista più lunga, sempre.'),
            ],
          ),
          _Panel(
            title: 'Principi del volo',
            tag: 'P8',
            children: [
              _P("Stallo: distacco del flusso quando si supera l'angolo critico d'attacco — indipendente dalla velocita', può avvenire a qualsiasi IAS (es. virata stretta, manovra brusca)."),
              _P('Fattore di carico in virata (bank angle costante, quota costante):'),
              _Formula('n = 1 / cos(angolo di bank)\nVs(virata) = Vs(livellato) × √n'),
              _Example('bank 60° → n=2 → Vs aumenta di √2 ≈ 1,41×'),
              _P('4 forze: portanza ↕ peso, spinta ↔ resistenza — volo livellato stabilizzato = tutte in equilibrio.'),
            ],
          ),
          _Panel(
            title: 'Fattori umani',
            tag: 'P4',
            children: [
              _P("Tempo di coscienza utile (TUC) in ipossia acuta — diminuisce bruscamente con la quota:"),
              _Bullet('18.000ft ≈ 20-30 min'),
              _Bullet('25.000ft ≈ 3-5 min'),
              _Bullet('35.000ft+ ≈ 30-60 sec'),
              _P("Illusioni vestibolari più citate: somatogravica (accelerazione → falsa sensazione di cabrata), Coriolis (movimento testa in virata prolungata → vertigine), falso orizzonte (pendio/nubi inclinate scambiate per orizzonte)."),
              _Mnemo('in dubbio strumentale: fidati sempre degli strumenti, mai delle sensazioni fisiche.'),
            ],
          ),
          _Panel(
            title: 'Regolamentazione',
            tag: 'P1',
            children: [
              _P('Spazi aerei: A = solo IFR, controllato, separazione totale → G = non controllato, nessuna clearance richiesta. B/C/D/E scalano il livello di controllo e i requisiti di contatto radio nel mezzo.'),
              _P("Precedenze in convergenza: chi ha l'altro aeromobile alla propria destra da' precedenza. Ordine di categoria: pallone frenato/mongolfiera > aliante > dirigibile > aeroplano/elicottero — il meno manovrabile ha sempre la precedenza."),
              _P('Minimi VMC — sotto i 3000ft/1000ft dal suolo, fuori nubi e in vista del suolo basta; sopra, la regola cambia con quota e classe:'),
              _VmcTable(),
              _Mnemo('*5km scende a 1500m se IAS ≤140kt (classe G, circuito/prove in volo) — l\'unica eccezione alla regola dei 5km.'),
            ],
          ),
          _Panel(
            title: 'Velocita\' limite',
            tag: 'P1/P2',
            children: [
              _Formula(
                  'Sotto FL100 (10.000ft): IAS max 250kt (tutti gli spazi)\nClasse D/C, entro 4NM dall\'ARP, sotto 2500ft AGL: IAS max 200kt\nVicino a un aliante in termica: da evitare/rallentare'),
              _P('Velocita\' limite dell\'aeromobile (poligono di manovra):'),
              _Bullet(
                  'Vs0/Vs1 stallo (config. atterraggio/pulita) · Vfe max con flap · Va manovra (sotto: comandi a fondo corsa sicuri) · Vno max normale (inizio arco giallo) · Vne mai da superare'),
              _Mnemo('l\'arco bianco = flap estraibili, il verde = normale operativo, il giallo = solo aria calma, la linea rossa = Vne.'),
            ],
          ),
          _Panel(
            title: 'Pesi',
            tag: 'P3',
            children: [
              _Bullet('Peso a vuoto (a secco) — struttura + motore + equipaggiamento fisso, senza carburante, olio, equipaggio, carico'),
              _Bullet('Peso base a vuoto (BEW) — a vuoto + olio + liquidi non scaricabili (a volte + carburante non utilizzabile)'),
              _Bullet('Peso a vuoto equipaggiato — BEW + dotazioni standard (estintore, kit, ecc.)'),
              _Bullet('Carico utile = MTOW − peso a vuoto equipaggiato (equipaggio+pax+bagagli+carburante)'),
              _Bullet('MTOW/MLW — peso massimo consentito al decollo / atterraggio (MLW può essere < MTOW)'),
              _Formula(
                  'Carico utile = MTOW − Peso a vuoto equipaggiato\nPeso al decollo = Peso a vuoto equip. + equipaggio + pax + bagagli + carburante imbarcato'),
              _Mnemo('"a secco" = zero fluidi consumabili; è sempre il numero più basso tra i pesi a vuoto citati in una domanda.'),
            ],
          ),
          _Panel(
            title: 'Procedure operative',
            tag: 'P7',
            children: [
              _P('Circuito standard (virate standard a sinistra salvo indicazione contraria), quote tipiche AGL:'),
              _Bullet('decollo → salita iniziale dritto fino a ~500ft → virata di crosswind'),
              _Bullet('sottovento (downwind) a quota di circuito (spesso 1000ft AGL) → base → finale allineato pista'),
              _P('Chiamate radio tipiche: in ordine, sottovento → base → finale → "pista libera" dopo l\'atterraggio.'),
              _P('Riattaccata (go-around): motore avanti, assetto di salita, flap ridotti in step, richiudere il circuito senza tagliare la strada a chi è in finale.'),
              _Mnemo('in dubbio su chi ha diritto di pista: chi è già in finale o più basso in fase di atterraggio ha sempre la precedenza su chi decolla o è a terra.'),
            ],
          ),
          _Panel(
            title: 'Strumenti e velocita\'',
            tag: 'P2',
            children: [
              _Formula(
                  'IAS → (errore strumentale/posizione) → CAS\nCAS → (comprimibilita\', rilevante ad alta quota/velocita\') → EAS\nEAS → (densita\' dell\'aria) → TAS'),
              _Mnemo('salendo di quota, a parita\' di IAS la TAS reale è sempre maggiore (aria meno densa).'),
              _P('Altimetro: tre regolazioni sulla finestrella Kollsman:'),
              _Bullet('QNH → legge la quota sul livello del mare'),
              _Bullet('QFE → legge l\'altezza sul campo (indica 0 in pista)'),
              _Bullet('1013 (standard) → legge il livello di volo (FL)'),
            ],
          ),
          _Panel(
            title: 'Comunicazioni',
            tag: 'P9/P10',
            children: [
              _P('Numeri in fraseologia inglese (pronuncia standard, non quella comune):'),
              _Example('tree=3 · fower=4 · fife=5 · niner=9 · decimal=punto'),
              _P('Readback corretto: ripetere sempre il valore numerico ricevuto (frequenza, livello, QNH, transponder) seguito dal proprio nominativo abbreviato — non basta confermare a parole ("wilco", "changing over") se il dato è un numero.'),
              _Mnemo('se la torre da\' un numero, nella risposta quel numero deve ricomparire.'),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              "Estratto dai pattern ricorrenti nel database di 2273 domande ufficiali ENAC/EASA PPL(A) — uso come promemoria, non come unica fonte di studio.",
              style: TextStyle(fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String tag;
  final List<Widget> children;
  const _Panel({required this.title, required this.tag, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: theme.colorScheme.secondary)),
                Text(tag,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const Divider(height: 14),
            ...children,
          ],
        ),
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
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12.5, height: 1.45)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _VmcTable extends StatelessWidget {
  const _VmcTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headStyle = TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.secondary);
    final cellStyle = const TextStyle(fontSize: 11.5, height: 1.3);
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
          row('Dove', 'Visibilita\'', 'Da nubi', head: true),
          row('<3000ft o <1000ft AGL', '5 km*', 'fuori nubi, suolo in vista'),
          row('≥3000ft, sotto FL100', '5 km', '1500m orizz. / 300m (1000ft) vert.'),
          row('a/sopra FL100', '8 km', '1500m orizz. / 300m (1000ft) vert.'),
        ],
      ),
    );
  }
}
