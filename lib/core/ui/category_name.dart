import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// Nomi delle categorie come vanno mostrati.
///
/// Le categorie di default sono salvate col nome italiano del seed
/// (`kDefaultCategories`): qui diventano la traduzione nella lingua attiva,
/// così cambiano con la lingua dell'app senza toccare i dati (e la sync).
/// Se l'utente le rinomina, il nome salvato non corrisponde più al seed e
/// viene mostrato così com'è.
extension CategoryDisplayName on Category {
  String displayName(AppLocalizations l10n) {
    if (!isDefault) return name;
    return switch (name) {
      'Spesa' => l10n.categoryGroceries,
      'Ristoranti' => l10n.categoryRestaurants,
      'Trasporti' => l10n.categoryTransport,
      'Casa' => l10n.categoryHousing,
      'Svago' => l10n.categoryLeisure,
      'Salute' => l10n.categoryHealth,
      'Shopping' => l10n.categoryShopping,
      'Stipendio' => l10n.categorySalary,
      'Regali' => l10n.categoryGifts,
      'Altro' => l10n.categoryOther,
      _ => name,
    };
  }

  /// Icona + nome, come nei chip e nei menu.
  String label(AppLocalizations l10n) => '$icon ${displayName(l10n)}';
}
