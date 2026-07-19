import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/house_model.dart';
import '../models/tariff_model.dart';
import '../providers/app_state.dart';

/// Lets the user customise:
///  - Tariff rates for both slab tables (values only, limits stay fixed to
///    match official TNEB slab boundaries).
///  - Which main meter / sub meter each house is wired to, and whether it
///    shares the common water pump.
///  - Light / Dark mode.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<TextEditingController> _lowRateControllers;
  late List<TextEditingController> _highRateControllers;
  late List<HouseConfig> _houses;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _lowRateControllers =
        state.tariffConfig.lowTable.map((s) => TextEditingController(text: s.ratePerUnit.toStringAsFixed(2))).toList();
    _highRateControllers =
        state.tariffConfig.highTable.map((s) => TextEditingController(text: s.ratePerUnit.toStringAsFixed(2))).toList();
    // Deep copy so edits don't mutate live state until saved.
    _houses = state.houses
        .map((h) => HouseConfig(
              id: h.id,
              name: h.name,
              mainMeterId: h.mainMeterId,
              subMeterId: h.subMeterId,
              sharesPump: h.sharesPump,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in [..._lowRateControllers, ..._highRateControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTariff(AppState state) async {
    final lowTable = <TariffSlab>[];
    for (int i = 0; i < state.tariffConfig.lowTable.length; i++) {
      final rate = double.tryParse(_lowRateControllers[i].text) ?? state.tariffConfig.lowTable[i].ratePerUnit;
      lowTable.add(state.tariffConfig.lowTable[i].copyWith(ratePerUnit: rate));
    }
    final highTable = <TariffSlab>[];
    for (int i = 0; i < state.tariffConfig.highTable.length; i++) {
      final rate = double.tryParse(_highRateControllers[i].text) ?? state.tariffConfig.highTable[i].ratePerUnit;
      highTable.add(state.tariffConfig.highTable[i].copyWith(ratePerUnit: rate));
    }
    await state.updateTariff(TariffConfig(lowTable: lowTable, highTable: highTable));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tariff rates saved')));
    }
  }

  Future<void> _saveHouses(AppState state) async {
    await state.updateHouses(_houses);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('House wiring saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Theme
              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: state.isDarkMode,
                  onChanged: (v) => state.toggleDarkMode(v),
                ),
              ),
              const SizedBox(height: 8),

              // Tariff: <=500 table
              _TariffTableEditor(
                title: 'Tariff: Total Units ≤ 500',
                slabs: state.tariffConfig.lowTable,
                controllers: _lowRateControllers,
              ),
              const SizedBox(height: 8),

              // Tariff: >500 table
              _TariffTableEditor(
                title: 'Tariff: Total Units > 500',
                slabs: state.tariffConfig.highTable,
                controllers: _highRateControllers,
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _saveTariff(state),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Tariff'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await state.resetTariffToDefaults();
                      setState(() {
                        _lowRateControllers = state.tariffConfig.lowTable
                            .map((s) => TextEditingController(text: s.ratePerUnit.toStringAsFixed(2)))
                            .toList();
                        _highRateControllers = state.tariffConfig.highTable
                            .map((s) => TextEditingController(text: s.ratePerUnit.toStringAsFixed(2)))
                            .toList();
                      });
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // House / meter / sub-meter / pump wiring
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('House Wiring & Pump Sharing',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      for (final house in _houses) _HouseWiringRow(house: house, onChanged: () => setState(() {})),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _saveHouses(state),
                        icon: const Icon(Icons.save),
                        label: const Text('Save House Wiring'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _TariffTableEditor extends StatelessWidget {
  final String title;
  final List<TariffSlab> slabs;
  final List<TextEditingController> controllers;

  const _TariffTableEditor({required this.title, required this.slabs, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            for (int i = 0; i < slabs.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(slabs[i].label(i == 0 ? 0 : (slabs[i - 1].uptoUnits ?? 0)))),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controllers[i],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(prefixText: '₹ ', isDense: true),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HouseWiringRow extends StatelessWidget {
  final HouseConfig house;
  final VoidCallback onChanged;

  const _HouseWiringRow({required this.house, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(house.name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: house.mainMeterId,
              decoration: const InputDecoration(labelText: 'Meter', isDense: true),
              items: [1, 2, 3].map((m) => DropdownMenuItem(value: m, child: Text('Meter $m'))).toList(),
              onChanged: (v) {
                if (v != null) {
                  house.mainMeterId = v;
                  onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int?>(
              initialValue: house.subMeterId,
              decoration: const InputDecoration(labelText: 'Sub Meter', isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                ...[1, 2, 3, 4].map((s) => DropdownMenuItem<int?>(value: s, child: Text('Sub $s'))),
              ],
              onChanged: (v) {
                house.subMeterId = v;
                onChanged();
              },
            ),
          ),
          Checkbox(
            value: house.sharesPump,
            onChanged: (v) {
              house.sharesPump = v ?? true;
              onChanged();
            },
          ),
          const Text('Pump', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
