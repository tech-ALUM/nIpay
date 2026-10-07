import 'dart:typed_data';

/// Immagine ripulita dai metadati, con tipo ricavato dal contenuto.
typedef SanitizedImage = ({Uint8List bytes, String extension, String mimeType});

/// Formato non riconosciuto (o file corrotto): l'allegato va rifiutato.
class UnsupportedImageException implements Exception {
  const UnsupportedImageException();

  @override
  String toString() => 'UnsupportedImageException';
}

/// Rimuove da una foto i metadati che possono contenere dati personali
/// (EXIF con coordinate GPS, modello del telefono, data; XMP; IPTC;
/// commenti) prima di salvarla o metterla in un PDF da condividere
/// (SECURITY_AUDIT NIP-16).
///
/// Nessuna ricodifica (niente perdita di qualità, nessun costo): si tolgono
/// solo i blocchi di metadati. L'orientamento EXIF, se presente, viene
/// conservato in un blocco EXIF minimo che contiene SOLO quel tag,
/// altrimenti le foto scattate in verticale apparirebbero ruotate.
///
/// Il tipo si ricava dai magic bytes, non dal nome del file
/// (SECURITY_AUDIT NIP-24): JPEG, PNG e WebP; tutto il resto lancia
/// [UnsupportedImageException].
SanitizedImage sanitizeImage(Uint8List data) {
  if (_startsWith(data, const [0xFF, 0xD8, 0xFF])) {
    return (
      bytes: _sanitizeJpeg(data),
      extension: 'jpg',
      mimeType: 'image/jpeg',
    );
  }
  if (_startsWith(data, const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ])) {
    return (bytes: _sanitizePng(data), extension: 'png', mimeType: 'image/png');
  }
  if (data.length >= 12 &&
      _ascii(data, 0, 4) == 'RIFF' &&
      _ascii(data, 8, 4) == 'WEBP') {
    return (
      bytes: _sanitizeWebp(data),
      extension: 'webp',
      mimeType: 'image/webp',
    );
  }
  throw const UnsupportedImageException();
}

bool _startsWith(Uint8List data, List<int> prefix) {
  if (data.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (data[i] != prefix[i]) return false;
  }
  return true;
}

String _ascii(Uint8List data, int offset, int length) =>
    String.fromCharCodes(data.sublist(offset, offset + length));

void _require(bool condition) {
  if (!condition) throw const UnsupportedImageException();
}

// ---------------------------------------------------------------------
// JPEG
// ---------------------------------------------------------------------

Uint8List _sanitizeJpeg(Uint8List data) {
  // Prima passata: segmenti fino allo Start Of Scan.
  final segments = <(int marker, Uint8List segment, Uint8List payload)>[];
  var pos = 2;
  Uint8List? tail; // da SOS (o EOI) in poi, copiato intatto
  while (tail == null) {
    _require(pos + 1 < data.length && data[pos] == 0xFF);
    var marker = data[pos + 1];
    // Byte di riempimento 0xFF ammessi prima del marker.
    while (marker == 0xFF) {
      pos++;
      _require(pos + 1 < data.length);
      marker = data[pos + 1];
    }
    if (marker == 0xDA || marker == 0xD9) {
      tail = Uint8List.sublistView(data, pos);
      break;
    }
    _require(pos + 3 < data.length);
    final length = (data[pos + 2] << 8) | data[pos + 3];
    _require(length >= 2 && pos + 2 + length <= data.length);
    segments.add((
      marker,
      Uint8List.sublistView(data, pos, pos + 2 + length),
      Uint8List.sublistView(data, pos + 4, pos + 2 + length),
    ));
    pos += 2 + length;
  }

  var orientation = 1;
  for (final (marker, _, payload) in segments) {
    if (marker == 0xE1) orientation = _exifOrientation(payload) ?? orientation;
  }

  bool keep(int marker, Uint8List payload) {
    if (marker == 0xE0) return true; // APP0 JFIF: nessun dato personale
    // Profilo colore e trasformazione Adobe servono a mostrare/decodificare
    // correttamente la foto, non contengono dati personali.
    if (marker == 0xE2) return _payloadStartsWith(payload, 'ICC_PROFILE');
    if (marker == 0xEE) return _payloadStartsWith(payload, 'Adobe');
    // Altri APPn (EXIF/XMP in APP1, IPTC, maker notes) e commenti: via.
    if ((marker >= 0xE1 && marker <= 0xEF) || marker == 0xFE) return false;
    return true; // tabelle, frame header, ecc.
  }

  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  for (final (marker, segment, _) in segments) {
    if (marker == 0xE0) out.add(segment);
  }
  if (orientation != 1) out.add(_exifOrientationSegment(orientation));
  for (final (marker, segment, payload) in segments) {
    if (marker != 0xE0 && keep(marker, payload)) out.add(segment);
  }
  out.add(tail);
  return out.takeBytes();
}

bool _payloadStartsWith(Uint8List payload, String prefix) =>
    payload.length >= prefix.length &&
    String.fromCharCodes(payload.sublist(0, prefix.length)) == prefix;

/// Orientamento (tag 0x0112 dell'IFD0) da un payload APP1 "Exif\0\0".
int? _exifOrientation(Uint8List payload) {
  if (payload.length < 14 || !_payloadStartsWith(payload, 'Exif\u0000\u0000')) {
    return null;
  }
  final tiff = Uint8List.sublistView(payload, 6);
  final bigEndian = tiff[0] == 0x4D && tiff[1] == 0x4D;
  if (!bigEndian && !(tiff[0] == 0x49 && tiff[1] == 0x49)) return null;
  int u16(int o) =>
      bigEndian ? (tiff[o] << 8) | tiff[o + 1] : tiff[o] | (tiff[o + 1] << 8);
  int u32(int o) => bigEndian
      ? (tiff[o] << 24) | (tiff[o + 1] << 16) | (tiff[o + 2] << 8) | tiff[o + 3]
      : tiff[o] |
            (tiff[o + 1] << 8) |
            (tiff[o + 2] << 16) |
            (tiff[o + 3] << 24);
  if (u16(2) != 42) return null;
  final ifd = u32(4);
  if (ifd + 2 > tiff.length) return null;
  final count = u16(ifd);
  for (var i = 0; i < count; i++) {
    final entry = ifd + 2 + i * 12;
    if (entry + 12 > tiff.length) return null;
    if (u16(entry) == 0x0112) {
      final value = u16(entry + 8);
      return value >= 1 && value <= 8 ? value : null;
    }
  }
  return null;
}

/// Segmento APP1 con un EXIF che contiene solo l'orientamento.
Uint8List _exifOrientationSegment(int orientation) => Uint8List.fromList([
  0xFF, 0xE1, 0x00, 0x22, // APP1, lunghezza 34
  0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
  0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // TIFF big-endian, IFD0 a 8
  0x00, 0x01, // una voce
  0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, // Orientation, SHORT, 1
  0x00, orientation, 0x00, 0x00, // valore
  0x00, 0x00, 0x00, 0x00, // nessun IFD successivo
]);

// ---------------------------------------------------------------------
// PNG
// ---------------------------------------------------------------------

/// Chunk PNG con metadati testuali/EXIF o data: via. Gli altri (pixel,
/// palette, trasparenza, colore, densità) restano, CRC compreso.
const _pngMetadataChunks = {'eXIf', 'tEXt', 'zTXt', 'iTXt', 'tIME'};

Uint8List _sanitizePng(Uint8List data) {
  final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(data, 0, 8));
  var pos = 8;
  while (pos < data.length) {
    _require(pos + 12 <= data.length);
    final length =
        (data[pos] << 24) |
        (data[pos + 1] << 16) |
        (data[pos + 2] << 8) |
        data[pos + 3];
    final end = pos + 12 + length;
    _require(length >= 0 && end <= data.length);
    final type = _ascii(data, pos + 4, 4);
    if (!_pngMetadataChunks.contains(type)) {
      out.add(Uint8List.sublistView(data, pos, end));
    }
    pos = end;
    if (type == 'IEND') break;
  }
  return out.takeBytes();
}

// ---------------------------------------------------------------------
// WebP (contenitore RIFF)
// ---------------------------------------------------------------------

Uint8List _sanitizeWebp(Uint8List data) {
  final chunks = BytesBuilder(copy: false);
  var pos = 12;
  while (pos < data.length) {
    _require(pos + 8 <= data.length);
    final type = _ascii(data, pos, 4);
    final size =
        data[pos + 4] |
        (data[pos + 5] << 8) |
        (data[pos + 6] << 16) |
        (data[pos + 7] << 24);
    final end = pos + 8 + size + (size.isOdd ? 1 : 0);
    _require(size >= 0 && pos + 8 + size <= data.length);
    final chunk = Uint8List.fromList(
      data.sublist(pos, end > data.length ? data.length : end),
    );
    if (type == 'VP8X' && chunk.length > 8) {
      chunk[8] &= ~0x0C; // flag EXIF (0x08) e XMP (0x04) azzerati
    }
    if (type != 'EXIF' && type != 'XMP ') chunks.add(chunk);
    pos = end;
  }
  final body = chunks.takeBytes();
  final riffSize = body.length + 4;
  return (BytesBuilder(copy: false)
        ..add('RIFF'.codeUnits)
        ..add([
          riffSize & 0xFF,
          (riffSize >> 8) & 0xFF,
          (riffSize >> 16) & 0xFF,
          (riffSize >> 24) & 0xFF,
        ])
        ..add('WEBP'.codeUnits)
        ..add(body))
      .takeBytes();
}
