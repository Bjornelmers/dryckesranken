import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ranking_app/data/models/drink_model.dart';
import 'package:ranking_app/ui/core/theme.dart';
import '../../app_view_model.dart';
import '../../social/social_view_model.dart';

class BatchAddDrinkView extends StatefulWidget {
  final List<XFile> images;

  const BatchAddDrinkView({super.key, required this.images});

  @override
  State<BatchAddDrinkView> createState() => _BatchAddDrinkViewState();
}

class _BatchAddDrinkViewState extends State<BatchAddDrinkView> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Uint8List? _currentImageBytes;
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

    // Start scanning the first image automatically after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndScanCurrent();
    });
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
    super.dispose();
  }

  // Load image bytes and trigger the scan
  Future<void> _loadAndScanCurrent() async {
    if (_currentIndex >= widget.images.length) return;

    final viewModel = Provider.of<AppViewModel>(context, listen: false);

    setState(() {
      _isScanning = true;
      _hasScanned = false;
      _errorMessage = '';
      _nameController.clear();
      _brandController.clear();
      _abvController.clear();
      _descriptionController.clear();
      _commentController.clear();
      _rating = 5.0;
      _typeController.text = 'Lager';
    });

    try {
      final file = widget.images[_currentIndex];
      final bytes = await file.readAsBytes();
      
      setState(() {
        _currentImageBytes = bytes;
      });

      _animationController.forward();

      final result = await viewModel.scanDrink(bytes);

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
        // Allow user to manually input details even if scan fails
        _hasScanned = true;
      });
    } finally {
      _animationController.stop();
      _animationController.reset();
    }
  }

  // Save current drink and progress the wizard
  Future<void> _saveAndNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentImageBytes == null) return;

    final abv = double.tryParse(_abvController.text) ?? 0.0;

    final newDrink = DrinkModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      type: _typeController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).join(', '),
      abv: abv,
      rating: _rating,
      comment: _commentController.text.trim(),
      imageBytes: _currentImageBytes,
      scannedDescription: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
    );

    final viewModel = Provider.of<AppViewModel>(context, listen: false);
    await viewModel.addDrink(newDrink);

    final socialVm = Provider.of<SocialViewModel>(context, listen: false);
    await socialVm.notifyFriendsOfRating(newDrink);

    _nextStep();
  }

  // Move to next step or complete
  void _nextStep() {
    if (_currentIndex < widget.images.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadAndScanCurrent();
    } else {
      // Completed all items
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.images.length} drycker har lagts till i ditt bibliotek!'),
          backgroundColor: AppTheme.ratingGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  // Skip the current photo
  void _skipCurrent() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hoppa över bild?'),
          content: const Text('Är du säker på att du vill hoppa över denna bild? Drycken sparas inte.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                _nextStep();
              },
              child: const Text('Ja, hoppa över'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / widget.images.length;
    final viewModel = Provider.of<AppViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Import-guide (${_currentIndex + 1} av ${widget.images.length})'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            onPressed: _skipCurrent,
            icon: const Icon(Icons.skip_next),
            label: const Text('Hoppa över'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Elegant progress indicator bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderLight,
            color: AppTheme.accentCyan,
            minHeight: 5,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
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
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.ratingRed),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Kunde inte läsa av automatiskt. Fyll i detaljerna manuellt nedan.\n($_errorMessage)',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Image scanner box
                      _buildPhotoBox(),
                      const SizedBox(height: 24),

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

                      // Input forms (Only show when scan has completed or failed but bytes loaded)
                      if (_hasScanned && !_isScanning) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                        divisions: 18,
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
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              ElevatedButton(
                                onPressed: _saveAndNext,
                                child: Text(
                                  _currentIndex < widget.images.length - 1
                                      ? 'Spara & Nästa dryck (${_currentIndex + 2} av ${widget.images.length})'
                                      : 'Spara & Slutför',
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
        ),
        child: Stack(
          children: [
            // Preview Image
            if (_currentImageBytes != null)
              Positioned.fill(
                child: Image.memory(
                  _currentImageBytes!,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Scanning Overlay Laser Animation
            if (_currentImageBytes != null && _isScanning)
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  final offset = _laserAnimation.value * 300;
                  return Stack(
                    children: [
                      Container(color: Colors.black.withOpacity(0.3)),
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
          ],
        ),
      ),
    );
  }
}
