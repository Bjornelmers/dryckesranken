import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../social_view_model.dart';
import '../../../core/theme.dart';
import 'user_profile_view.dart';
import '../../details/views/drink_detail_view.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final socialVm = Provider.of<SocialViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notiscenter'),
        actions: [
          if (socialVm.notifications.any((n) => !(n['read'] as bool? ?? false)))
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => socialVm.markAllNotificationsAsRead(),
                icon: const Icon(Icons.done_all, color: AppTheme.accentGold, size: 18),
                label: const Text(
                  'Markera alla som lästa',
                  style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: socialVm.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('Du har inga notiser just nu.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: socialVm.notifications.length,
              itemBuilder: (context, index) {
                final notif = socialVm.notifications[index];
                final notifId = notif['id'] as String;
                final type = notif['type'] as String? ?? 'info';
                final title = notif['title'] as String? ?? 'Notis';
                final message = notif['message'] as String? ?? '';
                final isRead = notif['read'] as bool? ?? false;
                final fromName = notif['fromUserName'] as String? ?? '';
                final photo = notif['fromUserPhoto'] as String?;

                final drinkName = notif['drinkName'] as String?;
                final drinkBrand = notif['drinkBrand'] as String?;
                final drinkType = notif['drinkType'] as String?;

                final fromUserId = notif['fromUserId'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isRead ? AppTheme.surfaceCardColor : AppTheme.surfaceCardColor.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isRead ? AppTheme.borderLight : AppTheme.accentGold.withOpacity(0.6),
                      width: isRead ? 1 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      socialVm.markNotificationAsRead(notifId);
                      final drinkId = notif['drinkId'] as String?;
                      if (drinkId != null && drinkId.isNotEmpty && fromUserId != null && fromUserId.isNotEmpty && type != 'friend_request') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DrinkDetailView(
                              drinkId: drinkId,
                              isReadOnly: true,
                              friendName: fromName,
                              friendUserId: fromUserId,
                            ),
                          ),
                        );
                      } else if (fromUserId != null && fromUserId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileView(
                              userId: fromUserId,
                              userName: fromName,
                              userPhoto: photo,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _getIconColor(type).withOpacity(0.2),
                              backgroundImage: photo != null ? NetworkImage(photo) : null,
                              child: photo == null
                                  ? Icon(_getNotificationIcon(type), size: 20, color: _getIconColor(type))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (!isRead)
                              IconButton(
                                icon: const Icon(Icons.mark_email_read, color: AppTheme.accentGold, size: 20),
                                tooltip: 'Markera som läst',
                                onPressed: () {
                                  socialVm.markNotificationAsRead(notifId);
                                },
                              ),
                          ],
                        ),
                        // Recommendation Action Button
                        if (type == 'recommendation' && drinkName != null) ...[
                          Builder(
                            builder: (context) {
                              final isAdded = socialVm.wishlist.any((item) =>
                                  (item['drinkName'] as String? ?? '').toLowerCase().trim() == drinkName.toLowerCase().trim() &&
                                  (item['brand'] as String? ?? '').toLowerCase().trim() == (drinkBrand ?? '').toLowerCase().trim());

                              if (isAdded) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    const Divider(color: AppTheme.borderLight),
                                    const SizedBox(height: 8),
                                    const Row(
                                      children: [
                                        Icon(Icons.bookmark_added, color: AppTheme.textSecondary, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tillagd på Borde-prova-listan 📝',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  const SizedBox(height: 12),
                                  const Divider(color: AppTheme.borderLight),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentGold,
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size.fromHeight(40),
                                    ),
                                    onPressed: () async {
                                      await socialVm.addToWishlist(
                                        drinkName: drinkName,
                                        brand: drinkBrand ?? '',
                                        type: drinkType ?? 'Övrigt',
                                        recommendedBy: fromName,
                                      );
                                      await socialVm.markNotificationAsRead(notifId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$drinkName tillagd på din Borde-prova-lista! 📝')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.bookmark_add, size: 18),
                                    label: const Text('+ Lägg till på min Borde-prova-lista', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        // Friend Request Action Buttons (Direct Accept / Decline)
                        if (type == 'friend_request') ...[
                          Builder(
                            builder: (context) {
                              final fromUserId = notif['fromUserId'] as String? ?? '';
                              final isPending = socialVm.incomingRequests.any((r) => r['fromUserId'] == fromUserId);
                              final isFriend = socialVm.friends.any((f) => f['uid'] == fromUserId);

                              if (isPending) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    const Divider(color: AppTheme.borderLight),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.accentGold,
                                              foregroundColor: Colors.black,
                                            ),
                                            onPressed: () async {
                                              final match = socialVm.incomingRequests.firstWhere(
                                                (r) => r['fromUserId'] == fromUserId,
                                                orElse: () => {'id': '${fromUserId}_current'},
                                              );
                                              await socialVm.respondToFriendRequest(match['id'] as String, fromUserId, true);
                                              await socialVm.markNotificationAsRead(notifId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Du och $fromName är nu vänner!')),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.check_circle, size: 18),
                                            label: const Text('Godkänn', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: AppTheme.accentPink),
                                              foregroundColor: AppTheme.accentPink,
                                            ),
                                            onPressed: () async {
                                              final match = socialVm.incomingRequests.firstWhere(
                                                (r) => r['fromUserId'] == fromUserId,
                                                orElse: () => {'id': '${fromUserId}_current'},
                                              );
                                              await socialVm.respondToFriendRequest(match['id'] as String, fromUserId, false);
                                              await socialVm.markNotificationAsRead(notifId);
                                            },
                                            icon: const Icon(Icons.cancel, size: 18),
                                            label: const Text('Neka', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    const Divider(color: AppTheme.borderLight),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          isFriend ? Icons.people_outline : Icons.done,
                                          color: AppTheme.textSecondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isFriend ? 'Vänförfrågan godkänd 👥' : 'Hanterad',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.people;
      case 'friend_ranked':
        return Icons.star;
      case 'recommendation':
        return Icons.thumb_up;
      case 'drinking_companion':
        return Icons.sports_bar;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'friend_request':
        return AppTheme.accentGold;
      case 'friend_accepted':
        return AppTheme.accentCyan;
      case 'friend_ranked':
        return AppTheme.accentGold;
      case 'recommendation':
        return AppTheme.accentPink;
      case 'drinking_companion':
        return AppTheme.accentGold;
      default:
        return AppTheme.accentCyan;
    }
  }
}
