import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/number_input_field.dart';
import '../widgets/section_card.dart';
import 'history_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

/// Main dashboard screen: shows live main-meter totals and collects every
/// input required for the monthly bill split (house units, sub meters,
/// water pump units and sharing).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  // House unit controllers, keyed by house id (1-6).
  final Map<int, TextEditingController> _houseControllers = {
    for (int i = 1; i <= 6; i++) i: TextEditingController(),
  };

  // Sub meter controllers, keyed by sub meter id (1-4).
  final Map<int, TextEditingController> _subMeterControllers = {
    for (int i = 1; i <= 4; i++) i: TextEditingController(),
  };

  final _pumpUnitsController = TextEditingController();
  final _pumpSharedByController = TextEditingController(text: '6');

  @override
  void dispose() {
    for (final c in _houseControllers.values) {
      c.dispose();
    }
    for (final c in _subMeterControllers.values) {
      c.dispose();
    }
    _pumpUnitsController.dispose();
    _pumpSharedByController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  /// Live preview of each main meter's total units as the user types,
  /// computed from currently-assigned houses + sub meters (no pump).
  Map<int, double> _livePreviewTotals(AppState state) {
    final totals = <int, double>{1: 0, 2: 0, 3: 0};
    for (final house in state.houses) {
      final base = _parse(_houseControllers[house.id]!);
      final sub = house.subMeterId != null ? _parse(_subMeterControllers[house.subMeterId]!) : 0.0;
      totals[house.mainMeterId] = (totals[house.mainMeterId] ?? 0) + base + sub;
    }
    return totals;
  }

  void _calculateAndNavigate(AppState state) {
    if (!_formKey.currentState!.validate()) return;

    final houseUnits = {for (final e in _houseControllers.entries) e.key: _parse(e.value)};
    final subUnits = {for (final e in _subMeterControllers.entries) e.key: _parse(e.value)};
    final pumpUnits = _parse(_pumpUnitsController);

    final result = state.calculate(
      houseUnits: houseUnits,
      subMeterUnits: subUnits,
      pumpUnits: pumpUnits,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final totals = _livePreviewTotals(state);

        return Scaffold(
          appBar: AppBar(
            title: const Text('TNEB Bill Splitter'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Previous Bills',
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _MeterTotalsDashboard(totals: totals),
                const SizedBox(height: 8),
                SectionCard(
                  title: 'House Units',
                  icon: Icons.house,
                  children: [
                    for (final house in state.houses)
                      NumberInputField(
                        label: '${house.name}'
                            '${house.subMeterId != null ? ' (Meter ${house.mainMeterId}, Sub ${house.subMeterId})' : ' (Meter ${house.mainMeterId})'}',
                        controller: _houseControllers[house.id]!,
                      ),
                  ],
                ),
                SectionCard(
                  title: 'Sub Meter Readings',
                  icon: Icons.speed,
                  children: [
                    for (int i = 1; i <= 4; i++)
                      NumberInputField(
                        label: 'Sub Meter $i',
                        controller: _subMeterControllers[i]!,
                      ),
                  ],
                ),
                SectionCard(
                  title: 'Common Water Pump',
                  icon: Icons.water_drop,
                  children: [
                    NumberInputField(
                      label: 'Water Pump Units',
                      controller: _pumpUnitsController,
                      prefixIcon: Icons.water,
                    ),
                    NumberInputField(
                      label: 'Shared By (no. of houses)',
                      controller: _pumpSharedByController,
                      suffixText: 'houses',
                      prefixIcon: Icons.people,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tip: edit which specific houses share the pump from Settings.',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _calculateAndNavigate(state),
                  icon: const Icon(Icons.calculate),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Calculate Bill', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Attractive dashboard row showing each Main Meter's live total units.
class _MeterTotalsDashboard extends StatelessWidget {
  final Map<int, double> totals;

  const _MeterTotalsDashboard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [scheme.primary, scheme.secondary, scheme.tertiary];

    return Row(
      children: [
        for (int i = 1; i <= 3; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: colors[i - 1].withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors[i - 1].withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Icon(Icons.electric_meter, color: colors[i - 1]),
                  const SizedBox(height: 4),
                  Text('Meter $i', style: TextStyle(fontWeight: FontWeight.bold, color: colors[i - 1])),
                  const SizedBox(height: 2),
                  Text(
                    '${(totals[i] ?? 0).toStringAsFixed(1)} units',
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
