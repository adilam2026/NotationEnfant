import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal local cache so the app stays browsable (read-only) when the
/// connection drops. Supabase remains the single source of truth — this is
/// just a snapshot of the last successful fetch.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  static const _childrenKey = 'cache_children_v1';
  static const _rewardsKey = 'cache_rewards_v1';
  static const _eventsKey = 'cache_events_v1';

  Future<void> saveChildren(List<Map<String, dynamic>> children) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childrenKey, jsonEncode(children));
  }

  Future<List<Map<String, dynamic>>> loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_childrenKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveRewards(List<Map<String, dynamic>> rewards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rewardsKey, jsonEncode(rewards));
  }

  Future<List<Map<String, dynamic>>> loadRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rewardsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveEvents(List<Map<String, dynamic>> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventsKey, jsonEncode(events));
  }

  Future<List<Map<String, dynamic>>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }
}
