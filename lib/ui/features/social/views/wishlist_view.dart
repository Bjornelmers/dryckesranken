import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ranking_app/data/models/drink_model.dart';
import '../social_view_model.dart';
import '../../app_view_model.dart';
import '../../details/views/drink_detail_view.dart';
import '../../../core/theme.dart';
import '../../ranking/views/add_drink_view.dart';

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final socialVm = Provider.of<SocialViewModel>(context);
    final appVm = Provider.of<AppViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borde-prova-lista 📝'),
      ),
      body: socialVm.wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('Din Borde-prova-lista är tom.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Spara drycker du är nyfiken på från dina vänner!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: socialVm.wishlist.length,
              itemBuilder: (context, index) {
                final item = socialVm.wishlist[index];
                final wishId = item['id'] as String;
                final name = item['drinkName'] as String? ?? 'Okänd dryck';
                final brand = item['brand'] as String? ?? '';
                final type = item['type'] as String? ?? 'Övrigt';
                final recommendedBy = item['recommendedBy'] as String?;

                final matchingDrinks = appVm.allDrinks.where((d) =>
                    d.name.toLowerCase().trim() == name.toLowerCase().trim() &&
                    d.brand.toLowerCase().trim() == brand.toLowerCase().trim());
                final DrinkModel? matchingDrink = matchingDrinks.isNotEmpty ? matchingDrinks.first : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (brand.isNotEmpty)
                                    Text(brand, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentCyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        if (recommendedBy != null && recommendedBy.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppTheme.accentGold),
                              const SizedBox(width: 4),
                              Text(
                                'Rekommenderad av $recommendedBy',
                                style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        if (matchingDrink != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.ratingGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.ratingGreen.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppTheme.ratingGreen, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Redan rankad: ${matchingDrink.rating.toStringAsFixed(1)} / 10 ⭐',
                                  style: const TextStyle(color: AppTheme.ratingGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                socialVm.removeFromWishlist(wishId);
                              },
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textSecondary),
                              label: const Text('Ta bort', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            if (matchingDrink != null)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentCyan,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DrinkDetailView(drinkId: matchingDrink.id),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('Visa mitt betyg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            else
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGold,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  final mockDrink = DrinkModel(
                                    id: '',
                                    name: name,
                                    brand: brand,
                                    type: type,
                                    abv: 0.0,
                                    rating: 5.0,
                                    comment: '',
                                    scannedDescription: '',
                                    createdAt: DateTime.now(),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddDrinkView(prefillDrink: mockDrink),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.star, size: 16),
                                label: const Text('Betygsätt nu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
