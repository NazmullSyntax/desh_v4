import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/app_user_model.dart';

/// Firebase Authentication implementation of [AuthRepository].
///
/// This is the ONLY file in the app that should import `firebase_auth`.
/// Once `google-services.json` / `GoogleService-Info.plist` and
/// `Firebase.initializeApp()` are wired up in `main.dart` (see
/// SETUP_INSTRUCTIONS.md), this class works without any further changes.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({fb.FirebaseAuth? auth, GoogleSignIn? googleSignIn, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  AppUser _mapFirebaseUser(fb.User user) {
    return AppUser(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((u) => u == null ? null : _mapFirebaseUser(u));
  }

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _mapFirebaseUser(u);
  }

  Future<void> _syncUserProfile(fb.User user, {String? name}) async {
    if (user.isAnonymous) return;

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name ?? user.displayName ?? '',
      'email': user.email,
      'photoUrl': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'createdAt': user.metadata.creationTime?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _syncUserProfile(credential.user!);
    return _mapFirebaseUser(credential.user!);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user!.updateDisplayName(name);
    await credential.user!.sendEmailVerification();
    await _syncUserProfile(credential.user!, name: name);
    return _mapFirebaseUser(credential.user!).copyWith(name: name);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw fb.FirebaseAuthException(code: 'sign-in-cancelled', message: 'Google sign-in was cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _syncUserProfile(userCredential.user!);
    return _mapFirebaseUser(userCredential.user!);
  }

  @override
  Future<AppUser> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    return AppUser(uid: credential.user!.uid, isGuest: true);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Google Sign-In may fail if not properly configured, but we should still sign out from Firebase
      print('Warning: Google Sign-In signOut failed: $e');
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (name != null) await user.updateDisplayName(name);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    await _syncUserProfile(user, name: name ?? user.displayName);
  }
}
