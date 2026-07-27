import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../social_view_model.dart';
import '../../../core/theme.dart';
import 'user_profile_view.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socialVm = Provider.of<SocialViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vänner & Community'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Mina vänner'),
                  if (socialVm.friends.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${socialVm.friends.length}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Sök användare'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Förfrågningar'),
                  if (socialVm.pendingRequestsCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${socialVm.pendingRequestsCount}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Mina vänner tab
          _buildFriendsTab(socialVm),
          // 2. Sök användare tab
          _buildSearchTab(socialVm),
          // 3. Förfrågningar tab
          _buildRequestsTab(socialVm),
        ],
      ),
    );
  }

  // --- Tab 1: Mina vänner ---
  Widget _buildFriendsTab(SocialViewModel socialVm) {
    if (socialVm.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Du har inga vänner tillagda än.',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: Colors.black),
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Sök och lägg till vänner'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: socialVm.friends.length,
      itemBuilder: (context, index) {
        final friend = socialVm.friends[index];
        final photo = friend['photoURL'] as String?;
        final name = friend['displayName'] as String? ?? 'Vän';

        final friendUid = friend['uid'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileView(
                    userId: friendUid,
                    userName: name,
                    userPhoto: photo,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accentGold.withOpacity(0.2),
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Text('Vän sedan tidigare', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined, color: AppTheme.textSecondary),
                    tooltip: 'Ta bort vän',
                    onPressed: () => _confirmRemoveFriend(context, socialVm, friendUid, name),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Tab 2: Sök användare ---
  Widget _buildSearchTab(SocialViewModel socialVm) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Sök efter namn eller e-post...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.accentGold),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        socialVm.clearSearch();
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              if (val.trim().length >= 2) {
                socialVm.searchUsers(val);
              } else {
                socialVm.clearSearch();
              }
            },
          ),
        ),
        Expanded(
          child: socialVm.isSearching
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
              : socialVm.searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.trim().isEmpty
                            ? 'Börja skriva för att söka efter konton.'
                            : 'Inga konton hittades (eller så är kontot privat).',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: socialVm.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = socialVm.searchResults[index];
                        final targetUid = user['uid'] as String;
                        final name = user['displayName'] as String;
                        final photo = user['photoURL'] as String?;
                        final status = socialVm.getRelationshipStatus(targetUid);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileView(
                                    userId: targetUid,
                                    userName: name,
                                    userPhoto: photo,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.accentCyan.withOpacity(0.2),
                                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                                    child: photo == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        if ((user['email'] as String? ?? '').isNotEmpty)
                                          Text(
                                            user['email'],
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButtonForUser(context, socialVm, targetUid, status),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildActionButtonForUser(BuildContext context, SocialViewModel socialVm, String targetUid, String status) {
    if (status == 'friend') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.accentCyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: const Text('Vän', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    } else if (status == 'pending_sent') {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.borderLight)),
        child: const Text('Skickad', style: TextStyle(fontSize: 12)),
      );
    } else if (status == 'pending_received') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: Colors.black),
        onPressed: () {
          _tabController.animateTo(2);
        },
        child: const Text('Visa förfrågan', style: TextStyle(fontSize: 12)),
      );
    } else {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: Colors.black),
        onPressed: () async {
          await socialVm.sendFriendRequest(targetUid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vänförfrågan skickad!')),
            );
          }
        },
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text('Lägg till', style: TextStyle(fontSize: 12)),
      );
    }
  }

  // --- Tab 3: Förfrågningar ---
  Widget _buildRequestsTab(SocialViewModel socialVm) {
    if (socialVm.incomingRequests.isEmpty && socialVm.outgoingRequests.isEmpty) {
      return const Center(
        child: Text('Inga väntande vänförfrågningar.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (socialVm.incomingRequests.isNotEmpty) ...[
          const Text(
            'Inkomna förfrågningar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
          ),
          const SizedBox(height: 8),
          ...socialVm.incomingRequests.map((req) {
            final reqId = req['id'] as String;
            final fromUid = req['fromUserId'] as String;
            final name = req['fromName'] as String? ?? 'Användare';
            final photo = req['fromPhoto'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accentGold.withOpacity(0.2),
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('Vill lägga till dig som vän', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppTheme.accentCyan, size: 28),
                      tooltip: 'Godkänn',
                      onPressed: () async {
                        await socialVm.respondToFriendRequest(reqId, fromUid, true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Du och $name är nu vänner!')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppTheme.accentPink, size: 28),
                      tooltip: 'Neka',
                      onPressed: () async {
                        await socialVm.respondToFriendRequest(reqId, fromUid, false);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (socialVm.outgoingRequests.isNotEmpty) ...[
          const Text(
            'Skickade förfrågningar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ...socialVm.outgoingRequests.map((req) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: const Text('Vänförfrågan skickad', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Väntar på svar...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.hourglass_top, size: 18, color: AppTheme.accentGold),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _confirmRemoveFriend(BuildContext context, SocialViewModel socialVm, String friendId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ta bort $name?'),
        content: Text('Vill du ta bort $name från din vänlista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            onPressed: () async {
              Navigator.pop(ctx);
              await socialVm.removeFriend(friendId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name borttagen från dina vänner.')),
                );
              }
            },
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
  }
}
