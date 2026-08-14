import 'package:flutter/material.dart';

/// Le 5 valute più usate al mondo (volume di scambio/riserve), tra quelle
/// supportate — JPY è la più scambiata dopo USD/EUR ma è esclusa (0 decimali,
/// vedi sotto), quindi al suo posto entra CNY.
const kTopCurrencies = ['USD', 'EUR', 'GBP', 'CNY', 'CHF'];

/// Le altre valute curate, in ordine alfabetico.
const kOtherCurrencies = [
  'AUD',
  'BRL',
  'CAD',
  'CZK',
  'DKK',
  'HKD',
  'HUF',
  'INR',
  'MXN',
  'NOK',
  'NZD',
  'PLN',
  'RON',
  'SEK',
  'SGD',
  'TRY',
  'ZAR',
];

/// Tutte le valute supportate: lista curata (non l'intero ISO 4217), tutte a
/// 2 decimali per rispettare l'invariante "importi sempre in centesimi (int)"
/// senza dover gestire valute a 0 decimali (es. JPY) o 3 (es. KWD).
const kCurrencies = [...kTopCurrencies, ...kOtherCurrencies];

/// Simbolo di ciascuna valuta curata. Più valute condividono lo stesso
/// simbolo (es. "$" per USD/CAD/AUD/NZD/SGD/HKD/MXN): nel menu a tendina va
/// comunque bene perché è affiancato al codice ISO, che resta univoco.
const kCurrencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'CNY': '¥',
  'CHF': 'Fr',
  'AUD': '\$',
  'BRL': 'R\$',
  'CAD': '\$',
  'CZK': 'Kč',
  'DKK': 'kr',
  'HKD': '\$',
  'HUF': 'Ft',
  'INR': '₹',
  'MXN': '\$',
  'NOK': 'kr',
  'NZD': '\$',
  'PLN': 'zł',
  'RON': 'lei',
  'SEK': 'kr',
  'SGD': '\$',
  'TRY': '₺',
  'ZAR': 'R',
};

/// Simbolo per [currencyCode]; il codice stesso se non mappato (non
/// dovrebbe succedere per le valute in [kCurrencies]).
String currencySymbol(String currencyCode) =>
    kCurrencySymbols[currencyCode] ?? currencyCode;

/// Le voci del menu a tendina valuta, con le 5 più comuni in cima separate
/// da un divisore dalle altre (in ordine alfabetico). Ogni voce mostra il
/// codice ISO (univoco) affiancato al simbolo, per riconoscerla a colpo
/// d'occhio senza perdere la precisione del codice.
List<DropdownMenuItem<String>> currencyMenuItems() => [
  for (final c in kTopCurrencies)
    DropdownMenuItem(value: c, child: Text('$c ${currencySymbol(c)}')),
  const DropdownMenuItem(enabled: false, child: Divider(height: 1)),
  for (final c in kOtherCurrencies)
    DropdownMenuItem(value: c, child: Text('$c ${currencySymbol(c)}')),
];
