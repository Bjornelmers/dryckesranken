import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ranking_app/data/models/drink_model.dart';
import 'package:ranking_app/ui/core/theme.dart';
import '../../app_view_model.dart';
import '../../social/social_view_model.dart';

class AddDrinkView extends StatefulWidget {
  final DrinkModel? drinkToEdit;
  final DrinkModel? prefillDrink;

  const AddDrinkView({
    super.key,
    this.drinkToEdit,
    this.prefillDrink,
  });

  @override
  State<AddDrinkView> createState() => _AddDrinkViewState();
}

class _AddDrinkViewState extends State<AddDrinkView> with SingleTickerProviderStateMixin {
  Uint8List? _imageBytes;
  
  bool get _isMobile {
    return defaultTargetPlatform == TargetPlatform.iOS ||
           defaultTargetPlatform == TargetPlatform.android;
  }
  bool _isScanning = false;
  bool _hasScanned = false;
  String _errorMessage = '';

  // Scan result controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _abvController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _locationController = TextEditingController();
  final _companionController = TextEditingController();
  String? _companionUid;
  bool _isLocating = false;
  
  final _typeController = TextEditingController();
  double _rating = 5.0;

  // Scanning laser animation
  late AnimationController _animationController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });

    // Pre-populate if editing or prefilling from friend's review
    if (widget.drinkToEdit != null) {
      final drink = widget.drinkToEdit!;
      _imageBytes = drink.imageBytes;
      _hasScanned = true;
      _nameController.text = drink.name;
      _brandController.text = drink.brand;
      _abvController.text = drink.abv.toString();
      _descriptionController.text = drink.scannedDescription;
      _commentController.text = drink.comment;
      _typeController.text = drink.type;
      _rating = drink.rating;
      _locationController.text = drink.location ?? '';
      _companionController.text = drink.companion ?? '';
      _companionUid = drink.companionUid;
    } else if (widget.prefillDrink != null) {
      final drink = widget.prefillDrink!;
      _imageBytes = drink.imageBytes;
      _hasScanned = true;
      _nameController.text = drink.name;
      _brandController.text = drink.brand;
      _abvController.text = drink.abv.toString();
      _descriptionController.text = drink.scannedDescription;
      _typeController.text = drink.type;
      _commentController.text = '';
      _rating = 5.0;
      _locationController.text = drink.location ?? '';
      _companionController.text = drink.companion ?? '';
      _companionUid = drink.companionUid;
    } else {
      _typeController.text = 'Lager';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _abvController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    _locationController.dispose();
    _companionController.dispose();
    super.dispose();
  }

  // Pick image helper
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = '';
    });
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _hasScanned = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Det gick inte att välja bild: $e';
      });
    }
  }

  // AI label scan runner
  Future<void> _runLabelScan() async {
    if (_imageBytes == null) return;

    setState(() {
      _isScanning = true;
      _errorMessage = '';
    });
    _animationController.forward();

    try {
      final viewModel = Provider.of<AppViewModel>(context, listen: false);
      final result = await viewModel.scanDrink(_imageBytes!);

      setState(() {
        _nameController.text = result['name'] ?? '';
        _brandController.text = result['brand'] ?? '';
        _descriptionController.text = result['description'] ?? '';
        
        final detectedType = result['type'] as String?;
        final detectedCountry = result['country'] as String?;
        
        String cleanCountry = '';
        if (detectedCountry != null && detectedCountry.trim().isNotEmpty) {
          final c = detectedCountry.trim().toLowerCase();
          if (c == 'sweden') cleanCountry = 'Sverige';
          else if (c == 'germany') cleanCountry = 'Tyskland';
          else if (c == 'belgium') cleanCountry = 'Belgien';
          else if (c == 'usa' || c == 'united states') cleanCountry = 'USA';
          else if (c == 'united kingdom' || c == 'uk' || c == 'england') cleanCountry = 'Storbritannien';
          else if (c == 'czech republic') cleanCountry = 'Tjeckien';
          else {
            cleanCountry = detectedCountry.trim();
            if (cleanCountry.isNotEmpty) {
              cleanCountry = cleanCountry[0].toUpperCase() + cleanCountry.substring(1);
            }
          }
        }

        final List<String> tags = [];
        if (detectedType != null && detectedType.isNotEmpty) {
          tags.add(detectedType);
        }
        if (cleanCountry.isNotEmpty) {
          tags.add(cleanCountry);
        }
        _typeController.text = tags.join(', ');

        final detectedAbv = result['abv'];
        if (detectedAbv is num) {
          _abvController.text = detectedAbv.toString();
        } else {
          _abvController.text = '0.0';
        }

        _isScanning = false;
        _hasScanned = true;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      _animationController.stop();
      _animationController.reset();
    }
  }

  // Save the drink entry
  Future<void> _saveDrink() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) return;

    final abv = double.tryParse(_abvController.text) ?? 0.0;
    
    final isEditing = widget.drinkToEdit != null;
    final drink = DrinkModel(
      id: isEditing ? widget.drinkToEdit!.id : DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      type: _typeController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).join(', '),
      abv: abv,
      rating: _rating,
      comment: _commentController.text.trim(),
      imageBytes: _imageBytes,
      scannedDescription: _descriptionController.text.trim(),
      createdAt: isEditing ? widget.drinkToEdit!.createdAt : DateTime.now(),
      location: _locationController.text.trim(),
      companion: _companionController.text.trim(),
      companionUid: _companionUid,
    );

    final viewModel = Provider.of<AppViewModel>(context, listen: false);
    await viewModel.addDrink(drink);

    final socialVm = Provider.of<SocialViewModel>(context, listen: false);
    await socialVm.notifyFriendsOfRating(drink);
    if (_companionUid != null && _companionUid!.isNotEmpty) {
      await socialVm.notifyCompanionOfDrink(targetCompanionUid: _companionUid!, drink: drink);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? '${drink.name} har uppdaterats!'
              : '${drink.name} sparades framgångsrikt!'),
          backgroundColor: AppTheme.ratingGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drinkToEdit != null ? 'Redigera Dryck' : 'Ranka Ny Dryck'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.ratingRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.ratingRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),

                // Step 1: Select/Take Photo Box
                _buildPhotoSelectorBox(),
                const SizedBox(height: 24),

                if (_imageBytes != null && !_hasScanned && !_isScanning)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: AppTheme.darkBackground,
                    ),
                    onPressed: _runLabelScan,
                    icon: const Icon(Icons.psychology),
                    label: Text(
                      viewModel.hasApiKey
                          ? 'Analysera etikett med Gemini AI'
                          : 'Kör test-analys (Demo)',
                    ),
                  ),

                if (_isScanning)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: AppTheme.accentGold),
                        const SizedBox(height: 12),
                        Text(
                          viewModel.hasApiKey
                              ? 'Analyserar etiketten med Gemini AI...'
                              : 'Simulerar skanning av flaska/burk...',
                          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // Step 2: Input forms and rank sliders (Only show once scanned/skipped)
                if (_hasScanned && !_isScanning) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          ' Dryckesdetaljer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),

                        // Form card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Dryckesnamn *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Ange dryckesnamn' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(labelText: 'Varumärke / Bryggeri *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Ange varumärke' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                   children: [
                                     Expanded(
                                       flex: 2,
                                       child: TextFormField(
                                         controller: _typeController,
                                         decoration: const InputDecoration(
                                           labelText: 'Kategorier / Taggar (t.ex. Lager, Sverige)',
                                           hintText: 'Lager, Sverige',
                                         ),
                                         validator: (v) => v == null || v.trim().isEmpty ? 'Ange minst en kategori' : null,
                                       ),
                                     ),
                                     const SizedBox(width: 16),
                                     Expanded(
                                       flex: 1,
                                       child: TextFormField(
                                         controller: _abvController,
                                         decoration: const InputDecoration(labelText: 'ABV (%)', hintText: '5.0'),
                                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                         validator: (v) {
                                           if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                             return 'Fel format';
                                           }
                                           return null;
                                         },
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 12),
                                 Align(
                                   alignment: Alignment.centerLeft,
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       const Text(
                                         'Snabbtaggar (klicka för att lägga till/ta bort):',
                                         style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                       ),
                                       const SizedBox(height: 8),
                                       Wrap(
                                         spacing: 6.0,
                                         runSpacing: 6.0,
                                         children: [
                                           'IPA', 'Lager', 'Stout', 'Pilsner', 'Cider', 'Suröl', 'Vin',
                                           'Sverige', 'Tyskland', 'Belgien', 'USA', 'Storbritannien', 'Tjeckien'
                                         ].map((tag) {
                                           final currentText = _typeController.text;
                                           final tagsList = currentText
                                               .split(',')
                                               .map((t) => t.trim())
                                               .where((t) => t.isNotEmpty)
                                               .toList();
                                           final isSelected = tagsList.any((t) => t.toLowerCase() == tag.toLowerCase());
                                           return FilterChip(
                                             label: Text(tag, style: const TextStyle(fontSize: 12)),
                                             selected: isSelected,
                                             selectedColor: AppTheme.accentGold.withOpacity(0.2),
                                             checkmarkColor: AppTheme.accentGold,
                                             onSelected: (selected) {
                                               setState(() {
                                                 if (selected) {
                                                   if (!tagsList.any((t) => t.toLowerCase() == tag.toLowerCase())) {
                                                     tagsList.add(tag);
                                                   }
                                                 } else {
                                                   tagsList.removeWhere((t) => t.toLowerCase() == tag.toLowerCase());
                                                 }
                                                 _typeController.text = tagsList.join(', ');
                                               });
                                             },
                                           );
                                         }).toList(),
                                       ),
                                     ],
                                   ),
                                 ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'AI-Etikettbeskrivning',
                                    hintText: 'Läses in automatiskt från skanningen...',
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Rating Slider card
                        Text(
                          ' Betygsätt & Recensera',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Ditt betyg:',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.getRatingColor(_rating),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: AppTheme.glowShadow(AppTheme.getRatingColor(_rating)),
                                      ),
                                      child: Text(
                                        _rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Slider(
                                  value: _rating,
                                  min: 1.0,
                                  max: 10.0,
                                  divisions: 18, // 0.5 steps
                                  onChanged: (val) {
                                    setState(() {
                                      _rating = val;
                                    });
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('1.0 (Blä)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      Text('5.0 (Helt ok)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      Text('10.0 (Himmelsk)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                 TextFormField(
                                   controller: _commentController,
                                   decoration: const InputDecoration(
                                     labelText: 'Recension / Kommentar (valfritt)',
                                     hintText: 'Hur smakade den? Vad tycker du?',
                                   ),
                                   maxLines: 3,
                                 ),
                                 const SizedBox(height: 24),
                                 Row(
                                   children: [
                                     Expanded(
                                       child: TextFormField(
                                         controller: _locationController,
                                         decoration: InputDecoration(
                                           labelText: 'Var dracks den? (valfritt)',
                                           hintText: _isLocating ? 'Hämtar plats...' : 'T.ex. Stockholm, Sverige',
                                           prefixIcon: const Icon(Icons.location_on, color: AppTheme.accentGold),
                                         ),
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     IconButton(
                                       icon: _isLocating 
                                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold))
                                           : const Icon(Icons.my_location, color: AppTheme.accentGold),
                                       tooltip: 'Hämta min nuvarande position',
                                       onPressed: _getCurrentLocation,
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 24),
                                 Row(
                                   children: [
                                     Expanded(
                                       child: TextFormField(
                                         controller: _companionController,
                                         decoration: const InputDecoration(
                                           labelText: 'Med vem dracks den? (valfritt)',
                                           hintText: 'T.ex. Johan, Mamma eller välj vän',
                                           prefixIcon: Icon(Icons.people, color: AppTheme.accentGold),
                                         ),
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     IconButton(
                                       icon: const Icon(Icons.person_add, color: AppTheme.accentGold),
                                       tooltip: 'Välj vän från appen',
                                       onPressed: () => _showFriendPicker(context),
                                     ),
                                   ],
                                 ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: _saveDrink,
                          child: const Text('Spara recension'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSelectorBox() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
        ),
        child: Stack(
          children: [
            // Preview Image
            if (_imageBytes != null)
              Positioned.fill(
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo,
                      size: 60,
                      color: AppTheme.borderLight,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ingen bild vald',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fota eller ladda upp en bild på flaskan/burken',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isMobile) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceCardColor,
                              foregroundColor: AppTheme.textPrimary,
                              minimumSize: const Size(140, 44),
                              side: const BorderSide(color: AppTheme.borderLight),
                            ),
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Kamera'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceCardColor,
                            foregroundColor: AppTheme.textPrimary,
                            minimumSize: Size(_isMobile ? 140 : 220, 44),
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: Text(_isMobile ? 'Galleri / Fil' : 'Välj bild från datorn'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Scanning Overlay Laser Animation
            if (_imageBytes != null && _isScanning)
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  final offset = _laserAnimation.value * 350;
                  return Stack(
                    children: [
                      // Translucent dark layer
                      Container(color: Colors.black.withOpacity(0.3)),
                      // The moving laser line
                      Positioned(
                        top: offset,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // Change Photo Button overlay
            if (_imageBytes != null && !_isScanning)
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    if (_isMobile) ...[
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          foregroundColor: AppTheme.textPrimary,
                        ),
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      icon: const Icon(Icons.photo_library),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      if (html.window.navigator.geolocation != null) {
        html.window.navigator.geolocation.getCurrentPosition().then((pos) async {
          final coords = pos.coords;
          if (coords != null && coords.latitude != null && coords.longitude != null) {
            final lat = coords.latitude;
            final lng = coords.longitude;

            final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng');
            final response = await http.get(url, headers: {'User-Agent': 'Dryckesranken_App'});
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final address = data['address'] as Map?;
              if (address != null) {
                final city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '';
                final country = address['country'] ?? '';
                setState(() {
                  _locationController.text = city.isNotEmpty ? '$city, $country' : country;
                  _isLocating = false;
                });
              } else {
                setState(() {
                  _locationController.text = '$lat, $lng';
                  _isLocating = false;
                });
              }
            } else {
              setState(() {
                _locationController.text = '$lat, $lng';
                _isLocating = false;
              });
            }
          } else {
            setState(() {
              _isLocating = false;
            });
          }
        }, onError: (err) {
          setState(() {
            _isLocating = false;
          });
        });
      } else {
        setState(() {
          _isLocating = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _showFriendPicker(BuildContext context) {
    final socialVm = Provider.of<SocialViewModel>(context, listen: false);
    if (socialVm.friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du har inga tillagda vänner än.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Välj vem du drack med:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: socialVm.friends.length,
                  itemBuilder: (context, index) {
                    final friend = socialVm.friends[index];
                    final name = friend['displayName'] as String? ?? 'Vän';
                    final photo = friend['photoURL'] as String?;
                    final uid = friend['uid'] as String;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photo != null ? NetworkImage(photo) : null,
                        child: photo == null ? Text(name[0].toUpperCase()) : null,
                      ),
                      title: Text(name),
                      onTap: () {
                        setState(() {
                          _companionController.text = name;
                          _companionUid = uid;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

