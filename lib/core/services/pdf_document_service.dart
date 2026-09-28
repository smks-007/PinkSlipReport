import 'dart:convert';
import 'dart:typed_data';

/// Creates a small, standards-compliant PDF for text-only official records.
/// This keeps report uploads valid without requiring a platform PDF plugin.
class PdfDocumentService {
  PdfDocumentService._();

  static Uint8List createTextPdf(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ').trim())
        .where((line) => line.isNotEmpty && !line.startsWith('%'))
        .take(42)
        .toList();

    final content = StringBuffer()
      ..writeln('BT')
      ..writeln('/F1 9 Tf')
      ..writeln('50 790 Td');
    for (final line in lines) {
      final escaped = line.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      content
        ..writeln('($escaped) Tj')
        ..writeln('0 -16 Td');
    }
    content.writeln('ET');

    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${utf8.encode(content.toString()).length} >>\nstream\n${content}endstream',
    ];

    final pdf = StringBuffer()..writeln('%PDF-1.4');
    final offsets = <int>[0];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(utf8.encode(pdf.toString()).length);
      pdf
        ..writeln('${i + 1} 0 obj')
        ..writeln(objects[i])
        ..writeln('endobj');
    }
    final xrefOffset = utf8.encode(pdf.toString()).length;
    pdf
      ..writeln('xref')
      ..writeln('0 ${objects.length + 1}')
      ..writeln('0000000000 65535 f ');
    for (final offset in offsets.skip(1)) {
      pdf.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    pdf
      ..writeln('trailer')
      ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
      ..writeln('startxref')
      ..writeln(xrefOffset)
      ..writeln('%%EOF');
    return Uint8List.fromList(utf8.encode(pdf.toString()));
  }
}
