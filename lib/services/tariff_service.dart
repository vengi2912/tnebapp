import '../models/tariff_model.dart';

/// Implements exact slab-wise TNEB domestic tariff billing.
///
/// TNEB domestic tariff is a *telescopic* (cumulative) slab structure:
/// each slab's rate only applies to the units that fall inside that slab,
/// not to the whole consumption. The correct table is chosen based on
/// whether total units are <= 500 or > 500.
class TariffService {
  final TariffConfig config;

  const TariffService(this.config);

  /// Returns the appropriate slab table for the given total units.
  List<TariffSlab> _tableFor(double totalUnits) {
    return totalUnits <= 500 ? config.lowTable : config.highTable;
  }

  /// Calculates the total bill amount for [totalUnits] consumed on a single
  /// meter, applying each slab's rate only to the units within that slab.
  double calculateBill(double totalUnits) {
    if (totalUnits <= 0) return 0.0;

    final slabs = _tableFor(totalUnits);
    double remaining = totalUnits;
    double previousLimit = 0;
    double total = 0.0;

    for (final slab in slabs) {
      if (remaining <= 0) break;

      final double slabCeiling = (slab.uptoUnits ?? double.maxFinite).toDouble();
      final double slabCapacity = slabCeiling - previousLimit;
      final double unitsInSlab = remaining < slabCapacity ? remaining : slabCapacity;

      if (unitsInSlab > 0) {
        total += unitsInSlab * slab.ratePerUnit;
        remaining -= unitsInSlab;
      }
      previousLimit = slabCeiling;
    }

    return total;
  }

  /// Returns a per-slab breakdown (for display/PDF), e.g. useful to show the
  /// user exactly how the bill was built up.
  List<SlabBreakdownLine> breakdown(double totalUnits) {
    if (totalUnits <= 0) return [];

    final slabs = _tableFor(totalUnits);
    double remaining = totalUnits;
    double previousLimit = 0;
    final lines = <SlabBreakdownLine>[];

    for (final slab in slabs) {
      if (remaining <= 0) break;

      final double slabCeiling = (slab.uptoUnits ?? double.maxFinite).toDouble();
      final double slabCapacity = slabCeiling - previousLimit;
      final double unitsInSlab = remaining < slabCapacity ? remaining : slabCapacity;

      if (unitsInSlab > 0) {
        lines.add(SlabBreakdownLine(
          label: slab.label(previousLimit.toInt()),
          units: unitsInSlab,
          rate: slab.ratePerUnit,
          amount: unitsInSlab * slab.ratePerUnit,
        ));
        remaining -= unitsInSlab;
      }
      previousLimit = slabCeiling;
    }
    return lines;
  }
}

class SlabBreakdownLine {
  final String label;
  final double units;
  final double rate;
  final double amount;

  SlabBreakdownLine({
    required this.label,
    required this.units,
    required this.rate,
    required this.amount,
  });
}
