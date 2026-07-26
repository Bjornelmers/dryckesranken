import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_view_model.dart';
import '../../../core/theme.dart';

class DrinkDetailView extends StatelessWidget {
  final String drinkId;

  const DrinkDetailView({super.key, required this.drinkId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, viewModel, _) {
        final drinkIndex = viewModel.allDrinks.indexWhere((d) => d.id == drinkId);
        if (drinkIndex == -1) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            ),
          );
        }
        final drink = viewModel.allDrinks[drinkIndex];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Sliver App Bar with Image
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(context, viewModel, drink.name),
                  ),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentCyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      drink.type,
                                      style: const TextStyle(
                                        color: AppTheme.accentCyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
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
                            const SizedBox(height: 40),
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
}
