import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill_record.dart';
import '../models/house_model.dart';
import '../services/db_service.dart';
import '../services/pdf_service.dart';
import '../widgets/house_result_tile.dart';

/// Displays the full calculated bill: per-house breakdown grouped by main
/// meter, and grand totals. Offers Save (SQLite), Export PDF, and Share.
class ResultScreen extends StatefulWidget {
  final BillCalculationResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _pdfService = PdfService();
  bool _saving = false;
  bool _saved = false;

  String get _monthLabel => DateFormat('MMMM yyyy').format(widget.result.calculatedAt);

  Future<void> _saveRecord() async {
    setState(() => _saving = true);
    try {
      final record = BillRecord(
        monthLabel: _monthLabel,
        savedAt: widget.result.calculatedAt,
        grandTotalUnits: widget.result.grandTotalUnits,
        grandTotalAmount: widget.result.grandTotalAmount,
        inputsJson: jsonEncode({
          'pumpUnits': widget.result.pumpUnits,
          'pumpSharedByCount': widget.result.pumpSharedByCount,
        }),
        resultJson: jsonEncode({
          'grandTotalUnits': widget.result.grandTotalUnits,
          'grandTotalAmount': widget.result.grandTotalAmount,
          'meters': widget.result.meters
              .map((m) => {
                    'meterId': m.meterId,
                    'totalUnits': m.totalUnits,
                    'totalBill': m.totalBill,
                    'houses': m.houses
                        .map((h) => {
                              'houseId': h.houseId,
                              'houseName': h.houseName,
                              'baseUnits': h.baseUnits,
                              'subMeterUnits': h.subMeterUnits,
                              'pumpShareUnits': h.pumpShareUnits,
                              'finalUnits': h.finalUnits,
                              'billAmount': h.billAmount,
                            })
                        .toList(),
                  })
              .toList(),
        }),
      );
      await DbService.instance.insertRecord(record);
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill saved to history')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportAndShare() async {
    final file = await _pdfService.generateBillPdf(result: widget.result, monthLabel: _monthLabel);
    if (!mounted) return;
    await _pdfService.sharePdf(file, text: 'TNEB Electricity Bill - $_monthLabel');
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Result - $_monthLabel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final meter in widget.result.meters) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.electric_meter, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text('Main Meter ${meter.meterId}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Text(currency.format(meter.totalBill),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.primary)),
                      ],
                    ),
                    Text('Total Units: ${meter.totalUnits.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const Divider(height: 18),
                    for (final house in meter.houses) HouseResultTile(result: house),
                  ],
                ),
              ),
            ),
          ],
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GRAND TOTAL UNITS', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.result.grandTotalUnits.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GRAND TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(currency.format(widget.result.grandTotalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _saveRecord,
                  icon: Icon(_saved ? Icons.check_circle : Icons.save),
                  label: Text(_saved ? 'Saved' : 'Save Record'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _exportAndShare,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export & Share PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
