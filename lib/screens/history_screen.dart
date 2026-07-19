import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill_record.dart';
import '../models/house_model.dart';
import '../services/db_service.dart';
import 'result_screen.dart';

/// Lists every previously saved monthly bill (from SQLite), newest first.
/// Tapping a record reopens it in the same result view used right after
/// calculation, and each record can be deleted with a swipe.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<BillRecord>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DbService.instance.fetchAllRecords();
  }

  Future<void> _delete(BillRecord record) async {
    if (record.id == null) return;
    await DbService.instance.deleteRecord(record.id!);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Previous Bills')),
      body: FutureBuilder<List<BillRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No saved bills yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Dismissible(
                key: ValueKey(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _delete(record),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                    title: Text(record.monthLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Units: ${record.grandTotalUnits.toStringAsFixed(1)}  |  '
                      'Saved: ${DateFormat('dd MMM yyyy').format(record.savedAt)}',
                    ),
                    trailing: Text(
                      currency.format(record.grandTotalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      final result = BillCalculationResult.fromSavedJson(
                        resultJson: record.decodedResult,
                        inputsJson: record.decodedInputs,
                        savedAt: record.savedAt,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
