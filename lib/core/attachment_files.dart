import 'dart:io';

/// Path relativo valido per un allegato: `attachments/<uuid>.<estensione>`,
/// senza separatori né `..`. Copre anche i file salvati dalle versioni
/// precedenti (estensione presa dal nome del file scelto).
final _attachmentPath = RegExp(
  r'^attachments/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.[A-Za-z0-9]{1,5}$',
);

bool isValidAttachmentPath(String relativePath) =>
    _attachmentPath.hasMatch(relativePath);

/// File di un allegato dentro la directory dell'app, o null se
/// [relativePath] non è un path di allegato generato dall'app.
///
/// `relativePath` arriva dal DB, che può essere popolato anche da un import
/// o, in futuro, dalla sync: un valore come `../shared_prefs/...` farebbe
/// leggere file arbitrari della sandbox e, tramite il PDF della nota spese,
/// li farebbe uscire dal device (SECURITY_AUDIT NIP-18, NIP-25).
File? attachmentFile(Directory appDir, String relativePath) =>
    isValidAttachmentPath(relativePath)
    ? File('${appDir.path}/$relativePath')
    : null;
