import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/supabase_service.dart';

/// HOD-only PDF preview for the configured academic-term report.
class SemesterTotalReportScreen extends StatefulWidget {
  const SemesterTotalReportScreen({super.key});

  @override
  State<SemesterTotalReportScreen> createState() =>
      _SemesterTotalReportScreenState();
}

class _SemesterTotalReportScreenState extends State<SemesterTotalReportScreen> {
  int _year = 2;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _term;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final service = SupabaseService();
    final result = await Future.wait([
      service.fetchAcademicTermSettings(_year),
      service.fetchHodSemesterTotalReport(_year),
    ]);
    if (!mounted) return;
    final term = result[0] as Map<String, dynamic>?;
    final rows = result[1] as List<Map<String, dynamic>>;
    setState(() {
      _term = term;
      _rows = rows;
      _loading = false;
      _error = term == null
          ? 'Configure the academic term for Year $_year before generating this report.'
          : (rows.isEmpty && service.lastPersistenceError != null
                ? service.lastPersistenceError
                : null);
    });
  }

  String _date(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<pw.Document> _buildPdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final present = _rows.fold<int>(0, (sum, row) => sum + ((row['present_days'] as num?)?.toInt() ?? 0));
    final attendance = _rows.fold<int>(0, (sum, row) => sum + ((row['attendance_days'] as num?)?.toInt() ?? 0));
    final percentage = attendance == 0 ? 0.0 : present * 100 / attendance;
    doc.addPage(
      pw.MultiPage(
        pageFormat: format.landscape,
        margin: const pw.EdgeInsets.all(26),
        build: (_) => [
          pw.Text('V.S.B. ENGINEERING COLLEGE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Department of Artificial Intelligence & Data Science', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 14),
          pw.Text('Semester Total Attendance Report - Year $_year', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.Text('${_term?['term_name'] ?? 'Academic Term'} | ${_date(_term?['start_date']?.toString())} to ${_date(_term?['end_date']?.toString())}'),
          pw.SizedBox(height: 10),
          pw.Text('Students: ${_rows.length}   Attendance: ${percentage.toStringAsFixed(1)}%   Generated: ${_date(DateTime.now().toIso8601String())}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const ['#', 'Roll No.', 'Student', 'Section', 'Days', 'Present', 'Absent', 'OD', 'Approved Leave', 'Attendance %'],
            data: List<List<String>>.generate(_rows.length, (index) {
              final row = _rows[index];
              String value(String key) => row[key]?.toString() ?? '0';
              final days = (row['attendance_days'] as num?)?.toInt() ?? 0;
              final presentDays = (row['present_days'] as num?)?.toInt() ?? 0;
              final percent = days == 0 ? 0.0 : presentDays * 100 / days;
              return [
                '${index + 1}', value('roll_number'), value('student_name'), value('section_id'),
                value('attendance_days'), value('present_days'), value('absent_days'),
                value('od_days'), value('approved_leave_days'), '${percent.toStringAsFixed(1)}%',
              ];
            }),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {0: const pw.FixedColumnWidth(20), 2: const pw.FlexColumnWidth(2.3)},
          ),
        ],
        footer: (_) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Official departmental record', style: const pw.TextStyle(fontSize: 8)),
        ),
      ),
    );
    return doc;
  }

  Future<void> _downloadReport() async {
    try {
      final bytes = await (await _buildPdf(PdfPageFormat.a4)).save();
      final start = _date(_term?['start_date']?.toString()).replaceAll('-', '');
      final end = _date(_term?['end_date']?.toString()).replaceAll('-', '');
      final savedPath = await FileSaver.instance.saveFile(
        name: 'leave_desk_semester_report_year_${_year}_${start}_$end',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded: $savedPath')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not prepare the PDF download: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Semester Total Report'),
      actions: [
        IconButton(
          tooltip: 'Download PDF',
          onPressed: _loading || _error != null ? null : _downloadReport,
          icon: const Icon(Icons.download_rounded),
        ),
      ],
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Text('Report year: '),
          DropdownButton<int>(
            value: _year,
            items: List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Year ${i + 1}'))),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _year = value);
              _load();
            },
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_term == null ? 'No term configured' : '${_term!['term_name']} - ${_date(_term!['start_date']?.toString())} to ${_date(_term!['end_date']?.toString())}')),
        ]),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
          : PdfPreview(
              build: (format) async => (await _buildPdf(format)).save(),
              onError: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'PDF preview could not be generated:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              canChangePageFormat: false,
              canChangeOrientation: true,
              allowPrinting: true,
              allowSharing: true,
            )),
    ]),
  );
}
