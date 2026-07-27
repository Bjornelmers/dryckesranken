import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drink_model.dart';

class StorageService {
  static const String _drinksBoxName = 'drinks_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _apiKeyField = 'gemini_api_key';

  late Box _drinksBox;
  late Box _settingsBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _drinksBox = await Hive.openBox(_drinksBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- Local Hive Methods ---

  // Get all saved drinks locally
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

  // Save or update a drink locally
  Future<void> saveDrink(DrinkModel drink) async {
    await _drinksBox.put(drink.id, drink.toMap());
  }

  // Delete a drink locally
  Future<void> deleteDrink(String id) async {
    await _drinksBox.delete(id);
  }

  // --- Cloud Firestore Methods ---

  // Get all saved drinks from Firestore for a specific user
  Future<List<DrinkModel>> getDrinksFromCloud(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinks')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return _fromFirestoreMap(doc.data());
      }).toList();
    } catch (e) {
      print('Error loading drinks from Firestore: $e');
      rethrow;
    }
  }

  // Get a single drink from Firestore
  Future<DrinkModel?> getDrinkFromCloud(String userId, String drinkId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinks')
          .doc(drinkId)
          .get();
      if (doc.exists && doc.data() != null) {
        return _fromFirestoreMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error loading single drink from Firestore: $e');
      return null;
    }
  }

  // Save or update a drink in Firestore
  Future<void> saveDrinkToCloud(String userId, DrinkModel drink) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinks')
          .doc(drink.id)
          .set(_toFirestoreMap(drink));
    } catch (e) {
      print('Error saving drink to Firestore: $e');
      rethrow;
    }
  }

  // Delete a drink from Firestore
  Future<void> deleteDrinkFromCloud(String userId, String drinkId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinks')
          .doc(drinkId)
          .delete();
    } catch (e) {
      print('Error deleting drink from Firestore: $e');
      rethrow;
    }
  }

  // Save API Key to Firestore
  Future<void> saveApiKeyToCloud(String userId, String apiKey) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set({'gemini_api_key': apiKey}, SetOptions(merge: true));
    } catch (e) {
      print('Error saving API Key to Firestore: $e');
      rethrow;
    }
  }

  // Get API Key from Firestore
  Future<String?> getApiKeyFromCloud(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('gemini_api_key')) {
          return data['gemini_api_key'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Error getting API Key from Firestore: $e');
      return null;
    }
  }

  // Helper: Convert DrinkModel to a Firestore-compatible Map
  Map<String, dynamic> _toFirestoreMap(DrinkModel drink) {
    final map = drink.toMap();
    if (drink.imageBytes != null) {
      map['imageBytes'] = base64Encode(drink.imageBytes!);
    }
    return map;
  }

  // Helper: Convert Firestore Map to DrinkModel
  DrinkModel _fromFirestoreMap(Map<String, dynamic> map) {
    Uint8List? bytes;
    final imageVal = map['imageBytes'];
    if (imageVal is String) {
      bytes = base64Decode(imageVal);
    } else if (imageVal is List<int>) {
      bytes = Uint8List.fromList(imageVal);
    }

    final newMap = Map<String, dynamic>.from(map);
    newMap['imageBytes'] = bytes;
    return DrinkModel.fromMap(newMap);
  }

  // --- Settings ---

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

  // Clear all data locally
  Future<void> clearAll() async {
    await _drinksBox.clear();
    await _settingsBox.clear();
  }
}
