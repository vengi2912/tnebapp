import '../models/house_model.dart';
import '../models/tariff_model.dart';
import 'tariff_service.dart';

/// Orchestrates the full TNEB bill-splitting calculation.
///
/// Calculation design
/// -------------------
/// 1. Each Main Meter's *physical* total units = sum of the base reading of
///    every house wired to it, plus any sub meter reading attached to those
///    houses. This is the figure TNEB actually bills on, so it is what gets
///    run through the slab tariff to produce that meter's fixed total bill.
/// 2. The common water pump's units are divided equally among every house
///    that shares it -> "pump share".
/// 3. Each house's "Final Units" = base units + its sub meter (if any) +
///    its pump share. Final Units are used only as a *weight* to fairly
///    split each meter's fixed total bill between the houses on that meter:
///
///       House Bill = (House Final Units / Sum of Final Units on that meter)
///                     * Meter Total Bill
///
///    Because the weights are ratios that sum to 1 within a meter group,
///    the sum of all house bills on a meter always exactly equals that
///    meter's total bill - no rounding leakage across the building.
class CalculationService {
  final TariffConfig tariffConfig;

  const CalculationService(this.tariffConfig);

  BillCalculationResult calculate({
    required List<HouseConfig> houseConfigs,
    required Map<int, double> houseUnits, // houseId -> entered units
    required Map<int, double> subMeterUnits, // subMeterId(1-4) -> units
    required double pumpUnits,
  }) {
    final tariffService = TariffService(tariffConfig);

    final sharingHouses = houseConfigs.where((h) => h.sharesPump).toList();
    final int sharedByCount = sharingHouses.isEmpty ? 1 : sharingHouses.length;
    final double pumpSharePerHouse = pumpUnits / sharedByCount;

    final List<MeterResult> meterResults = [];
    double grandUnits = 0;
    double grandAmount = 0;

    for (final meterId in [1, 2, 3]) {
      final housesOnMeter = houseConfigs.where((h) => h.mainMeterId == meterId).toList();

      // Step 1: physical meter total (drives the tariff slab lookup).
      double meterTotalUnits = 0;
      final Map<int, double> baseUnitsByHouse = {};
      final Map<int, double> subUnitsByHouse = {};

      for (final house in housesOnMeter) {
        final base = houseUnits[house.id] ?? 0.0;
        final sub = house.subMeterId != null ? (subMeterUnits[house.subMeterId] ?? 0.0) : 0.0;
        baseUnitsByHouse[house.id] = base;
        subUnitsByHouse[house.id] = sub;
        meterTotalUnits += base + sub;
      }

      final meterBill = tariffService.calculateBill(meterTotalUnits);

      // Step 2 & 3: final (weighted) units per house, then proportional split.
      final Map<int, double> finalUnitsByHouse = {};
      double weightSum = 0;
      for (final house in housesOnMeter) {
        final pumpShare = house.sharesPump ? pumpSharePerHouse : 0.0;
        final finalUnits = baseUnitsByHouse[house.id]! + subUnitsByHouse[house.id]! + pumpShare;
        finalUnitsByHouse[house.id] = finalUnits;
        weightSum += finalUnits;
      }

      final houseResults = <HouseResult>[];
      for (final house in housesOnMeter) {
        final finalUnits = finalUnitsByHouse[house.id]!;
        final share = weightSum > 0 ? finalUnits / weightSum : 0.0;
        final bill = share * meterBill;

        houseResults.add(HouseResult(
          houseId: house.id,
          houseName: house.name,
          mainMeterId: meterId,
          baseUnits: baseUnitsByHouse[house.id]!,
          subMeterUnits: subUnitsByHouse[house.id]!,
          pumpShareUnits: house.sharesPump ? pumpSharePerHouse : 0.0,
          finalUnits: finalUnits,
          billAmount: bill,
        ));
      }

      meterResults.add(MeterResult(
        meterId: meterId,
        totalUnits: meterTotalUnits,
        totalBill: meterBill,
        houses: houseResults,
      ));

      grandUnits += meterTotalUnits;
      grandAmount += meterBill;
    }

    return BillCalculationResult(
      meters: meterResults,
      pumpUnits: pumpUnits,
      pumpSharedByCount: sharedByCount,
      grandTotalUnits: grandUnits,
      grandTotalAmount: grandAmount,
      calculatedAt: DateTime.now(),
    );
  }
}
