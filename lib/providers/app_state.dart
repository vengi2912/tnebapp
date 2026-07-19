import 'package:flutter/foundation.dart';

import '../models/house_model.dart';
import '../models/tariff_model.dart';
import '../services/calculation_service.dart';
import '../services/prefs_service.dart';

/// App-wide state: house/meter wiring, tariff configuration, theme, and the
/// most recent calculation result. Exposed via [ChangeNotifierProvider] at
/// the root of the widget tree.
class AppState extends ChangeNotifier {
  final PrefsService _prefsService = PrefsService();

  List<HouseConfig> houses = HouseConfig.defaultLayout();
  TariffConfig tariffConfig = TariffConfig.defaults();
  bool isDarkMode = false;
  bool isLoaded = false;

  BillCalculationResult? lastResult;

  Future<void> init() async {
    houses = await _prefsService.loadHouses();
    tariffConfig = await _prefsService.loadTariff();
    isDarkMode = await _prefsService.loadDarkMode();
    isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode = value;
    await _prefsService.saveDarkMode(value);
    notifyListeners();
  }

  Future<void> updateHouses(List<HouseConfig> updated) async {
    houses = updated;
    await _prefsService.saveHouses(updated);
    notifyListeners();
  }

  Future<void> updateTariff(TariffConfig updated) async {
    tariffConfig = updated;
    await _prefsService.saveTariff(updated);
    notifyListeners();
  }

  Future<void> resetTariffToDefaults() async {
    tariffConfig = TariffConfig.defaults();
    await _prefsService.saveTariff(tariffConfig);
    notifyListeners();
  }

  BillCalculationResult calculate({
    required Map<int, double> houseUnits,
    required Map<int, double> subMeterUnits,
    required double pumpUnits,
  }) {
    final service = CalculationService(tariffConfig);
    final result = service.calculate(
      houseConfigs: houses,
      houseUnits: houseUnits,
      subMeterUnits: subMeterUnits,
      pumpUnits: pumpUnits,
    );
    lastResult = result;
    notifyListeners();
    return result;
  }
}
