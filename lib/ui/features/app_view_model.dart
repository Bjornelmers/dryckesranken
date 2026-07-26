import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/models/drink_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/gemini_service.dart';

class AppViewModel extends ChangeNotifier {
  final StorageService _storageService;
  final GeminiService _geminiService;

  List<DrinkModel> _drinks = [];
  bool _isLoading = false;
  String? _apiKey;
  String _searchQuery = '';
  String _selectedTypeFilter = 'Alla';

  AppViewModel(
    this._storageService,
    this._geminiService,
  );

  // Getters
  bool get isLoading => _isLoading;
  String? get apiKey => _apiKey;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  String get searchQuery => _searchQuery;
  String get selectedTypeFilter => _selectedTypeFilter;

  // Initialize and load initial state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.init();
    _drinks = _storageService.getDrinks();
    _apiKey = _storageService.getApiKey();

    _isLoading = false;
    notifyListeners();
  }

  // Get list of drinks based on active search and filter
  List<DrinkModel> get drinks {
    return _drinks.where((drink) {
      // 1. Apply Search Query
      final matchesSearch = drink.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          drink.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          drink.comment.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Apply Type/Category Filter
      final matchesType = _selectedTypeFilter == 'Alla' || drink.type == _selectedTypeFilter;

      return matchesSearch && matchesType;
    }).toList();
  }

  // Raw original drinks list
  List<DrinkModel> get allDrinks => _drinks;

  // Statistics calculation
  int get totalDrinks => _drinks.length;

  double get averageRating {
    if (_drinks.isEmpty) return 0.0;
    final total = _drinks.fold<double>(0.0, (sum, drink) => sum + drink.rating);
    return double.parse((total / _drinks.length).toStringAsFixed(1));
  }

  String get favoriteType {
    if (_drinks.isEmpty) return 'Ingen';
    
    // Group drinks by type and calculate average rating for each type
    final Map<String, List<double>> typeRatings = {};
    for (var drink in _drinks) {
      typeRatings.putIfAbsent(drink.type, () => []).add(drink.rating);
    }

    String bestType = 'Ingen';
    double bestAverage = 0.0;

    typeRatings.forEach((type, ratings) {
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      // We prioritize type with higher rating. If ratings are equal, we choose the one with more entries.
      if (avg > bestAverage || (avg == bestAverage && ratings.length > (typeRatings[bestType]?.length ?? 0))) {
        bestAverage = avg;
        bestType = type;
      }
    });

    return bestType;
  }

  // Unique categories currently present in the database (for filters)
  List<String> get availableCategories {
    final categories = _drinks.map((d) => d.type).toSet().toList();
    categories.sort();
    return ['Alla', ...categories];
  }

  // Actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTypeFilter(String filter) {
    _selectedTypeFilter = filter;
    notifyListeners();
  }

  Future<void> saveApiKey(String apiKey) async {
    _isLoading = true;
    notifyListeners();

    await _storageService.saveApiKey(apiKey);
    _apiKey = _storageService.getApiKey();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteApiKey() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.saveApiKey('');
    _apiKey = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDrink(DrinkModel drink) async {
    _isLoading = true;
    notifyListeners();

    await _storageService.saveDrink(drink);
    _drinks = _storageService.getDrinks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDrink(String id) async {
    _isLoading = true;
    notifyListeners();

    await _storageService.deleteDrink(id);
    _drinks = _storageService.getDrinks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearDatabase() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.clearAll();
    _drinks = [];
    _apiKey = null;

    _isLoading = false;
    notifyListeners();
  }

  // Wrapper for AI Scanning
  Future<Map<String, dynamic>> scanDrink(Uint8List imageBytes) async {
    // This will throw if the API request fails, which UI will handle
    return await _geminiService.scanDrinkLabel(
      imageBytes: imageBytes,
      apiKey: _apiKey,
    );
  }

  // Export all drinks as a JSON string with base64 encoded images
  String exportBackupJson() {
    final list = _drinks.map((drink) {
      final map = drink.toMap();
      if (drink.imageBytes != null) {
        map['imageBytes'] = base64Encode(drink.imageBytes!);
      }
      return map;
    }).toList();

    return jsonEncode(list);
  }

  // Import drinks from a JSON string containing base64 encoded images
  Future<int> importBackupJson(String jsonString) async {
    _isLoading = true;
    notifyListeners();

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw Exception('Backup-filen har felaktigt format.');
      }

      int importCount = 0;
      for (var item in decoded) {
        if (item is Map) {
          // Convert base64 image back to Uint8List
          final String? base64Img = item['imageBytes'] as String?;
          Uint8List? imageBytes;
          if (base64Img != null && base64Img.isNotEmpty) {
            imageBytes = base64Decode(base64Img);
          }

          final mutableItem = Map<String, dynamic>.from(item);
          mutableItem['imageBytes'] = imageBytes;

          final drink = DrinkModel.fromMap(mutableItem);
          await _storageService.saveDrink(drink);
          importCount++;
        }
      }

      // Reload state
      _drinks = _storageService.getDrinks();
      return importCount;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
