/// Modello contabile delle spese divise nei portafogli (M-SOC4,
/// mds/FRIENDS_PLAN.md): la propria quota è una spesa (conta in statistiche
/// e budget), il resto è un movimento "con amici" che cambia solo il saldo.
///
/// Esempio: A paga 60 € per A, B, C (20 € a testa).
/// - A: spesa 20 € + "verso amici" 40 € → il saldo scende di 60 €, quanto è
///   uscito davvero;
/// - B: spesa 20 € + "da amici" 20 € → il saldo non cambia finché non salda.
/// Un rimborso è "verso amici" per chi paga e "da amici" per chi riceve.
library;

/// Movimenti di un partecipante; 0 = nessun movimento di quel tipo.
typedef ShareMovements = ({
  int expenseCents,
  int friendOutCents,
  int friendInCents,
});

/// Come entra la quota [myShareCents] di una spesa da [totalCents] nel
/// portafoglio di chi partecipa. [iPaid]: ho pagato io il conto.
ShareMovements movementsForShare({
  required bool iPaid,
  required int totalCents,
  required int myShareCents,
}) {
  assert(myShareCents > 0 && myShareCents <= totalCents);
  return iPaid
      ? (
          expenseCents: myShareCents,
          friendOutCents: totalCents - myShareCents,
          friendInCents: 0,
        )
      : (
          expenseCents: myShareCents,
          friendOutCents: 0,
          friendInCents: myShareCents,
        );
}

/// Parti uguali al centesimo: la somma torna sempre col totale e i
/// centesimi di resto vanno ai primi ([people] ≥ 1). Con meno centesimi
/// che persone alcune quote sono 0: il server le rifiuta, la UI lo dice.
List<int> splitEqually(int totalCents, int people) {
  assert(people >= 1 && totalCents >= 0);
  final base = totalCents ~/ people;
  final rest = totalCents % people;
  return [for (var i = 0; i < people; i++) base + (i < rest ? 1 : 0)];
}
