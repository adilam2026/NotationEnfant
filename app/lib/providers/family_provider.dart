import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/default_rewards.dart';
import '../models/child.dart';
import '../models/reward.dart';
import '../models/star_event.dart';
import '../services/local_cache_service.dart';
import '../services/supabase_service.dart';
import '../utils/star_logic.dart';

/// Owns every family-scoped piece of state: children, rewards, recent
/// history. Keeps a local cache for offline viewing and a lightweight
/// realtime subscription on `children` so a star given on one phone shows
/// up on the other without the user doing anything.
class FamilyProvider extends ChangeNotifier {
  final _service = SupabaseService.instance;
  final _cache = LocalCacheService.instance;

  List<Child> children = [];
  List<Reward> rewards = [];
  List<StarEvent> recentEvents = [];

  bool isLoading = true;
  bool isOffline = false;
  String? errorMessage;

  String? _profileId;
  RealtimeChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> init(String profileId) async {
    _profileId = profileId;
    await _loadFromCache();
    await _checkConnectivity();
    _connectivitySub ??= Connectivity()
        .onConnectivityChanged
        .listen((_) => _checkConnectivity());
    await refresh();
    _subscribeRealtime(profileId);
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    isOffline = results.every((r) => r == ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    final cachedChildren = await _cache.loadChildren();
    final cachedRewards = await _cache.loadRewards();
    final cachedEvents = await _cache.loadEvents();
    if (cachedChildren.isNotEmpty) {
      children = cachedChildren.map(Child.fromMap).toList();
    }
    if (cachedRewards.isNotEmpty) {
      rewards = cachedRewards.map(Reward.fromMap).toList();
    }
    if (cachedEvents.isNotEmpty) {
      recentEvents = cachedEvents.map(StarEvent.fromMap).toList();
    }
    isLoading = children.isEmpty;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_profileId == null) return;
    try {
      final fetchedChildren = await _service.fetchChildren();
      var fetchedRewards = await _service.fetchRewards();
      if (fetchedRewards.isEmpty && fetchedChildren.isEmpty) {
        await _seedDefaultRewards();
        fetchedRewards = await _service.fetchRewards();
      }
      final ids = fetchedChildren.map((c) => c.id).toList();
      final fetchedEvents = await _service.fetchRecentEvents(ids);

      children = fetchedChildren;
      rewards = fetchedRewards;
      recentEvents = fetchedEvents;
      isOffline = false;
      errorMessage = null;

      await _cache.saveChildren(children.map((c) => c.toMap()).toList());
      await _cache.saveRewards(_rewardsToMaps(rewards));
      await _cache.saveEvents(_eventsToMaps(recentEvents));
    } catch (error) {
      errorMessage = 'Impossible de synchroniser pour le moment.';
      final results = await Connectivity().checkConnectivity();
      isOffline = results.every((r) => r == ConnectivityResult.none);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _seedDefaultRewards() async {
    for (final r in kDefaultRewards) {
      await _service.addReward(
        title: r.title,
        emoji: r.emoji,
        starsRequired: r.starsRequired,
      );
    }
  }

  void _subscribeRealtime(String profileId) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('public:children:profile_id=eq.$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'children',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: profileId,
          ),
          callback: (payload) => refreshChildrenOnly(),
        )
        .subscribe();
  }

  Future<void> refreshChildrenOnly() async {
    try {
      children = await _service.fetchChildren();
      await _cache.saveChildren(children.map((c) => c.toMap()).toList());
      notifyListeners();
    } catch (_) {
      // Silent — a manual refresh or the next realtime tick will retry.
    }
  }

  Child? childById(String id) {
    for (final c in children) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Children
  // ------------------------------------------------------------------

  Future<void> addChild({
    required String firstName,
    required String avatar,
    required String theme,
  }) async {
    final child = await _service.addChild(
        firstName: firstName, avatar: avatar, theme: theme);
    children = [...children, child];
    notifyListeners();
  }

  Future<void> updateChild(
    String childId, {
    String? firstName,
    String? avatar,
    String? theme,
  }) async {
    await _service.updateChild(childId,
        firstName: firstName, avatar: avatar, theme: theme);
    children = [
      for (final c in children)
        if (c.id == childId)
          c.copyWith(firstName: firstName, avatar: avatar, theme: theme)
        else
          c
    ];
    notifyListeners();
  }

  Future<void> deleteChild(String childId) async {
    await _service.deleteChild(childId);
    children = children.where((c) => c.id != childId).toList();
    recentEvents = recentEvents.where((e) => e.childId != childId).toList();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Rating
  // ------------------------------------------------------------------

  Future<StarEvent> rateChild({
    required String childId,
    required int value,
    required EventCategory category,
    required String reason,
  }) async {
    final (child, event) = await _service.addStarEvent(
      childId: childId,
      value: value,
      category: category,
      reason: reason,
    );
    children = [
      for (final c in children)
        if (c.id == childId) child else c
    ];
    recentEvents = [event, ...recentEvents];
    await _cache.saveChildren(children.map((c) => c.toMap()).toList());
    await _cache.saveEvents(_eventsToMaps(recentEvents));
    notifyListeners();
    return event;
  }

  Future<void> undoEvent(String eventId) async {
    await _service.deleteStarEvent(eventId);
    final removed = recentEvents.firstWhere((e) => e.id == eventId);
    recentEvents = recentEvents.where((e) => e.id != eventId).toList();
    await _refreshSingleChild(removed.childId);
    notifyListeners();
  }

  Future<void> deleteEvent(StarEvent event) async {
    await _service.deleteStarEvent(event.id);
    recentEvents = recentEvents.where((e) => e.id != event.id).toList();
    await _refreshSingleChild(event.childId);
    notifyListeners();
  }

  Future<void> updateEvent(StarEvent event, {int? value, String? reason}) async {
    await _service.updateStarEvent(event.id, value: value, reason: reason);
    await refresh();
  }

  Future<void> _refreshSingleChild(String childId) async {
    final fetched = await _service.fetchChildren();
    children = fetched;
    await _cache.saveChildren(children.map((c) => c.toMap()).toList());
  }

  // ------------------------------------------------------------------
  // Rewards
  // ------------------------------------------------------------------

  Future<void> addReward({
    required String title,
    required String emoji,
    required int starsRequired,
  }) async {
    await _service.addReward(title: title, emoji: emoji, starsRequired: starsRequired);
    rewards = await _service.fetchRewards();
    notifyListeners();
  }

  Future<void> updateReward(
    String rewardId, {
    String? title,
    String? emoji,
    int? starsRequired,
  }) async {
    await _service.updateReward(rewardId,
        title: title, emoji: emoji, starsRequired: starsRequired);
    rewards = await _service.fetchRewards();
    notifyListeners();
  }

  Future<void> deleteReward(String rewardId) async {
    await _service.deleteReward(rewardId);
    rewards = rewards.where((r) => r.id != rewardId).toList();
    notifyListeners();
  }

  Future<void> redeemReward({
    required String childId,
    required String rewardId,
  }) async {
    final child = await _service.redeemReward(childId: childId, rewardId: rewardId);
    children = [
      for (final c in children)
        if (c.id == childId) child else c
    ];
    final ids = children.map((c) => c.id).toList();
    recentEvents = await _service.fetchRecentEvents(ids);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  List<StarEvent> eventsForChild(String childId) {
    return recentEvents.where((e) => e.childId == childId).toList();
  }

  int starsGainedThisWeek(String childId) {
    return starsGainedSince(eventsForChild(childId), startOfWeek(DateTime.now()));
  }

  int starsGainedToday(String childId) {
    return starsGainedSince(eventsForChild(childId), startOfDay(DateTime.now()));
  }

  List<Map<String, dynamic>> _rewardsToMaps(List<Reward> list) => list
      .map((r) => {
            'id': r.id,
            'profile_id': r.profileId,
            'title': r.title,
            'emoji': r.emoji,
            'stars_required': r.starsRequired,
            'active': r.active,
            'created_at': r.createdAt.toIso8601String(),
          })
      .toList();

  List<Map<String, dynamic>> _eventsToMaps(List<StarEvent> list) => list
      .map((e) => {
            'id': e.id,
            'child_id': e.childId,
            'value': e.value,
            'category': categoryToString(e.category),
            'reason': e.reason,
            'created_at': e.createdAt.toIso8601String(),
          })
      .toList();

  void reset() {
    children = [];
    rewards = [];
    recentEvents = [];
    isLoading = true;
    _profileId = null;
    _channel?.unsubscribe();
    _channel = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
