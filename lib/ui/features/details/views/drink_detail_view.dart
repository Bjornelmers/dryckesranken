import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ranking_app/data/models/drink_model.dart';
import '../../ranking/views/add_drink_view.dart';
import '../../app_view_model.dart';
import '../../social/social_view_model.dart';
import '../../../core/theme.dart';

class DrinkDetailView extends StatelessWidget {
  final String drinkId;
  final DrinkModel? initialDrink;
  final bool isReadOnly;

  const DrinkDetailView({
    super.key,
    required this.drinkId,
    this.initialDrink,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, viewModel, _) {
        final drinkIndex = viewModel.allDrinks.indexWhere((d) => d.id == drinkId);
        final DrinkModel? targetDrink = initialDrink ?? (drinkIndex != -1 ? viewModel.allDrinks[drinkIndex] : null);

        if (targetDrink == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dryckesdetaljer')),
            body: const Center(
              child: Text('Kunde inte hitta drycken.', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }
        final DrinkModel drink = targetDrink;
        final bool canEdit = !isReadOnly && drinkIndex != -1;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Sliver App Bar with Image
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: true,
                actions: [
                  if (canEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => _editDrink(context, drink),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () => _confirmDelete(context, viewModel, drink.name),
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: drink.imageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              drink.imageBytes!,
                              fit: BoxFit.cover,
                            ),
                            // Black gradient at the bottom of the image for readibility
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(
                            Icons.sports_bar,
                            size: 100,
                            color: AppTheme.borderLight,
                          ),
                        ),
                ),
              ),

              // Detail content body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category and ABV badges + Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: drink.type.split(',').map((tag) {
                                      final t = tag.trim();
                                      if (t.isEmpty) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentCyan.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            t,
                                            style: const TextStyle(
                                              color: AppTheme.accentCyan,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceCardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.borderLight),
                                    ),
                                    child: Text(
                                      drink.abv > 0 ? '${drink.abv}% ABV' : 'Alkoholfri',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${drink.createdAt.day}/${drink.createdAt.month} - ${drink.createdAt.year}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Rating and Title Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      drink.name,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      drink.brand,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentGold,
                                        foregroundColor: Colors.black,
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddDrinkView(prefillDrink: drink),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.rate_review, size: 20),
                                      label: const Text(
                                        'Gör egen recension',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Glowing rating circle
                              Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: AppTheme.getRatingColor(drink.rating),
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.glowShadow(AppTheme.getRatingColor(drink.rating)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        drink.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text(
                                        'av 10',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Comment section
                          Text(
                            'Din recension',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.format_quote, color: AppTheme.accentGold, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      drink.comment,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // AI label description section
                          if (drink.scannedDescription.isNotEmpty) ...[
                            Text(
                              'Om drycken (AI-analys)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: AppTheme.surfaceColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.psychology, color: AppTheme.accentCyan, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                       child: Text(
                                         drink.scannedDescription,
                                         style: const TextStyle(
                                           fontSize: 14,
                                           color: AppTheme.textSecondary,
                                           height: 1.4,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             const SizedBox(height: 24),
                           ],

                           // Social Actions & Friend Ratings
                           Consumer<SocialViewModel>(
                             builder: (context, socialVm, _) {
                               return Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     children: [
                                       Expanded(
                                         child: OutlinedButton.icon(
                                           style: OutlinedButton.styleFrom(
                                             side: const BorderSide(color: AppTheme.accentGold),
                                             padding: const EdgeInsets.symmetric(vertical: 12),
                                           ),
                                           onPressed: () async {
                                             await socialVm.addToWishlist(
                                               drinkName: drink.name,
                                               brand: drink.brand,
                                               type: drink.type,
                                             );
                                             if (context.mounted) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(content: Text('${drink.name} sparad på din Borde-prova-lista! 📝')),
                                               );
                                             }
                                           },
                                           icon: const Icon(Icons.bookmark_add_outlined, color: AppTheme.accentGold, size: 18),
                                           label: const Text('Borde-prova-lista', style: TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                                         ),
                                       ),
                                       const SizedBox(width: 12),
                                       Expanded(
                                         child: ElevatedButton.icon(
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: AppTheme.accentCyan,
                                             foregroundColor: Colors.black,
                                             padding: const EdgeInsets.symmetric(vertical: 12),
                                           ),
                                           onPressed: () => _showRecommendModal(context, socialVm, drink),
                                           icon: const Icon(Icons.send_rounded, size: 18),
                                           label: const Text('Rekommendera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                         ),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 28),

                                   // Friends' Ratings Section
                                   Text(
                                     'Vänners betyg',
                                     style: Theme.of(context).textTheme.titleLarge,
                                   ),
                                   const SizedBox(height: 10),
                                   FutureBuilder<List<Map<String, dynamic>>>(
                                     future: socialVm.getFriendsDrinkRatings(drink.name),
                                     builder: (context, snapshot) {
                                       if (snapshot.connectionState == ConnectionState.waiting) {
                                         return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
                                       }
                                       final ratings = snapshot.data ?? [];
                                       if (ratings.isEmpty) {
                                         return const Card(
                                           child: Padding(
                                             padding: EdgeInsets.all(16.0),
                                             child: Row(
                                               children: [
                                                 Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 20),
                                                 SizedBox(width: 12),
                                                 Expanded(
                                                   child: Text(
                                                     'Ingen av dina vänner har betygsatt denna dryck än.',
                                                     style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         );
                                       }

                                       return Column(
                                         children: ratings.map((item) {
                                           final fName = item['friendName'] as String? ?? 'Vän';
                                           final fPhoto = item['friendPhoto'] as String?;
                                           final score = item['rating'] as double? ?? 5.0;
                                           final comment = item['comment'] as String? ?? '';

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
                                                       Row(
                                                         children: [
                                                           CircleAvatar(
                                                             radius: 16,
                                                             backgroundColor: AppTheme.accentGold.withOpacity(0.2),
                                                             backgroundImage: fPhoto != null ? NetworkImage(fPhoto) : null,
                                                             child: fPhoto == null ? Text(fName[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentGold, fontSize: 12)) : null,
                                                           ),
                                                           const SizedBox(width: 10),
                                                           Text(fName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                         ],
                                                       ),
                                                       Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                         decoration: BoxDecoration(
                                                           color: AppTheme.accentGold.withOpacity(0.2),
                                                           borderRadius: BorderRadius.circular(8),
                                                           border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                                                         ),
                                                         child: Text(
                                                           '${score.toStringAsFixed(1)} / 10 ⭐',
                                                           style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                   if (comment.isNotEmpty) ...[
                                                     const SizedBox(height: 10),
                                                     Text(
                                                       '"$comment"',
                                                       style: const TextStyle(color: AppTheme.textPrimary, fontStyle: FontStyle.italic, fontSize: 13),
                                                     ),
                                                   ],
                                                 ],
                                               ),
                                             ),
                                           );
                                         }).toList(),
                                       );
                                     },
                                   ),
                                 ],
                               );
                             },
                           ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppViewModel viewModel, String drinkName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ta bort recension?'),
          content: Text('Vill du ta bort din recension av "$drinkName" permanent?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: AppTheme.textPrimary,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await viewModel.deleteDrink(drinkId);
                // Pop the dialog
                navigator.pop();
                // Pop the details view back to dashboard
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('"$drinkName" har raderats.')),
                );
              },
              child: const Text('Ja, ta bort'),
            ),
          ],
        );
      },
    );
  }

  void _editDrink(BuildContext context, DrinkModel drink) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDrinkView(drinkToEdit: drink),
      ),
    );
  }

  void _showRecommendModal(BuildContext context, SocialViewModel socialVm, DrinkModel drink) {
    if (socialVm.friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du behöver ha minst en vän för att rekommendera drycker.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekommendera "${drink.name}" till:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: socialVm.friends.length,
                  itemBuilder: (context, index) {
                    final friend = socialVm.friends[index];
                    final fName = friend['displayName'] as String? ?? 'Vän';
                    final fPhoto = friend['photoURL'] as String?;
                    final fUid = friend['uid'] as String;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accentCyan.withOpacity(0.2),
                        backgroundImage: fPhoto != null ? NetworkImage(fPhoto) : null,
                        child: fPhoto == null ? Text(fName[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)) : null,
                      ),
                      title: Text(fName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.send_rounded, color: AppTheme.accentCyan, size: 20),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await socialVm.recommendDrinkToFriend(targetFriendId: fUid, drink: drink);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Rekommendation skickad till $fName! 🤝')),
                          );
                        }
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
