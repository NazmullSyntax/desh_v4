import 'dart:async';
import '../../domain/repositories/auth_repository.dart';
import '../../models/app_user_model.dart';

/// In-memory mock implementation of [AuthRepository].
///
/// Useful for running and demoing the app before Firebase credentials are
/// added, and for widget/unit tests. Swap [FirebaseAuthRepository] in once
/// `google-services.json` is in place (see main.dart / providers/auth_provider.dart).
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  final Map<String, ({String password, bool isAdmin})> _registeredUsers = {};

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _current;

  void _emit(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final entry = _registeredUsers[email];
    if (entry == null || entry.password != password) {
      throw Exception('Invalid email or password.');
    }
    final user = AppUser(
      uid: email.hashCode.toString(),
      email: email,
      name: email.split('@').first,
      isAdmin: entry.isAdmin,
    );
    _emit(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _registeredUsers[email] = (password: password, isAdmin: isAdmin);
    final user = AppUser(
      uid: email.hashCode.toString(),
      email: email,
      name: name,
      createdAt: DateTime.now(),
      isAdmin: isAdmin,
    );
    _emit(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = const AppUser(uid: 'google_mock_uid', email: 'demo@deshexplorer.app', name: 'Demo Traveler');
    _emit(user);
    return user;
  }

  @override
  Future<AppUser> signInAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Unique per session so each guest gets their own favorites/trips
    // bucket in the mock repositories, matching how Firebase's real
    // signInAnonymously() always returns a fresh unique uid.
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final user = AppUser(uid: guestId, isGuest: true);
    _emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_registeredUsers.containsKey(email)) {
      throw Exception('No account found for this email.');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _emit(null);
  }

  @override
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (_current == null) return;
    _emit(_current!.copyWith(name: name, photoUrl: photoUrl));
  }
}
