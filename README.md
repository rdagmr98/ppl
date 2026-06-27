# Quiz PPL(A)

App per allenarsi all'esame teorico **PPL(A)** (licenza di pilota privato).
Veloce: tocchi la risposta e vedi subito **verde** se giusta (avanza da sola) o
**rossa** se sbagliata, indicando quella corretta. Nessun "invia / sei sicuro?".

## Modalità
- **Esame completo** — 132 quesiti con la distribuzione ufficiale ENAC per materia.
- **Esame + fonia inglese** — 152 quesiti (132 + 20 di comunicazioni EN).
- **Allenamento rapido** — 30 quesiti casuali.
- **Studio per materia** — scegli materia e numero di domande.

A fine prova: punteggio totale, dettaglio per materia con soglia 75% e revisione degli errori.

## Web app
Disponibile su GitHub Pages: https://rdagmr98.github.io/ppl/

## Database
1384 quesiti del pool ufficiale ENAC/EASA PPL(A), 10 materie. I contenuti del
quiz sono di pubblico dominio aeronautico; l'app è uno strumento di studio gratuito.

## Sviluppo
```
flutter pub get
flutter run                 # debug
flutter build web --release --base-href "/ppl/"
flutter build apk --split-per-abi --release
```
