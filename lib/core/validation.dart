/// Regole di validazione dei form (SECURITY_AUDIT NIP-10, NIP-24).
///
/// I limiti di lunghezza sono più stretti dei vincoli CHECK del database
/// (supabase/migrations/20261005000000_sync_integrity.sql): un valore
/// accettato dall'app non viene mai rifiutato dal server in sync.
library;

/// Nomi (portafogli, categorie, tag, centri di costo, campi, note spese).
const kMaxNameLength = 100;

/// Descrizione di transazioni e ricorrenze (server: 1000).
const kMaxDescriptionLength = 200;

/// Valore di un campo custom (server: 2000).
const kMaxCustomValueLength = 500;

/// Icona (emoji) di una categoria (server: 64).
const kMaxIconLength = 16;

/// Opzioni di un campo a scelta: numero massimo (server: 200) e lunghezza
/// del testo inserito (separato da virgole).
const kMaxChoiceOptions = 50;
const kMaxChoiceOptionsLength = 2000;

/// Lunghezza minima delle password nuove. Va tenuta allineata alla
/// "Minimum password length" di Supabase Auth (supabase/config.toml e
/// dashboard del progetto): il controllo vero è quello del server.
const kMinPasswordLength = 12;

/// bcrypt (usato da Supabase Auth) considera solo i primi 72 byte.
const kMaxPasswordLength = 72;

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _letter = RegExp(r'[A-Za-z]');
final _digit = RegExp(r'[0-9]');

bool isValidEmail(String value) =>
    value.length <= 254 && _email.hasMatch(value);

/// Password nuova (registrazione, cambio, recupero): almeno
/// [kMinPasswordLength] caratteri, con lettere e numeri.
bool isStrongPassword(String value) =>
    value.length >= kMinPasswordLength &&
    value.length <= kMaxPasswordLength &&
    _letter.hasMatch(value) &&
    _digit.hasMatch(value);
