import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/core/services/pdf_document_service.dart';

void main() {
  test('creates a structurally valid text PDF', () {
    final bytes = PdfDocumentService.createTextPdf(
      '% PinkSlipReport\nStudent: Example Student\nStatus: APPROVED',
    );
    final pdf = utf8.decode(bytes);

    expect(pdf, startsWith('%PDF-1.4\n'));
    expect(pdf, contains('/Type /Catalog'));
    expect(pdf, contains('Student: Example Student'));
    expect(pdf, contains('xref'));
    expect(pdf, contains('startxref'));
    expect(pdf, endsWith('%%EOF\n'));
  });
}
