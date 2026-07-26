import 'package:hive_flutter/hive_flutter.dart';
import '../models/drink_model.dart';

class StorageService {
  static const String _drinksBoxName = 'drinks_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _apiKeyField = 'gemini_api_key';

  late Box _drinksBox;
  late Box _settingsBox;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _drinksBox = await Hive.openBox(_drinksBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // Get all saved drinks, sorted by creation date (newest first)
  List<DrinkModel> getDrinks() {
    try {
      final List<DrinkModel> drinks = [];
      for (var key in _drinksBox.keys) {
        final data = _drinksBox.get(key);
        if (data is Map) {
          drinks.add(DrinkModel.fromMap(data));
        }
      }
      drinks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return drinks;
    } catch (e) {
      print('Error loading drinks from Hive: $e');
      return [];
    }
  }

  // Save or update a drink
  Future<void> saveDrink(DrinkModel drink) async {
    await _drinksBox.put(drink.id, drink.toMap());
  }

  // Delete a drink
  Future<void> deleteDrink(String id) async {
    await _drinksBox.delete(id);
  }

  // Save the Gemini API Key
  Future<void> saveApiKey(String apiKey) async {
    await _settingsBox.put(_apiKeyField, apiKey);
  }

  // Get the Gemini API Key
  String? getApiKey() {
    final key = _settingsBox.get(_apiKeyField);
    if (key is String && key.trim().isNotEmpty) {
      return key.trim();
    }
    return null;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _drinksBox.clear();
    await _settingsBox.clear();
  }
}
