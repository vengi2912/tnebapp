import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/house_model.dart';

/// Builds a printable/shareable PDF bill summary and offers a share sheet
/// (WhatsApp, email, etc. - whatever the device has installed).
class PdfService {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  Future<File> generateBillPdf({
    required BillCalculationResult result,
    required String monthLabel,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'TNEB Bill Splitter',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(monthLabel, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            'Generated: ${_dateFmt.format(result.calculatedAt)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          for (final meter in result.meters) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: PdfColors.blue50,
              child: pw.Text(
                'Main Meter ${meter.meterId}   |   Total Units: ${meter.totalUnits.toStringAsFixed(2)}   |   '
                'Bill: ${_currency.format(meter.totalBill)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(1.4),
                4: pw.FlexColumnWidth(1.6),
              },
              children: [
                _headerRow(['House', 'Units', 'Pump Share', 'Final Units', 'Bill Amount']),
                for (final h in meter.houses)
                  _dataRow([
                    h.houseName,
                    h.houseUnitsEntered.toStringAsFixed(2),
                    h.pumpShareUnits.toStringAsFixed(2),
                    h.finalUnits.toStringAsFixed(2),
                    _currency.format(h.billAmount),
                  ]),
              ],
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Common Water Pump Units: ${result.pumpUnits.toStringAsFixed(2)} '
                  '(shared by ${result.pumpSharedByCount} houses)'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors.green50,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('GRAND TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Text(
                  '${result.grandTotalUnits.toStringAsFixed(2)} units   |   '
                  '${_currency.format(result.grandTotalAmount)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'TNEB_Bill_${monthLabel.replaceAll(' ', '_')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.TableRow _headerRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(c, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ))
          .toList(),
    );
  }

  pw.TableRow _dataRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
              ))
          .toList(),
    );
  }

  /// Opens the system share sheet (WhatsApp will appear there if installed).
  Future<void> sharePdf(File file, {String? text}) async {
    await Share.shareXFiles([XFile(file.path)], text: text ?? 'TNEB Electricity Bill');
  }
}
