import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drink_model.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Profile & Privacy ---

  // Update user profile metadata & privacy mode ('private', 'friendsOnly', 'public')
  Future<void> updateUserProfile({
    required String userId,
    required String displayName,
    required String? photoURL,
    required String email,
    String? privacyMode,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'displayName': displayName,
        'photoURL': photoURL,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (privacyMode != null) {
        data['privacyMode'] = privacyMode;
      }
      await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Fetch current user privacy mode
  Future<String> getUserPrivacyMode(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['privacyMode'] as String? ?? 'friendsOnly';
      }
    } catch (e) {
      print('Error fetching privacy mode: $e');
    }
    return 'friendsOnly';
  }

  // Search users by display name or email (excludes 'private' profiles and current user)
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    if (query.trim().isEmpty) return [];
    final cleanQuery = query.trim().toLowerCase();

    try {
      final snapshot = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        final data = doc.data();
        final privacy = data['privacyMode'] as String? ?? 'friendsOnly';
        if (privacy == 'private') continue;

        final name = (data['displayName'] as String? ?? '').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();

        if (name.contains(cleanQuery) || email.contains(cleanQuery)) {
          results.add({
            'uid': doc.id,
            'displayName': data['displayName'] ?? 'Användare',
            'photoURL': data['photoURL'],
            'email': data['email'] ?? '',
            'privacyMode': privacy,
          });
        }
      }
      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // --- Friends & Friend Requests ---

  // Stream active friends list for a user
  Stream<List<Map<String, dynamic>>> listenFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
    });
  }

  // Send a friend request
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromName,
    required String? fromPhoto,
    required String toUserId,
  }) async {
    try {
      // Create request doc in global collection
      final reqRef = _firestore.collection('friendRequests').doc('${fromUserId}_$toUserId');
      await reqRef.set({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromName': fromName,
        'fromPhoto': fromPhoto,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send notification to recipient
      await _createNotification(
        toUserId: toUserId,
        type: 'friend_request',
        title: 'Ny vänförfrågan',
        message: '$fromName vill lägga till dig som vän.',
        fromUserId: fromUserId,
        fromUserName: fromName,
        fromUserPhoto: fromPhoto,
      );
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  // Listen incoming pending friend requests for current user
  Stream<List<Map<String, dynamic>>> listenIncomingFriendRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  // Listen outgoing pending friend requests sent by current user
  Stream<List<Map<String, dynamic>>> listenOutgoingFriendRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  // Accept or decline friend request
  Future<void> respondToFriendRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required bool accept,
  }) async {
    try {
      final reqRef = _firestore.collection('friendRequests').doc(requestId);

      if (accept) {
        await reqRef.update({'status': 'accepted'});

        // Fetch sender & receiver user details
        final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
        final fromData = fromUserDoc.data() ?? {};

        // Add to both users' friends subcollection
        await _firestore
            .collection('users')
            .doc(toUserId)
            .collection('friends')
            .doc(fromUserId)
            .set({
          'displayName': fromData['displayName'] ?? 'Vän',
          'photoURL': fromData['photoURL'],
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        await _firestore
            .collection('users')
            .doc(fromUserId)
            .collection('friends')
            .doc(toUserId)
            .set({
          'displayName': currentUserName,
          'photoURL': currentUserPhoto,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // Send confirmation notification back to sender
        await _createNotification(
          toUserId: fromUserId,
          type: 'friend_accepted',
          title: 'Vänförfrågan godkänd',
          message: '$currentUserName godkände din vänförfrågan!',
          fromUserId: toUserId,
          fromUserName: currentUserName,
          fromUserPhoto: currentUserPhoto,
        );
      } else {
        await reqRef.delete();
      }
    } catch (e) {
      print('Error responding to friend request: $e');
      rethrow;
    }
  }

  // Remove a friend
  Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .delete();
      await _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(currentUserId)
          .delete();
    } catch (e) {
      print('Error removing friend: $e');
    }
  }

  // --- Notifications ---

  // Stream notifications for a user
  Stream<List<Map<String, dynamic>>> listenNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String type,
    required String title,
    required String message,
    required String fromUserId,
    required String fromUserName,
    required String? fromUserPhoto,
    String? drinkId,
    String? drinkName,
    String? drinkBrand,
    String? drinkType,
  }) async {
    await _createNotification(
      toUserId: targetUserId,
      type: type,
      title: title,
      message: message,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhoto: fromUserPhoto,
      drinkId: drinkId,
      drinkName: drinkName,
      drinkBrand: drinkBrand,
      drinkType: drinkType,
    );
  }

  // Internal helper to push a notification document
  Future<void> _createNotification({
    required String toUserId,
    required String type,
    required String title,
    required String message,
    required String fromUserId,
    required String fromUserName,
    required String? fromUserPhoto,
    String? drinkId,
    String? drinkName,
    String? drinkBrand,
    String? drinkType,
  }) async {
    await _firestore
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .add({
      'type': type,
      'title': title,
      'message': message,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhoto': fromUserPhoto,
      'drinkId': drinkId,
      'drinkName': drinkName,
      'drinkBrand': drinkBrand,
      'drinkType': drinkType,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Notify friends when user rates a drink
  Future<void> notifyFriendsOfDrinkRating({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required DrinkModel drink,
  }) async {
    try {
      final friendsSnap = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .get();

      for (var doc in friendsSnap.docs) {
        final friendId = doc.id;
        await _createNotification(
          toUserId: friendId,
          type: 'friend_ranked',
          title: 'Ny rankning från $currentUserName',
          message: '$currentUserName gav ${drink.name} betyget ${drink.rating}/10 ⭐',
          fromUserId: currentUserId,
          fromUserName: currentUserName,
          fromUserPhoto: currentUserPhoto,
          drinkId: drink.id,
          drinkName: drink.name,
          drinkBrand: drink.brand,
          drinkType: drink.type,
        );
      }
    } catch (e) {
      print('Error notifying friends of rating: $e');
    }
  }

  // --- Recommendations ---

  // Recommend a drink to a specific friend
  Future<void> recommendDrinkToFriend({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required String targetFriendId,
    required DrinkModel drink,
  }) async {
    try {
      await _createNotification(
        toUserId: targetFriendId,
        type: 'recommendation',
        title: 'Dryckesrekommendation',
        message: '$currentUserName rekommenderar dig att prova ${drink.name} (${drink.brand})!',
        fromUserId: currentUserId,
        fromUserName: currentUserName,
        fromUserPhoto: currentUserPhoto,
        drinkId: drink.id,
        drinkName: drink.name,
        drinkBrand: drink.brand,
        drinkType: drink.type,
      );
    } catch (e) {
      print('Error recommending drink: $e');
      rethrow;
    }
  }

  // --- Wishlist ("Borde-prova-lista") ---

  // Stream wishlist for a user
  Stream<List<Map<String, dynamic>>> listenWishlist(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  // Add item to wishlist
  Future<void> addToWishlist({
    required String userId,
    required String drinkName,
    required String brand,
    required String type,
    String? recommendedBy,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .add({
        'drinkName': drinkName,
        'brand': brand,
        'type': type,
        'recommendedBy': recommendedBy,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to wishlist: $e');
      rethrow;
    }
  }

  // Remove item from wishlist
  Future<void> removeFromWishlist(String userId, String wishId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(wishId)
          .delete();
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  // --- Drink Comparisons Across Friends ---

  // Find ratings by friends for a specific drink name
  Future<List<Map<String, dynamic>>> getFriendsDrinkRatings({
    required String currentUserId,
    required String drinkName,
  }) async {
    if (drinkName.trim().isEmpty) return [];
    final cleanName = drinkName.trim().toLowerCase();

    try {
      // 1. Fetch friend IDs
      final friendsSnap = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .get();

      final List<Map<String, dynamic>> friendRatings = [];

      for (var friendDoc in friendsSnap.docs) {
        final friendId = friendDoc.id;
        final friendName = friendDoc.data()['displayName'] as String? ?? 'Vän';
        final friendPhoto = friendDoc.data()['photoURL'] as String?;

        // 2. Fetch drinks subcollection of friend
        final drinksSnap = await _firestore
            .collection('users')
            .doc(friendId)
            .collection('drinks')
            .get();

        for (var drinkDoc in drinksSnap.docs) {
          final data = drinkDoc.data();
          final dName = (data['name'] as String? ?? '').toLowerCase();
          if (dName == cleanName) {
            friendRatings.add({
              'friendId': friendId,
              'friendName': friendName,
              'friendPhoto': friendPhoto,
              'rating': (data['rating'] as num?)?.toDouble() ?? 5.0,
              'comment': data['comment'] as String? ?? '',
              'createdAt': data['createdAt'],
            });
          }
        }
      }
      return friendRatings;
    } catch (e) {
      print('Error fetching friends drink ratings: $e');
      return [];
    }
  }
}
