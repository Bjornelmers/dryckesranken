import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app_view_model.dart';
import '../../../core/theme.dart';
import '../../settings/views/settings_view.dart';
import '../../details/views/drink_detail_view.dart';
import '../../ranking/views/add_drink_view.dart';
import '../../ranking/views/batch_add_drink_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppViewModel>(
        builder: (context, viewModel, _) {
          return CustomScrollView(
            slivers: [
              // Beautiful Custom App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: 100.0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sports_bar, color: AppTheme.accentGold, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'DryckesRanken',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (viewModel.isLoggedIn) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(
                                viewModel.currentUser!.photoURL ??
                                    'https://www.gravatar.com/avatar/?d=mp',
                              ),
                            ),
                          ] else ...[
                            TextButton.icon(
                              onPressed: () => _handleLogin(context, viewModel),
                              icon: const Icon(Icons.login, size: 14, color: AppTheme.accentGold),
                              label: const Text(
                                'Logga in',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: const BorderSide(color: AppTheme.accentGold, width: 1),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsView()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  titlePadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                ),
              ),

              // Statistics Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: _buildStatsSection(context, viewModel),
                ),
              ),

              // Search and Filter section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        onChanged: viewModel.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Sök på namn, märke, betyg...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                          suffixIcon: viewModel.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    viewModel.setSearchQuery('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter chips row
                      _buildFilterChips(context, viewModel),
                    ],
                  ),
                ),
              ),

              // Drink Grid List
              if (viewModel.drinks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, viewModel),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getResponsiveCrossAxisCount(context),
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final drink = viewModel.drinks[index];
                        return _buildDrinkCard(context, drink);
                      },
                      childCount: viewModel.drinks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'Lägg till',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Determine grid columns based on screen width
  int _getResponsiveCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 550) return 2;
    return 1;
  }

  Widget _buildStatsSection(BuildContext context, AppViewModel viewModel) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    final stats = [
      _StatItem(
        icon: Icons.bookmark_added,
        title: 'Totalt',
        value: '${viewModel.totalDrinks}',
        subtitle: 'drycker rankade',
        color: AppTheme.accentCyan,
      ),
      _StatItem(
        icon: Icons.star,
        title: 'Snittbetyg',
        value: viewModel.totalDrinks > 0 ? '${viewModel.averageRating}' : '-',
        subtitle: 'betyg 1-10',
        color: AppTheme.accentGold,
      ),
      _StatItem(
        icon: Icons.favorite,
        title: 'Favoritkategori',
        value: viewModel.favoriteType,
        subtitle: 'högst snitt',
        color: AppTheme.ratingGreen,
      ),
    ];

    if (isMobile) {
      return Column(
        children: stats
            .map((stat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildStatCard(context, stat, double.infinity),
                ))
            .toList(),
      );
    }

    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: _buildStatCard(context, stat, null),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat, double? width) {
    return Card(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: stat.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(stat.icon, color: stat.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    stat.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AppViewModel viewModel) {
    final categories = viewModel.availableCategories;
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = viewModel.selectedTypeFilter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  viewModel.setSelectedTypeFilter(category);
                }
              },
              selectedColor: AppTheme.accentGold.withOpacity(0.2),
              checkmarkColor: AppTheme.accentGold,
              backgroundColor: AppTheme.surfaceCardColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.accentGold : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.accentGold : AppTheme.borderLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppViewModel viewModel) {
    final hasFilter = viewModel.searchQuery.isNotEmpty || viewModel.selectedTypeFilter != 'Alla';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_drinks_outlined,
              size: 80,
              color: AppTheme.borderLight,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Inga matchande drycker hittades' : 'Här var det tomt!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Prova att rensa ditt filter eller söka efter något annat.'
                  : 'Du har inte rankat några drycker än. Klicka på knappen nedan för att lägga till din första recension!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  viewModel.setSearchQuery('');
                  viewModel.setSelectedTypeFilter('Alla');
                },
                child: const Text('Rensa alla filter'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkCard(BuildContext context, dynamic drink) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DrinkDetailView(drinkId: drink.id),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drink Image thumbnail
                Expanded(
                  child: drink.imageBytes != null
                      ? Image.memory(
                          drink.imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(
                            Icons.local_bar,
                            size: 50,
                            color: AppTheme.borderLight,
                          ),
                        ),
                ),

                // Drink Text info
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              drink.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        drink.brand,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: drink.type.split(',').map((tag) {
                                final t = tag.trim();
                                if (t.isEmpty) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentCyan,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Text(
                            drink.abv > 0 ? '${drink.abv}% ABV' : 'Alkoholfri',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Rating Badge (Positioned at top right of the card)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.getRatingColor(drink.rating),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppTheme.glowShadow(AppTheme.getRatingColor(drink.rating)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${drink.rating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lägg till dryck',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_photo_alternate, color: AppTheme.accentGold),
                ),
                title: const Text('Ranka en dryck', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                subtitle: const Text('Ladda upp en bild på en enskild burk eller flaska', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddDrinkView()),
                  );
                },
              ),
              const Divider(color: AppTheme.borderLight, height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.collections, color: AppTheme.accentCyan),
                ),
                title: const Text('Importera album', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                subtitle: const Text('Välj och skanna flera dryckesbilder samtidigt', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndNavigateBatch(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndNavigateBatch(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BatchAddDrinkView(images: images),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte läsa bilder: $e')),
        );
      }
    }
  }

  Future<void> _handleLogin(BuildContext context, AppViewModel viewModel) async {
    try {
      await viewModel.signInWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Välkommen, ${viewModel.currentUser!.displayName ?? "inloggad"}!'),
            backgroundColor: AppTheme.ratingGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunde inte logga in: $e'),
            backgroundColor: AppTheme.ratingRed,
          ),
        );
      }
    }
  }
}

// Data holder class for stats items
class _StatItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}
