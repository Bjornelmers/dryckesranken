import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/drink_model.dart';
import '../../../../data/services/storage_service.dart';
import '../social_view_model.dart';
import '../../../core/theme.dart';
import '../../details/views/drink_detail_view.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhoto;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhoto,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  List<DrinkModel> _userDrinks = [];
  String _privacyMode = 'friendsOnly';
  bool _isFriend = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndDrinks();
  }

  Future<void> _loadUserProfileAndDrinks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final socialVm = Provider.of<SocialViewModel>(context, listen: false);
    _isFriend = socialVm.friends.any((f) => f['uid'] == widget.userId);

    try {
      final privacy = await socialVm.getUserPrivacyMode(widget.userId);
      _privacyMode = privacy;

      // Check permission to view rankings
      final canView = privacy == 'public' || _isFriend;

      if (canView) {
        final drinks = await _storageService.getDrinksFromCloud(widget.userId);
        _userDrinks = drinks;
      }
    } catch (e) {
      _errorMessage = 'Kunde inte hämta användarens drycker: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialVm = Provider.of<SocialViewModel>(context);
    final status = socialVm.getRelationshipStatus(widget.userId);

    final totalDrinks = _userDrinks.length;
    final avgRating = _userDrinks.isNotEmpty
        ? (_userDrinks.map((d) => d.rating).reduce((a, b) => a + b) / totalDrinks)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : CustomScrollView(
              slivers: [
                // User Profile Header Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppTheme.accentGold.withOpacity(0.2),
                              backgroundImage: widget.userPhoto != null ? NetworkImage(widget.userPhoto!) : null,
                              child: widget.userPhoto == null
                                  ? Text(
                                      widget.userName[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 28, color: AppTheme.accentGold, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.userName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            _buildPrivacyBadge(),
                            const SizedBox(height: 16),
                            if (!_isFriend) ...[
                              _buildFriendActionButton(context, socialVm, status),
                              const SizedBox(height: 16),
                            ],
                            // Quick stats
                            if (_privacyMode == 'public' || _isFriend) ...[
                              const Divider(color: AppTheme.borderLight),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Rankade', '$totalDrinks st', Icons.sports_bar),
                                  _buildStatItem('Snittbetyg', avgRating > 0 ? avgRating.toStringAsFixed(1) : '-', Icons.star),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Drink Grid or Privacy Lock Message
                if (_privacyMode == 'private')
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 64, color: AppTheme.textSecondary),
                          SizedBox(height: 16),
                          Text('Det här kontot är privat.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                else if (_privacyMode == 'friendsOnly' && !_isFriend)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            const Text(
                              'Endast synlig för vänner',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Skicka en vänförfrågan för att få tillgång till användarens dryckesrankningar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            _buildFriendActionButton(context, socialVm, status),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_userDrinks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('Användaren har inte lagt till några rankningar än.', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final drink = _userDrinks[index];
                          return _buildDrinkCard(context, drink);
                        },
                        childCount: _userDrinks.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPrivacyBadge() {
    String label = 'Endast vänner';
    IconData icon = Icons.people;
    Color color = AppTheme.accentGold;

    if (_privacyMode == 'private') {
      label = 'Privat konto';
      icon = Icons.lock;
      color = AppTheme.accentPink;
    } else if (_privacyMode == 'public') {
      label = 'Offentligt konto';
      icon = Icons.public;
      color = AppTheme.accentCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildFriendActionButton(BuildContext context, SocialViewModel socialVm, String status) {
    if (status == 'pending_sent') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top, size: 16),
        label: const Text('Vänförfrågan skickad'),
      );
    } else if (status == 'none') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: Colors.black),
        onPressed: () async {
          await socialVm.sendFriendRequest(widget.userId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vänförfrågan skickad!')),
            );
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Skicka vänförfrågan'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDrinkCard(BuildContext context, DrinkModel drink) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DrinkDetailView(
                drinkId: drink.id,
                drink: drink,
                isReadOnly: true,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  drink.imageBytes != null
                      ? Image.memory(drink.imageBytes!, fit: BoxFit.cover)
                      : Container(color: AppTheme.surfaceColor, child: const Icon(Icons.sports_bar, size: 40, color: AppTheme.textSecondary)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                      child: Text('${drink.rating} ⭐', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drink.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(drink.brand, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
