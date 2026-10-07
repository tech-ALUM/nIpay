import 'package:uuid/uuid.dart';

/// Namespace UUIDv5 dell'app: fisso, non cambiarlo (cambierebbe gli id).
const _nipayNamespace = '3b0f7c1e-5a52-4f0d-9d3e-6a2c8e41b7d9';

/// Id stabile derivato da una chiave naturale, uguale su ogni device.
///
/// Per le entità che due device possono creare "in parallelo" per la stessa
/// cosa (il budget di una categoria, le categorie di default di un
/// portafoglio): con id casuali la sync produceva duplicati o violava i
/// vincoli unici; con lo stesso id le due copie si fondono (last-write-wins).
/// La chiave contiene sempre l'id (casuale, v4) del portafoglio, quindi non
/// è indovinabile da chi non conosce già i dati.
String deterministicId(String naturalKey) =>
    const Uuid().v5(_nipayNamespace, 'nipay:$naturalKey');
