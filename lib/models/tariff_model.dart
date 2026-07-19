/// Represents a single slab of the Tamil Nadu Domestic Electricity Tariff.
///
/// [uptoUnits] is the upper bound (inclusive) of this slab, counted from the
/// very first unit (i.e. cumulative, not "units within this slab").
/// A value of `null` means "and above" (the last, open-ended slab).
class TariffSlab {
  final int? uptoUnits;
  final double ratePerUnit;

  const TariffSlab({required this.uptoUnits, required this.ratePerUnit});

  TariffSlab copyWith({int? uptoUnits, double? ratePerUnit}) {
    return TariffSlab(
      uptoUnits: uptoUnits ?? this.uptoUnits,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
    );
  }

  Map<String, dynamic> toJson() => {
        'uptoUnits': uptoUnits,
        'ratePerUnit': ratePerUnit,
      };

  factory TariffSlab.fromJson(Map<String, dynamic> json) => TariffSlab(
        uptoUnits: json['uptoUnits'] as int?,
        ratePerUnit: (json['ratePerUnit'] as num).toDouble(),
      );

  /// Human readable label like "201-400 Units" or "Above 1000".
  String label(int previousLimit) {
    if (uptoUnits == null) return 'Above $previousLimit';
    return '${previousLimit + 1}-$uptoUnits Units';
  }
}

/// Holds both TNEB domestic tariff tables (as per the spec):
///  - `lowTable`  : used when the total main meter units are <= 500
///  - `highTable` : used when the total main meter units are  > 500
class TariffConfig {
  final List<TariffSlab> lowTable; // total <= 500
  final List<TariffSlab> highTable; // total > 500

  const TariffConfig({required this.lowTable, required this.highTable});

  /// Official default Tamil Nadu domestic tariff, exactly as specified.
  factory TariffConfig.defaults() {
    return const TariffConfig(
      lowTable: [
        TariffSlab(uptoUnits: 200, ratePerUnit: 0.0), // 1-200 Free
        TariffSlab(uptoUnits: 400, ratePerUnit: 4.70), // 201-400
        TariffSlab(uptoUnits: 500, ratePerUnit: 6.30), // 401-500
      ],
      highTable: [
        TariffSlab(uptoUnits: 100, ratePerUnit: 0.0), // 1-100 Free
        TariffSlab(uptoUnits: 400, ratePerUnit: 4.70), // 101-400
        TariffSlab(uptoUnits: 500, ratePerUnit: 6.30), // 401-500
        TariffSlab(uptoUnits: 600, ratePerUnit: 8.40), // 501-600
        TariffSlab(uptoUnits: 800, ratePerUnit: 9.45), // 601-800
        TariffSlab(uptoUnits: 1000, ratePerUnit: 10.50), // 801-1000
        TariffSlab(uptoUnits: null, ratePerUnit: 11.55), // Above 1000
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'lowTable': lowTable.map((e) => e.toJson()).toList(),
        'highTable': highTable.map((e) => e.toJson()).toList(),
      };

  factory TariffConfig.fromJson(Map<String, dynamic> json) => TariffConfig(
        lowTable: (json['lowTable'] as List)
            .map((e) => TariffSlab.fromJson(e as Map<String, dynamic>))
            .toList(),
        highTable: (json['highTable'] as List)
            .map((e) => TariffSlab.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  TariffConfig copyWith({List<TariffSlab>? lowTable, List<TariffSlab>? highTable}) {
    return TariffConfig(
      lowTable: lowTable ?? this.lowTable,
      highTable: highTable ?? this.highTable,
    );
  }
}
