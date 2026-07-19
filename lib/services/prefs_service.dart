import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/house_model.dart';
import '../models/tariff_model.dart';

/// Persists user-editable settings: tariff rates, house/meter/sub-meter
/// wiring, and the dark-mode preference.
class PrefsService {
  static const _tariffKey = 'tneb_tariff_config';
  static const _housesKey = 'tneb_house_configs';
  static const _themeKey = 'tneb_dark_mode';

  Future<TariffConfig> loadTariff() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tariffKey);
    if (raw == null) return TariffConfig.defaults();
    try {
      return TariffConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return TariffConfig.defaults();
    }
  }

  Future<void> saveTariff(TariffConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tariffKey, jsonEncode(config.toJson()));
  }

  Future<List<HouseConfig>> loadHouses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_housesKey);
    if (raw == null) return HouseConfig.defaultLayout();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => HouseConfig.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return HouseConfig.defaultLayout();
    }
  }

  Future<void> saveHouses(List<HouseConfig> houses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_housesKey, jsonEncode(houses.map((h) => h.toJson()).toList()));
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }
}
