import '../../models/app_user_model.dart';

/// Domain-layer contract for authentication. The presentation layer (UI,
/// providers) only ever talks to this interface — never to Firebase
/// directly — so the auth backend can be swapped without touching screens.
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> signInWithEmail({required String email, required String password});

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInAsGuest();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<void> updateProfile({String? name, String? photoUrl});
}
