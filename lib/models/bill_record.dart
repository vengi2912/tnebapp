import 'dart:convert';

/// A single saved monthly bill snapshot, stored in SQLite.
///
/// The full calculation result and the raw inputs are stored as JSON blobs
/// so history can be re-displayed or re-exported to PDF without needing to
/// re-run the calculation logic.
class BillRecord {
  final int? id;
  final String monthLabel; // e.g. "July 2026"
  final DateTime savedAt;
  final double grandTotalUnits;
  final double grandTotalAmount;
  final String inputsJson; // raw form inputs
  final String resultJson; // full computed breakdown

  BillRecord({
    this.id,
    required this.monthLabel,
    required this.savedAt,
    required this.grandTotalUnits,
    required this.grandTotalAmount,
    required this.inputsJson,
    required this.resultJson,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'monthLabel': monthLabel,
        'savedAt': savedAt.toIso8601String(),
        'grandTotalUnits': grandTotalUnits,
        'grandTotalAmount': grandTotalAmount,
        'inputsJson': inputsJson,
        'resultJson': resultJson,
      };

  factory BillRecord.fromMap(Map<String, dynamic> map) => BillRecord(
        id: map['id'] as int?,
        monthLabel: map['monthLabel'] as String,
        savedAt: DateTime.parse(map['savedAt'] as String),
        grandTotalUnits: (map['grandTotalUnits'] as num).toDouble(),
        grandTotalAmount: (map['grandTotalAmount'] as num).toDouble(),
        inputsJson: map['inputsJson'] as String,
        resultJson: map['resultJson'] as String,
      );

  Map<String, dynamic> get decodedResult => jsonDecode(resultJson) as Map<String, dynamic>;
  Map<String, dynamic> get decodedInputs => jsonDecode(inputsJson) as Map<String, dynamic>;
}
