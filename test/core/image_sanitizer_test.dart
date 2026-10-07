import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/image_sanitizer.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/db/tables.dart';
import 'package:nipay/data/export/expense_report_pdf.dart';

/// SECURITY_AUDIT NIP-16: posizione GPS e altri metadati delle foto non
/// devono finire negli allegati salvati né nel PDF della nota spese.
const _secret = 'GPS-45.4534N-9.1991E';

List<int> _segment(int marker, List<int> payload) {
  final length = payload.length + 2;
  return [0xFF, marker, length >> 8, length & 0xFF, ...payload];
}

/// EXIF big-endian con Orientation=[orientation] e, a seguire, una stringa
/// riconoscibile al posto dei tag GPS.
List<int> _exif(int orientation) => [
  ...'Exif'.codeUnits,
  0,
  0,
  0x4D,
  0x4D,
  0x00,
  0x2A,
  0x00,
  0x00,
  0x00,
  0x08,
  0x00,
  0x01,
  0x01,
  0x12,
  0x00,
  0x03,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  orientation,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  ..._secret.codeUnits,
];

Uint8List _jpeg({required List<List<int>> segments}) => Uint8List.fromList([
  0xFF, 0xD8,
  for (final s in segments) ...s,
  // SOS + dati compressi finti + EOI: devono restare identici.
  0xFF, 0xDA, 0x00, 0x04, 0x01, 0x00, 0x12, 0x34, 0x56, 0xFF, 0xD9,
]);

bool _contains(List<int> haystack, String needle) {
  final n = needle.codeUnits;
  outer:
  for (var i = 0; i + n.length <= haystack.length; i++) {
    for (var j = 0; j < n.length; j++) {
      if (haystack[i + j] != n[j]) continue outer;
    }
    return true;
  }
  return false;
}

List<int> _pngChunk(String type, List<int> data) => [
  data.length >> 24, (data.length >> 16) & 0xFF, (data.length >> 8) & 0xFF,
  data.length & 0xFF,
  ...type.codeUnits,
  ...data,
  0,
  0,
  0,
  0, // CRC (non verificato)
];

List<int> _riffChunk(String type, List<int> data) => [
  ...type.codeUnits,
  data.length & 0xFF,
  (data.length >> 8) & 0xFF,
  (data.length >> 16) & 0xFF,
  (data.length >> 24) & 0xFF,
  ...data,
  if (data.length.isOdd) 0,
];

void main() {
  group('JPEG', () {
    final original = _jpeg(
      segments: [
        _segment(0xE0, [...'JFIF'.codeUnits, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0]),
        _segment(0xE1, _exif(6)),
        _segment(0xE1, [
          ...'http://ns.adobe.com/xap/1.0/'.codeUnits,
          0,
          ..._secret.codeUnits,
        ]),
        _segment(0xE2, [...'ICC_PROFILE'.codeUnits, 0, 1, 1, 9, 9]),
        _segment(0xED, [...'Photoshop 3.0'.codeUnits, ..._secret.codeUnits]),
        _segment(0xFE, _secret.codeUnits),
        _segment(0xDB, List.filled(65, 1)),
      ],
    );

    test('removes EXIF/XMP/IPTC/comments, keeps image data, ICC and '
        'orientation', () {
      expect(_contains(original, _secret), isTrue);
      final clean = sanitizeImage(original);

      expect(clean.mimeType, 'image/jpeg');
      expect(clean.extension, 'jpg');
      expect(_contains(clean.bytes, _secret), isFalse);
      expect(_contains(clean.bytes, 'http://ns.adobe.com'), isFalse);
      expect(_contains(clean.bytes, 'ICC_PROFILE'), isTrue);
      expect(_contains(clean.bytes, 'JFIF'), isTrue);
      // Orientamento conservato (EXIF minimo con il solo tag 0x0112 = 6).
      expect(_contains(clean.bytes, 'Exif'), isTrue);
      final exifAt = clean.bytes.indexOf(0xE1) - 1;
      expect(clean.bytes.sublist(exifAt, exifAt + 36).length, 36);
      expect(clean.bytes[exifAt + 29], 6);
      // Scan finale identico.
      expect(
        clean.bytes.sublist(clean.bytes.length - 11),
        original.sublist(original.length - 11),
      );
    });

    test('is idempotent', () {
      final once = sanitizeImage(original).bytes;
      expect(sanitizeImage(once).bytes, once);
    });

    test('without orientation no EXIF block is written', () {
      final clean = sanitizeImage(
        _jpeg(
          segments: [
            _segment(0xE1, _exif(1)),
            _segment(0xDB, [0]),
          ],
        ),
      );
      expect(_contains(clean.bytes, 'Exif'), isFalse);
    });

    test('a truncated file is rejected', () {
      expect(
        () => sanitizeImage(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x10])),
        throwsA(isA<UnsupportedImageException>()),
      );
    });

    test('the expense report PDF never contains the GPS data of an old, '
        'unsanitized receipt', () async {
      // Foto vera (icona dell'app) con un EXIF "GPS" aggiunto a mano.
      final icon = File('assets/icon/icon.jpeg').readAsBytesSync();
      final withGps = Uint8List.fromList([
        0xFF,
        0xD8,
        ..._segment(0xE1, _exif(1)),
        ...icon.sublist(2),
      ]);
      expect(_contains(withGps, _secret), isTrue);

      final now = DateTime(2026, 10, 5);
      final pdf = await buildExpenseReportPdf(
        walletName: 'Conto',
        from: now,
        to: now.add(const Duration(days: 1)),
        rows: [
          (
            transaction: Transaction(
              id: 'tx1',
              createdAt: now,
              updatedAt: now,
              type: TransactionType.expense,
              amountCents: 1000,
              date: now,
              walletId: 'w1',
              description: 'Pranzo',
            ),
            entry: ExpenseReportEntry(
              transactionId: 'tx1',
              reimbursable: true,
              eInvoice: false,
              updatedAt: now,
            ),
          ),
        ],
        categoriesById: const {},
        costCentersById: const {},
        attachmentsByTx: {
          'tx1': [withGps],
        },
      );
      expect(_contains(pdf, _secret), isFalse);
    });
  });

  test('PNG: text and EXIF chunks are removed, pixels kept', () {
    final png = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      ..._pngChunk('IHDR', List.filled(13, 1)),
      ..._pngChunk('tEXt', [...'Comment'.codeUnits, 0, ..._secret.codeUnits]),
      ..._pngChunk('eXIf', _exif(1).sublist(6)),
      ..._pngChunk('IDAT', [1, 2, 3]),
      ..._pngChunk('IEND', const []),
    ]);
    final clean = sanitizeImage(png);
    expect(clean.mimeType, 'image/png');
    expect(_contains(clean.bytes, _secret), isFalse);
    expect(_contains(clean.bytes, 'IHDR'), isTrue);
    expect(_contains(clean.bytes, 'IDAT'), isTrue);
    expect(_contains(clean.bytes, 'IEND'), isTrue);
  });

  test('WebP: EXIF/XMP chunks removed, VP8X flags and RIFF size fixed', () {
    final body = [
      ...'WEBP'.codeUnits,
      ..._riffChunk('VP8X', [0x0C, 0, 0, 0, 1, 0, 0, 1, 0, 0]),
      ..._riffChunk('VP8 ', [1, 2, 3, 4]),
      ..._riffChunk('EXIF', _secret.codeUnits),
      ..._riffChunk('XMP ', _secret.codeUnits),
    ];
    final webp = Uint8List.fromList([
      ...'RIFF'.codeUnits,
      body.length & 0xFF,
      (body.length >> 8) & 0xFF,
      0,
      0,
      ...body,
    ]);
    final clean = sanitizeImage(webp);
    expect(clean.mimeType, 'image/webp');
    expect(_contains(clean.bytes, _secret), isFalse);
    final size = clean.bytes[4] | (clean.bytes[5] << 8);
    expect(size, clean.bytes.length - 8);
    expect(clean.bytes[20] & 0x0C, 0, reason: 'flag EXIF/XMP azzerati');
  });

  test('other formats (HTML, HEIC, executables) are rejected by content, '
      'whatever the file name', () {
    for (final data in [
      '<html><script>alert(1)</script></html>'.codeUnits,
      [0, 0, 0, 0x18, ...'ftypheic'.codeUnits],
      [0x4D, 0x5A, 0x90, 0x00],
      <int>[],
    ]) {
      expect(
        () => sanitizeImage(Uint8List.fromList(data)),
        throwsA(isA<UnsupportedImageException>()),
      );
    }
  });
}
