import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  Future<Uint8List> generateBaptismCertificate({
    required String memberName,
    required String baptismDate,
    required String ministerName,
    required String certificateNumber,
  }) async {
    final pdf = pw.Document();

    // Load logo if available, otherwise use a placeholder or text
    // For now, we will use a stylish text header
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.gold, width: 5),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('ZION JERUSALEM CHURCH', 
                    style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 10),
                pw.Text('MBAGALA KWA MATOPE, DAR ES SALAAM', 
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                pw.SizedBox(height: 30),
                pw.Divider(color: PdfColors.gold, thickness: 2),
                pw.SizedBox(height: 20),
                pw.Text('CHETI CHA UBATIZO', 
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Hii inathibitisha kuwa:', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text(memberName.toUpperCase(), 
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.Text('Alibatizwa kwa maji mengi katika jina la Baba, na Mwana, na Roho Mtakatifu.', 
                    textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(baptismDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Divider(width: 150),
                        pw.Text('Tarehe ya Ubatizo'),
                      ]
                    ),
                    pw.Column(
                      children: [
                        pw.Text(ministerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Divider(width: 150),
                        pw.Text('Mchungaji Msimamizi'),
                      ]
                    ),
                  ]
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Namba ya Cheti: $certificateNumber', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                    pw.Text('Sayuni: Mahali pa Sifa na Uponyaji', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                  ]
                )
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateMembershipCertificate({
    required String memberName,
    required String joinDate,
    required String certificateNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 3),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              children: [
                pw.Text('ZION JERUSALEM CHURCH', 
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 40),
                pw.Text('CHETI CHA UANACHAMA', 
                    style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 50),
                pw.Text('Huu ni uthibitisho wa uanachama rasmi kwa:', textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 20),
                pw.Text(memberName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text('Amekubaliwa kuwa mwanachama wa Zion Jerusalem Church tangu tarehe $joinDate.', 
                    textAlign: pw.TextAlign.center),
                pw.Spacer(),
                pw.Divider(),
                pw.Text('Askofu Messi Mgala', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Kiongozi Mkuu wa Kiroho'),
                pw.SizedBox(height: 20),
                pw.Text('ID: $certificateNumber', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> saveAndOpenFile(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    // Use printing package to share or print
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
