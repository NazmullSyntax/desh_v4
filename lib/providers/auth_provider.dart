import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/storage_repository.dart';
import '../models/app_user_model.dart';
import 'storage_provider.dart';

/// Provides the active [AuthRepository] implementation. Controlled by
/// [AppConfig.useFirebase] — flip that flag once Firebase is configured.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

/// Streams the current auth state (null = signed out).
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Bumped after a profile edit to force [currentUserProvider] to re-read
/// the latest user data from the repository.
///
/// This exists because Firebase Auth's `authStateChanges()` stream does
/// NOT emit a new event after `updateDisplayName()` / `updatePhotoURL()`
/// — only on actual sign-in/sign-out. Without this, editing your name or
/// photo would silently not appear anywhere in the UI until the next app
/// restart. Call `ref.read(profileRefreshProvider.notifier).bump()` after
/// any profile mutation.
class ProfileRefreshController extends StateNotifier<int> {
  ProfileRefreshController() : super(0);
  void bump() => state = state + 1;
}

final profileRefreshProvider = StateNotifierProvider<ProfileRefreshController, int>((ref) {
  return ProfileRefreshController();
});

/// Convenience provider exposing just the current user (or null). Re-reads
/// [AuthRepository.currentUser] directly (rather than only trusting the
/// stream's last value) whenever [profileRefreshProvider] changes, so
/// edited name/photo show up immediately everywhere this is watched.
final currentUserProvider = Provider<AppUser?>((ref) {
  ref.watch(profileRefreshProvider); // dependency only — triggers re-run on bump()
  final streamUser = ref.watch(authStateProvider).maybeWhen(data: (user) => user, orElse: () => null);
  if (streamUser == null) return null;
  // Prefer the freshest snapshot directly from the repository if available,
  // falling back to the last stream value (e.g. for the Mock repository,
  // which already keeps both in sync).
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser ?? streamUser;
});

/// Controller for auth actions (login/register/etc) with loading & error
/// state, used by the auth screens.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, {bool isAdmin = false}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.registerWithEmail(name: name, email: email, password: password, isAdmin: isAdmin);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithGoogle();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> continueAsGuest() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInAsGuest();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() => _repository.signOut();

  /// Updates the signed-in user's display name and/or profile photo.
  ///
  /// If [localPhotoPath] is provided, it's uploaded via [StorageRepository]
  /// first and the resulting URL is what gets saved to the auth profile —
  /// screens never deal with storage directly. Always bumps
  /// [profileRefreshProvider] afterward so the new name/photo show up
  /// immediately (see that provider's doc comment for why this is needed).
  Future<bool> updateProfile({
    String? name,
    String? localPhotoPath,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? photoUrl;
      if (localPhotoPath != null) {
        final storage = _ref.read(storageRepositoryProvider);
        final user = _repository.currentUser;
        photoUrl = await storage.uploadFile(
          localFilePath: localPhotoPath,
          folder: 'profile_photos',
          fileName: '${user?.uid ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      await _repository.updateProfile(name: name, photoUrl: photoUrl);
      _ref.read(profileRefreshProvider.notifier).bump();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
