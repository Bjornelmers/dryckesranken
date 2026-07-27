import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app_view_model.dart';
import '../../../core/theme.dart';
import '../../settings/views/settings_view.dart';
import '../../details/views/drink_detail_view.dart';
import '../../ranking/views/add_drink_view.dart';
import '../../social/social_view_model.dart';
import '../../social/views/friends_view.dart';
import '../../social/views/notifications_view.dart';
import '../../social/views/wishlist_view.dart';

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
                titleSpacing: 12,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 420;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App Logo & Title
                        Row(
                          children: [
                            const Icon(Icons.sports_bar, color: AppTheme.accentGold, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              'DryckesRanken',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                fontSize: isMobile ? 14 : 18,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        // Right Actions (Avatar, Wishlist, Friends, Notifications, Settings)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer<SocialViewModel>(
                              builder: (context, socialVm, _) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Wishlist Icon
                                    IconButton(
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.bookmark_outline, color: AppTheme.textPrimary, size: 18),
                                      tooltip: 'Borde-prova-lista',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const WishlistView()),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    // Friends Icon
                                    Stack(
                                      children: [
                                        IconButton(
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.people_outline, color: AppTheme.textPrimary, size: 18),
                                          tooltip: 'Vänner',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const FriendsView()),
                                            );
                                          },
                                        ),
                                        if (socialVm.pendingRequestsCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: AppTheme.accentGold,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${socialVm.pendingRequestsCount}',
                                                style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    // Notification Bell Icon
                                    Stack(
                                      children: [
                                        IconButton(
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.notifications_none, color: AppTheme.textPrimary, size: 18),
                                          tooltip: 'Notiser',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const NotificationsView()),
                                            );
                                          },
                                        ),
                                        if (socialVm.unreadNotificationsCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: AppTheme.accentPink,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${socialVm.unreadNotificationsCount}',
                                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            if (viewModel.isLoggedIn)
                              Tooltip(
                                message: 'Inställningar',
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsView()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundImage: NetworkImage(
                                      viewModel.currentUser!.photoURL ??
                                          'https://www.gravatar.com/avatar/?d=mp',
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              TextButton.icon(
                                onPressed: () => _handleLogin(context, viewModel),
                                icon: const Icon(Icons.login, size: 12, color: AppTheme.accentGold),
                                label: const Text(
                                  'Logga in',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary, size: 18),
                                tooltip: 'Inställningar',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SettingsView()),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
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
                      Builder(
                        builder: (context) {
                          final countries = viewModel.availableCountries;
                          if (countries.length <= 1) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              _buildCountryFilterChips(context, viewModel),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Statistics Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: _buildStatsSection(context, viewModel),
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
      _StatItem(
        icon: Icons.flag,
        title: 'Favoritland',
        value: viewModel.favoriteCountry,
        subtitle: 'högst snitt',
        color: AppTheme.accentCyan,
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
    final hasDateFilter = viewModel.selectedDateRangeFilter != null;
    
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          // Date Filter chip
          ChoiceChip(
            avatar: Icon(
              Icons.calendar_today,
              color: hasDateFilter ? AppTheme.accentGold : AppTheme.textSecondary,
              size: 14,
            ),
            label: Text(
              !hasDateFilter
                  ? 'Välj datum'
                  : '${viewModel.selectedDateRangeFilter!.start.day}/${viewModel.selectedDateRangeFilter!.start.month} - ${viewModel.selectedDateRangeFilter!.end.day}/${viewModel.selectedDateRangeFilter!.end.month}',
            ),
            selected: hasDateFilter,
            onSelected: (selected) async {
              if (hasDateFilter) {
                viewModel.setSelectedDateRangeFilter(null);
              } else {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.accentGold,
                          onPrimary: Colors.black,
                          surface: AppTheme.surfaceCardColor,
                          onSurface: AppTheme.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  viewModel.setSelectedDateRangeFilter(picked);
                }
              }
            },
            selectedColor: AppTheme.accentGold.withOpacity(0.2),
            checkmarkColor: AppTheme.accentGold,
            backgroundColor: AppTheme.surfaceCardColor,
            labelStyle: TextStyle(
              color: hasDateFilter ? AppTheme.accentGold : AppTheme.textSecondary,
              fontWeight: hasDateFilter ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: hasDateFilter ? AppTheme.accentGold : AppTheme.borderLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: AppTheme.borderLight,
          ),
          const SizedBox(width: 8),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppViewModel viewModel) {
    final hasFilter = viewModel.searchQuery.isNotEmpty ||
        viewModel.selectedTypeFilter != 'Alla' ||
        viewModel.selectedCountryFilter != 'Alla länder' ||
        viewModel.selectedDateRangeFilter != null;

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
                  ? 'Prova av att rensa ditt filter eller söka efter något annat.'
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
                  viewModel.setSelectedCountryFilter('Alla länder');
                  viewModel.setSelectedDateRangeFilter(null);
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
                              children: [
                                if (drink.mainCategory != null && drink.mainCategory!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      drink.mainCategory!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentPink,
                                      ),
                                    ),
                                  ),
                                ...drink.type.split(',').map((tag) {
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
                              ],
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
                  child: const Icon(Icons.auto_awesome, color: AppTheme.accentGold),
                ),
                title: const Text('Skanna med AI', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                subtitle: const Text('Kamera eller galleri – Gemini läser av etiketten automatiskt', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_camera, color: AppTheme.accentGold),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDrinkView(
                              initialSource: ImageSource.camera,
                              skipScan: false,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: AppTheme.accentGold),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDrinkView(
                              initialSource: ImageSource.gallery,
                              skipScan: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderLight, height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit, color: AppTheme.accentPink),
                ),
                title: const Text('Fyll i manuellt', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                subtitle: const Text('Välj bild först men skippa AI-skanningen', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_camera, color: AppTheme.accentPink),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDrinkView(
                              initialSource: ImageSource.camera,
                              skipScan: true,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: AppTheme.accentPink),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDrinkView(
                              initialSource: ImageSource.gallery,
                              skipScan: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountryFilterChips(BuildContext context, AppViewModel viewModel) {
    final countries = viewModel.availableCountries;
    if (countries.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final country = countries[index];
          final isSelected = viewModel.selectedCountryFilter == country;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: country == 'Alla länder'
                  ? null
                  : const Icon(Icons.location_on_outlined, color: AppTheme.accentGold, size: 12),
              label: Text(country),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  viewModel.setSelectedCountryFilter(country);
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
