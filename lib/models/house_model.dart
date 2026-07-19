/// Configuration + live input data for a single house.
///
/// `mainMeterId` (1..3) says which of the 3 main TNEB meters feeds this
/// house. `subMeterId` (1..4, or null) says which sub meter (if any) is
/// attached to this house in addition to its direct share. `sharesPump`
/// controls whether this house participates in splitting the common
/// water pump units.
class HouseConfig {
  final int id; // 1..6
  String name;
  int mainMeterId; // 1, 2 or 3
  int? subMeterId; // 1..4 or null
  bool sharesPump;

  HouseConfig({
    required this.id,
    required this.name,
    required this.mainMeterId,
    this.subMeterId,
    this.sharesPump = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mainMeterId': mainMeterId,
        'subMeterId': subMeterId,
        'sharesPump': sharesPump,
      };

  factory HouseConfig.fromJson(Map<String, dynamic> json) => HouseConfig(
        id: json['id'] as int,
        name: json['name'] as String,
        mainMeterId: json['mainMeterId'] as int,
        subMeterId: json['subMeterId'] as int?,
        sharesPump: json['sharesPump'] as bool? ?? true,
      );

  /// Default layout: 2 houses per main meter, first 4 houses carry a
  /// dedicated sub meter, all houses share the common water pump.
  static List<HouseConfig> defaultLayout() {
    return [
      HouseConfig(id: 1, name: 'House 1', mainMeterId: 1, subMeterId: 1),
      HouseConfig(id: 2, name: 'House 2', mainMeterId: 1, subMeterId: 2),
      HouseConfig(id: 3, name: 'House 3', mainMeterId: 2, subMeterId: 3),
      HouseConfig(id: 4, name: 'House 4', mainMeterId: 2, subMeterId: 4),
      HouseConfig(id: 5, name: 'House 5', mainMeterId: 3, subMeterId: null),
      HouseConfig(id: 6, name: 'House 6', mainMeterId: 3, subMeterId: null),
    ];
  }
}

/// Computed result for one house after a bill calculation run.
class HouseResult {
  final int houseId;
  final String houseName;
  final int mainMeterId;
  final double baseUnits; // direct house reading
  final double subMeterUnits; // attached sub meter reading (0 if none)
  final double pumpShareUnits; // this house's share of the pump
  final double finalUnits; // base + sub + pump share
  final double billAmount; // ₹ owed by this house

  HouseResult({
    required this.houseId,
    required this.houseName,
    required this.mainMeterId,
    required this.baseUnits,
    required this.subMeterUnits,
    required this.pumpShareUnits,
    required this.finalUnits,
    required this.billAmount,
  });

  double get houseUnitsEntered => baseUnits + subMeterUnits;

  factory HouseResult.fromJson(Map<String, dynamic> json, int mainMeterId) {
    return HouseResult(
      houseId: json['houseId'] as int,
      houseName: json['houseName'] as String,
      mainMeterId: mainMeterId,
      baseUnits: (json['baseUnits'] as num).toDouble(),
      subMeterUnits: (json['subMeterUnits'] as num).toDouble(),
      pumpShareUnits: (json['pumpShareUnits'] as num).toDouble(),
      finalUnits: (json['finalUnits'] as num).toDouble(),
      billAmount: (json['billAmount'] as num).toDouble(),
    );
  }
}

/// Computed result for one main meter after a bill calculation run.
class MeterResult {
  final int meterId;
  final double totalUnits; // physical units used for slab tariff lookup
  final double totalBill; // ₹ total for this meter (sum of slabs)
  final List<HouseResult> houses;

  MeterResult({
    required this.meterId,
    required this.totalUnits,
    required this.totalBill,
    required this.houses,
  });

  factory MeterResult.fromJson(Map<String, dynamic> json) {
    final meterId = json['meterId'] as int;
    return MeterResult(
      meterId: meterId,
      totalUnits: (json['totalUnits'] as num).toDouble(),
      totalBill: (json['totalBill'] as num).toDouble(),
      houses: (json['houses'] as List)
          .map((h) => HouseResult.fromJson(h as Map<String, dynamic>, meterId))
          .toList(),
    );
  }
}

/// Full result of a single bill calculation (all 3 meters + grand totals).
class BillCalculationResult {
  final List<MeterResult> meters;
  final double pumpUnits;
  final int pumpSharedByCount;
  final double grandTotalUnits;
  final double grandTotalAmount;
  final DateTime calculatedAt;

  BillCalculationResult({
    required this.meters,
    required this.pumpUnits,
    required this.pumpSharedByCount,
    required this.grandTotalUnits,
    required this.grandTotalAmount,
    required this.calculatedAt,
  });

  List<HouseResult> get allHouses =>
      meters.expand((m) => m.houses).toList()..sort((a, b) => a.houseId.compareTo(b.houseId));

  /// Reconstructs a result from the JSON blob saved in [BillRecord.resultJson]
  /// combined with the pump info saved in [BillRecord.inputsJson].
  factory BillCalculationResult.fromSavedJson({
    required Map<String, dynamic> resultJson,
    required Map<String, dynamic> inputsJson,
    required DateTime savedAt,
  }) {
    return BillCalculationResult(
      meters: (resultJson['meters'] as List)
          .map((m) => MeterResult.fromJson(m as Map<String, dynamic>))
          .toList(),
      pumpUnits: (inputsJson['pumpUnits'] as num?)?.toDouble() ?? 0.0,
      pumpSharedByCount: (inputsJson['pumpSharedByCount'] as num?)?.toInt() ?? 6,
      grandTotalUnits: (resultJson['grandTotalUnits'] as num).toDouble(),
      grandTotalAmount: (resultJson['grandTotalAmount'] as num).toDouble(),
      calculatedAt: savedAt,
    );
  }
}
