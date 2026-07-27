import 'dart:typed_data';

class DrinkModel {
  final String id;
  final String name;
  final String brand;
  final String type;
  final double abv;
  final double rating;
  final String comment;
  final Uint8List? imageBytes;
  final String scannedDescription;
  final DateTime createdAt;
  final String? location;
  final String? companion;
  final String? companionUid;
  final String? country;
  final String? mainCategory;

  DrinkModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.abv,
    required this.rating,
    required this.comment,
    this.imageBytes,
    required this.scannedDescription,
    required this.createdAt,
    this.location,
    this.companion,
    this.companionUid,
    this.country,
    this.mainCategory,
  });

  // Convert DrinkModel to a Map for Hive/Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'type': type,
      'abv': abv,
      'rating': rating,
      'comment': comment,
      'imageBytes': imageBytes,
      'scannedDescription': scannedDescription,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'companion': companion,
      'companionUid': companionUid,
      'country': country,
      'mainCategory': mainCategory ?? 'Övrigt',
    };
  }

  // Create DrinkModel from a Map
  factory DrinkModel.fromMap(Map<dynamic, dynamic> map) {
    return DrinkModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      type: map['type'] as String? ?? '',
      abv: (map['abv'] as num? ?? 0.0).toDouble(),
      rating: (map['rating'] as num? ?? 1.0).toDouble(),
      comment: map['comment'] as String? ?? '',
      imageBytes: map['imageBytes'] as Uint8List?,
      scannedDescription: map['scannedDescription'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      location: map['location'] as String?,
      companion: map['companion'] as String?,
      companionUid: map['companionUid'] as String?,
      country: map['country'] as String?,
      mainCategory: map['mainCategory'] as String? ?? 'Övrigt',
    );
  }

  // Helper method to create a copy of the model with modified fields
  DrinkModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? type,
    double? abv,
    double? rating,
    String? comment,
    Uint8List? imageBytes,
    String? scannedDescription,
    DateTime? createdAt,
    String? location,
    String? companion,
    String? companionUid,
    String? country,
    String? mainCategory,
  }) {
    return DrinkModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      abv: abv ?? this.abv,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageBytes: imageBytes ?? this.imageBytes,
      scannedDescription: scannedDescription ?? this.scannedDescription,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      companion: companion ?? this.companion,
      companionUid: companionUid ?? this.companionUid,
      country: country ?? this.country,
      mainCategory: mainCategory ?? this.mainCategory,
    );
  }
}
