import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/models/drink_model.dart';
import '../../../data/services/social_service.dart';

class SocialViewModel extends ChangeNotifier {
  final SocialService _socialService = SocialService();

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhoto;

  String _privacyMode = 'friendsOnly';
  bool _isLoading = false;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _wishlist = [];

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  StreamSubscription? _friendsSub;
  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _wishlistSub;

  // Getters
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String get privacyMode => _privacyMode;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get outgoingRequests => _outgoingRequests;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get wishlist => _wishlist;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  int get unreadNotificationsCount => _notifications.where((n) => n['read'] == false).length;
  int get pendingRequestsCount => _incomingRequests.length;

  // Initialize listeners for a logged-in user
  void updateUserContext({
    required String? userId,
    required String? userName,
    required String? userPhoto,
    required String? userEmail,
  }) {
    if (userId == _currentUserId) return;

    _currentUserId = userId;
    _currentUserName = userName ?? 'Användare';
    _currentUserPhoto = userPhoto;

    _cancelSubscriptions();

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      // Sync user profile data to Firestore
      _socialService.updateUserProfile(
        userId: _currentUserId!,
        displayName: _currentUserName!,
        photoURL: _currentUserPhoto,
        email: userEmail ?? '',
      );

      _loadPrivacyMode();
      _startListeners();
    } else {
      _resetState();
    }
  }

  Future<String> getUserPrivacyMode(String userId) async {
    return await _socialService.getUserPrivacyMode(userId);
  }

  Future<void> _loadPrivacyMode() async {
    if (_currentUserId == null) return;
    _privacyMode = await _socialService.getUserPrivacyMode(_currentUserId!);
    notifyListeners();
  }

  Future<void> updatePrivacyMode(String newMode) async {
    if (_currentUserId == null) return;
    _privacyMode = newMode;
    notifyListeners();

    await _socialService.updateUserProfile(
      userId: _currentUserId!,
      displayName: _currentUserName!,
      photoURL: _currentUserPhoto,
      email: '',
      privacyMode: newMode,
    );
  }

  void _startListeners() {
    if (_currentUserId == null) return;

    _friendsSub = _socialService.listenFriends(_currentUserId!).listen((data) {
      _friends = data;
      notifyListeners();
    });

    _incomingSub = _socialService.listenIncomingFriendRequests(_currentUserId!).listen((data) {
      _incomingRequests = data;
      notifyListeners();
    });

    _outgoingSub = _socialService.listenOutgoingFriendRequests(_currentUserId!).listen((data) {
      _outgoingRequests = data;
      notifyListeners();
    });

    _notificationsSub = _socialService.listenNotifications(_currentUserId!).listen((data) {
      _notifications = data;
      notifyListeners();
    });

    _wishlistSub = _socialService.listenWishlist(_currentUserId!).listen((data) {
      _wishlist = data;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _friendsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _notificationsSub?.cancel();
    _wishlistSub?.cancel();
  }

  void _resetState() {
    _friends = [];
    _incomingRequests = [];
    _outgoingRequests = [];
    _notifications = [];
    _wishlist = [];
    _searchResults = [];
    notifyListeners();
  }

  // --- Search ---

  Future<void> searchUsers(String query) async {
    if (_currentUserId == null || query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchResults = await _socialService.searchUsers(
      query: query,
      currentUserId: _currentUserId!,
    );

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // --- Friend Requests ---

  Future<void> sendFriendRequest(String targetUserId) async {
    if (_currentUserId == null) return;
    await _socialService.sendFriendRequest(
      fromUserId: _currentUserId!,
      fromName: _currentUserName!,
      fromPhoto: _currentUserPhoto,
      toUserId: targetUserId,
    );
  }

  Future<void> respondToFriendRequest(String requestId, String fromUserId, bool accept) async {
    if (_currentUserId == null) return;
    await _socialService.respondToFriendRequest(
      requestId: requestId,
      fromUserId: fromUserId,
      toUserId: _currentUserId!,
      currentUserName: _currentUserName!,
      currentUserPhoto: _currentUserPhoto,
      accept: accept,
    );
  }

  Future<void> removeFriend(String friendId) async {
    if (_currentUserId == null) return;
    await _socialService.removeFriend(_currentUserId!, friendId);
  }

  // Check relationship status with a user
  String getRelationshipStatus(String userId) {
    if (_friends.any((f) => f['uid'] == userId)) return 'friend';
    if (_outgoingRequests.any((r) => r['toUserId'] == userId)) return 'pending_sent';
    if (_incomingRequests.any((r) => r['fromUserId'] == userId)) return 'pending_received';
    return 'none';
  }

  // --- Notifications ---

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_currentUserId == null) return;
    await _socialService.markNotificationAsRead(_currentUserId!, notificationId);
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_currentUserId == null) return;
    await _socialService.markAllNotificationsAsRead(_currentUserId!);
  }

  Future<void> notifyFriendsOfRating(DrinkModel drink) async {
    if (_currentUserId == null) return;
    await _socialService.notifyFriendsOfDrinkRating(
      currentUserId: _currentUserId!,
      currentUserName: _currentUserName!,
      currentUserPhoto: _currentUserPhoto,
      drink: drink,
    );
  }

  // --- Recommendations & Wishlist ---

  Future<void> recommendDrinkToFriend({
    required String targetFriendId,
    required DrinkModel drink,
  }) async {
    if (_currentUserId == null) return;
    await _socialService.recommendDrinkToFriend(
      currentUserId: _currentUserId!,
      currentUserName: _currentUserName!,
      currentUserPhoto: _currentUserPhoto,
      targetFriendId: targetFriendId,
      drink: drink,
    );
  }

  Future<void> notifyCompanionOfDrink({
    required String targetCompanionUid,
    required DrinkModel drink,
  }) async {
    if (_currentUserId == null) return;
    await _socialService.sendNotification(
      targetUserId: targetCompanionUid,
      type: 'drinking_companion',
      title: 'Drack med dig! 🍻',
      message: '$_currentUserName drack precis "${drink.name}" med dig!',
      fromUserId: _currentUserId!,
      fromUserName: _currentUserName!,
      fromUserPhoto: _currentUserPhoto,
      drinkId: drink.id,
      drinkName: drink.name,
      drinkBrand: drink.brand,
      drinkType: drink.type,
    );
  }

  Future<void> addToWishlist({
    required String drinkName,
    required String brand,
    required String type,
    String? recommendedBy,
  }) async {
    if (_currentUserId == null) return;
    await _socialService.addToWishlist(
      userId: _currentUserId!,
      drinkName: drinkName,
      brand: brand,
      type: type,
      recommendedBy: recommendedBy,
    );
  }

  Future<void> removeFromWishlist(String wishId) async {
    if (_currentUserId == null) return;
    await _socialService.removeFromWishlist(_currentUserId!, wishId);
  }

  // --- Friend Drink Comparisons ---

  Future<List<Map<String, dynamic>>> getFriendsDrinkRatings(String drinkName) async {
    if (_currentUserId == null) return [];
    return await _socialService.getFriendsDrinkRatings(
      currentUserId: _currentUserId!,
      drinkName: drinkName,
    );
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
