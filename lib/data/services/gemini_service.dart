import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Scans the drink label from the image bytes.
  // If apiKey is null/empty, it runs in simulated demo mode.
  Future<Map<String, dynamic>> scanDrinkLabel({
    required Uint8List imageBytes,
    required String? apiKey,
  }) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      // Run in demo mode with simulated delay
      await Future.delayed(const Duration(seconds: 2));
      return _generateMockScanResult();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
Analyze this image of a drink bottle or can.
Identify the drink details and return them strictly in the following JSON format:
{
  "name": "Name of the drink (e.g., Punk IPA, Coca Cola Zero)",
  "brand": "Brand or brewery/producer (e.g., BrewDog, Coca-Cola)",
  "mainCategory": "Choose exactly one from this list: Öl, Vin, Sprit, Cider, Likör, Alkoholfritt, Övrigt",
  "type": "Specific subcategory or style (e.g., IPA, Lager, Stout, Rött vin, Vitt vin, Gin, Rom, Bourbon)",
  "abv": 5.4, // Alcohol by volume (ABV) as a double. Use 0.0 for non-alcoholic.
  "country": "Country of origin if visible or known (e.g., Sweden, Belgium, USA). Return empty string if unknown.",
  "description": "A brief 1-2 sentence description of the drink style or flavor profile extracted or inferred from the label."
}
Make sure the returned text is a single valid JSON object.
IMPORTANT: If you use double quotes inside string values (like in the description or name), you must escape them using backslashes, e.g. \"quotes\".
''';

      final imagePart = DataPart('image/jpeg', imageBytes);
      final textPart = TextPart(prompt);

      final response = await model.generateContent([
        Content.multi([textPart, imagePart])
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Received empty response from Gemini API.');
      }

      // Parse JSON response with robust cleanup
      var cleanedText = responseText.trim();
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.replaceAll(RegExp(r'^```json\s*', caseSensitive: false), '');
        cleanedText = cleanedText.replaceAll(RegExp(r'^```\s*'), '');
        cleanedText = cleanedText.replaceAll(RegExp(r'\s*```$'), '');
        cleanedText = cleanedText.trim();
      }

      final Map<String, dynamic> parsedJson = json.decode(cleanedText);
      return parsedJson;
    } catch (e) {
      print('Gemini Scan Error: $e');
      throw Exception('Det gick inte att läsa av etiketten. Kontrollera din API-nyckel och bildkvalitet. ($e)');
    }
  }

  // Generates realistic mock drink data for demonstration purposes
  Map<String, dynamic> _generateMockScanResult() {
    final List<Map<String, dynamic>> mocks = [
      {
        'name': 'DIPA Double Dry Hopped',
        'brand': 'O/O Brewing',
        'mainCategory': 'Öl',
        'type': 'IPA',
        'abv': 8.0,
        'country': 'Sverige',
        'description': 'En intensiv och humlearomatisk dubbel IPA med toner av mango, citrus och barrskog.'
      },
      {
        'name': 'Melleruds Utmärkta Pilsner',
        'brand': 'Spendrups',
        'mainCategory': 'Öl',
        'type': 'Pilsner',
        'abv': 4.5,
        'country': 'Sverige',
        'description': 'En klassisk svensk ekologisk pilsner med balanserad beska och ren, maltig smak.'
      },
      {
        'name': 'Nectarine Cider',
        'brand': 'Kopparbergs',
        'mainCategory': 'Cider',
        'type': 'Cider',
        'abv': 4.0,
        'country': 'Sverige',
        'description': 'Söt och uppfriskande äppelcider med en tydlig karaktär av solmogen nektarin.'
      },
      {
        'name': 'Monster Energy Ultra',
        'brand': 'Monster Beverage',
        'mainCategory': 'Övrigt',
        'type': 'Energy Drink',
        'abv': 0.0,
        'country': 'USA',
        'description': 'Kolsyrad energidryck utan socker, berikad med taurin, ginseng, koffein och B-vitaminer.'
      },
      {
        'name': 'Coca-Cola Zero Sugar',
        'brand': 'The Coca-Cola Company',
        'mainCategory': 'Alkoholfritt',
        'type': 'Soda',
        'abv': 0.0,
        'country': 'USA',
        'description': 'Klassisk uppfriskande läskedryck med colasmak helt utan socker och kalorier.'
      },
      {
        'name': 'Negroamaro Zinfandel',
        'brand': 'Castel Forte',
        'mainCategory': 'Vin',
        'type': 'Rött vin',
        'abv': 13.5,
        'country': 'Italien',
        'description': 'Fylligt och fruktigt rött vin från Italien med inslag av mörka bär, choklad och kryddor.'
      }
    ];

    // Pick a random mock from the list
    final randomIndex = DateTime.now().millisecondsSinceEpoch % mocks.length;
    return mocks[randomIndex];
  }
}
