import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../models/family_profile.dart';
import '../models/reward.dart';
import '../models/star_event.dart';
import '../utils/auth_redirect.dart';
import 'error_mapping.dart';

export 'error_mapping.dart' show AppException, isEmailNotConfirmedError;

/// Thin wrapper around the Supabase client. Screens/providers never touch
/// `Supabase.instance` directly — everything goes through here so error
/// handling and mapping stay in one place.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  User? get currentUser => _db.auth.currentUser;
  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  /// Creates the auth user and stores the family name as user metadata
  /// (read back later by [ensureProfileForCurrentUser]).
  ///
  /// Returns `true` if a session was created immediately (this Supabase
  /// project doesn't require email confirmation), `false` if the account
  /// needs email confirmation before it can sign in — in that case there is
  /// no session yet, so `auth.uid()` is null and we must NOT try to insert
  /// the `profiles` row now: the RLS policy (`id = auth.uid()`) would
  /// reject it. The profile is created lazily on first authenticated
  /// session instead — see [ensureProfileForCurrentUser].
  Future<bool> signUpFamily({
    required String email,
    required String password,
    required String familyName,
  }) {
    return _guard(() async {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'family_name': familyName},
        emailRedirectTo: kAuthRedirectUrl,
      );
      if (res.user == null) {
        throw AppException('Impossible de créer votre espace pour le moment.');
      }
      if (res.session != null) {
        await ensureProfileForCurrentUser(familyName: familyName);
        return true;
      }
      return false;
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return _guard(() async {
      await _db.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signOut() {
    return _guard(() => _db.auth.signOut());
  }

  Future<void> sendPasswordReset(String email) {
    return _guard(
      () => _db.auth.resetPasswordForEmail(email, redirectTo: kAuthRedirectUrl),
    );
  }

  Future<void> resendConfirmationEmail(String email) {
    return _guard(
      () => _db.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: kAuthRedirectUrl,
      ),
    );
  }

  /// Creates the `profiles` row for the current session if it doesn't
  /// exist yet. Safe to call on every authenticated app start / sign-in —
  /// this is what actually finishes onboarding for an account that
  /// confirmed its email after the app already showed "check your email"
  /// (session was null back then, so signUpFamily above never inserted the
  /// row), and is a no-op for every session after the first.
  Future<void> ensureProfileForCurrentUser({String? familyName}) {
    return _guard(() async {
      final user = currentUser;
      if (user == null) return;
      final existing =
          await _db.from('profiles').select('id').eq('id', user.id).maybeSingle();
      if (existing != null) return;
      await _db.from('profiles').insert({
        'id': user.id,
        'email': user.email ?? '',
        'family_name': familyName ??
            (user.userMetadata?['family_name'] as String?) ??
            'Ma famille',
      });
    });
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  Future<FamilyProfile> fetchProfile() {
    return _guard(() async {
      final uid = currentUser!.id;
      final row = await _db.from('profiles').select().eq('id', uid).single();
      return FamilyProfile.fromMap(row);
    });
  }

  Future<void> updateFamilyName(String familyName) {
    return _guard(() async {
      await _db
          .from('profiles')
          .update({'family_name': familyName}).eq('id', currentUser!.id);
    });
  }

  Future<void> updateParentPin(String pin) {
    return _guard(() async {
      await _db
          .from('profiles')
          .update({'parent_pin': pin}).eq('id', currentUser!.id);
    });
  }

  // ---------------------------------------------------------------------
  // Children
  // ---------------------------------------------------------------------

  Future<List<Child>> fetchChildren() {
    return _guard(() async {
      final rows = await _db
          .from('children')
          .select()
          .eq('profile_id', currentUser!.id)
          .order('created_at');
      return rows.map((r) => Child.fromMap(r)).toList();
    });
  }

  Future<Child> addChild({
    required String firstName,
    required String avatar,
    required String theme,
  }) {
    return _guard(() async {
      final row = await _db
          .from('children')
          .insert({
            'profile_id': currentUser!.id,
            'first_name': firstName,
            'avatar': avatar,
            'theme': theme,
          })
          .select()
          .single();
      return Child.fromMap(row);
    });
  }

  Future<void> updateChild(
    String childId, {
    String? firstName,
    String? avatar,
    String? theme,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (avatar != null) data['avatar'] = avatar;
      if (theme != null) data['theme'] = theme;
      if (data.isEmpty) return;
      await _db.from('children').update(data).eq('id', childId);
    });
  }

  Future<void> deleteChild(String childId) {
    return _guard(() => _db.from('children').delete().eq('id', childId));
  }

  Stream<List<Map<String, dynamic>>> watchChildren(String profileId) {
    return _db
        .from('children')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .order('created_at');
  }

  // ---------------------------------------------------------------------
  // Star events
  // ---------------------------------------------------------------------

  Future<(Child, StarEvent)> addStarEvent({
    required String childId,
    required int value,
    required EventCategory category,
    required String reason,
  }) {
    return _guard(() async {
      final row = await _db.rpc('add_star_event', params: {
        'p_child_id': childId,
        'p_value': value,
        'p_category': categoryToString(category),
        'p_reason': reason,
      });
      final map = Map<String, dynamic>.from(row as Map);
      final child = Child.fromMap(Map<String, dynamic>.from(map['child'] as Map));
      final event = StarEvent.fromMap(Map<String, dynamic>.from(map['event'] as Map));
      return (child, event);
    });
  }

  Future<List<StarEvent>> fetchRecentEvents(
    List<String> childIds, {
    int limit = 60,
  }) {
    return _guard(() async {
      if (childIds.isEmpty) return <StarEvent>[];
      final rows = await _db
          .from('star_events')
          .select()
          .inFilter('child_id', childIds)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map((r) => StarEvent.fromMap(r)).toList();
    });
  }

  Future<void> deleteStarEvent(String eventId) {
    return _guard(() => _db.from('star_events').delete().eq('id', eventId));
  }

  Future<void> updateStarEvent(
    String eventId, {
    int? value,
    String? reason,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{};
      if (value != null) data['value'] = value;
      if (reason != null) data['reason'] = reason;
      if (data.isEmpty) return;
      await _db.from('star_events').update(data).eq('id', eventId);
    });
  }

  // ---------------------------------------------------------------------
  // Rewards
  // ---------------------------------------------------------------------

  Future<List<Reward>> fetchRewards() {
    return _guard(() async {
      final rows = await _db
          .from('rewards')
          .select()
          .eq('profile_id', currentUser!.id)
          .eq('active', true)
          .order('stars_required');
      return rows.map((r) => Reward.fromMap(r)).toList();
    });
  }

  Future<void> addReward({
    required String title,
    required String emoji,
    required int starsRequired,
  }) {
    return _guard(() async {
      await _db.from('rewards').insert({
        'profile_id': currentUser!.id,
        'title': title,
        'emoji': emoji,
        'stars_required': starsRequired,
      });
    });
  }

  Future<void> updateReward(
    String rewardId, {
    String? title,
    String? emoji,
    int? starsRequired,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (emoji != null) data['emoji'] = emoji;
      if (starsRequired != null) data['stars_required'] = starsRequired;
      if (data.isEmpty) return;
      await _db.from('rewards').update(data).eq('id', rewardId);
    });
  }

  Future<void> deleteReward(String rewardId) {
    return _guard(
        () => _db.from('rewards').update({'active': false}).eq('id', rewardId));
  }

  Future<Child> redeemReward({
    required String childId,
    required String rewardId,
  }) {
    return _guard(() async {
      final row = await _db.rpc('redeem_reward', params: {
        'p_child_id': childId,
        'p_reward_id': rewardId,
      });
      return Child.fromMap(Map<String, dynamic>.from(row as Map));
    });
  }
}
