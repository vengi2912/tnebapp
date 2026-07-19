import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/house_model.dart';

/// Displays a single house's computed bill breakdown in a compact tile:
/// House Number | House Units | Pump Share | Final Units | Bill Amount.
class HouseResultTile extends StatelessWidget {
  final HouseResult result;

  const HouseResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primaryContainer,
            child: Text('${result.houseId}', style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.houseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Units: ${result.houseUnitsEntered.toStringAsFixed(2)}  '
                  '+ Pump: ${result.pumpShareUnits.toStringAsFixed(2)}  '
                  '= Final: ${result.finalUnits.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            currency.format(result.billAmount),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
