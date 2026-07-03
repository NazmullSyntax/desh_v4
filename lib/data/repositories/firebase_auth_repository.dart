import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../constants/firebase_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/app_user_model.dart';

class AdminAuthException implements Exception {
  final String message;
  const AdminAuthException(this.message);

  @override
  String toString() => message;
}

({bool isAdmin, String role}) resolveAdminRole({
  required Map<String, dynamic>? userData,
  required Map<String, dynamic>? adminData,
}) {
  final bool userIsAdmin = userData?['isAdmin'] as bool? ?? false;
  final bool adminIsAdmin = adminData?['isAdmin'] as bool? ?? false;
  final String? userRole = (userData?[FirebaseConstants.fieldRole] as String?)?.trim().toLowerCase();
  final String? adminRole = (adminData?[FirebaseConstants.fieldRole] as String?)?.trim().toLowerCase();
  final String role = adminRole ?? userRole ?? (userIsAdmin || adminIsAdmin ? FirebaseConstants.roleAdmin : 'user');
  final bool isAdmin = userIsAdmin || adminIsAdmin || role == FirebaseConstants.roleAdmin;
  return (isAdmin: isAdmin, role: role);
}

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
  AppUser? _cachedUser;

  FirebaseAuthRepository({fb.FirebaseAuth? auth, GoogleSignIn? googleSignIn, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  AppUser _mapFirebaseUser(fb.User user, {bool isAdmin = false}) {
    return AppUser(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      isAdmin: isAdmin,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((u) async {
      if (u == null) {
        _cachedUser = null;
        return null;
      }
      if (_cachedUser?.uid == u.uid) {
        return _cachedUser;
      }

      try {
        final adminState = await _loadAdminState(u.uid, user: u);
        final appUser = _mapFirebaseUser(u, isAdmin: adminState.isAdmin);
        _cachedUser = appUser;
        return appUser;
      } catch (e) {
        debugPrint('Admin auth: unable to resolve admin state for ${u.uid}: $e');
        final appUser = _mapFirebaseUser(u, isAdmin: false);
        _cachedUser = appUser;
        return appUser;
      }
    });
  }

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) {
      _cachedUser = null;
      return null;
    }
    return _cachedUser?.uid == u.uid ? _cachedUser : _mapFirebaseUser(u);
  }

  Future<void> _syncUserProfile(fb.User user, {String? name, bool isAdmin = false}) async {
    if (user.isAnonymous) return;

    final role = isAdmin ? FirebaseConstants.roleAdmin : 'user';
    final profileData = {
      FirebaseConstants.fieldUid: user.uid,
      FirebaseConstants.fieldName: name ?? user.displayName ?? '',
      FirebaseConstants.fieldEmail: user.email,
      'photoUrl': user.photoURL,
      'isAdmin': isAdmin,
      FirebaseConstants.fieldRole: role,
      'isEmailVerified': user.emailVerified,
      FirebaseConstants.fieldCreatedAt: user.metadata.creationTime?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(_firestore.collection(FirebaseConstants.userCollection).doc(user.uid), profileData, SetOptions(merge: true));

    if (isAdmin) {
      batch.set(
        _firestore.collection('admins').doc(user.uid),
        {
          ...profileData,
          FirebaseConstants.fieldRole: FirebaseConstants.roleAdmin,
          'isAdmin': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<({bool isAdmin, String role})> _loadAdminState(String uid, {fb.User? user, String? name}) async {
    final userDoc = await _firestore.collection(FirebaseConstants.userCollection).doc(uid).get();
    final adminDoc = await _firestore.collection('admins').doc(uid).get();
    final resolved = resolveAdminRole(userData: userDoc.data(), adminData: adminDoc.data());

    if (resolved.isAdmin && user != null && (!adminDoc.exists || resolved.role != FirebaseConstants.roleAdmin)) {
      debugPrint('Admin auth: migrating missing admin record for $uid');
      await _syncUserProfile(user, name: name ?? user.displayName, isAdmin: true);
    }

    return resolved;
  }

  String _mapAuthError(Object error) {
    if (error is fb.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
          return 'The password is incorrect.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'email-already-in-use':
          return 'This email is already registered. Please log in instead.';
        case 'weak-password':
          return 'The password is too weak.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    if (error is FirebaseException) {
      return error.message ?? 'Firestore operation failed.';
    }

    return error.toString();
  }

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      debugPrint('Admin auth: Firebase login success. UID=${user.uid}');
      final adminState = await _loadAdminState(user.uid, user: user, name: user.displayName);
      debugPrint('Admin auth: resolved admin state. UID=${user.uid}, isAdmin=${adminState.isAdmin}, role=${adminState.role}');
      await _syncUserProfile(user, name: user.displayName, isAdmin: adminState.isAdmin);
      _cachedUser = _mapFirebaseUser(user, isAdmin: adminState.isAdmin);
      return _cachedUser!;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Admin auth: sign-in failed. Code=${e.code}, Message=${e.message}');
      throw AdminAuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      debugPrint('Admin auth: Firestore lookup failed. Code=${e.code}, Message=${e.message}');
      throw AdminAuthException('Firestore lookup failed: ${_mapAuthError(e)}');
    }
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      debugPrint('Admin auth: creating Firebase user for $email');
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      await user.updateDisplayName(name);
      await user.sendEmailVerification();
      debugPrint('Admin auth: Firebase user created. UID=${user.uid}');
      debugPrint('Admin auth: saving Firestore admin record. isAdmin=$isAdmin');
      await _syncUserProfile(user, name: name, isAdmin: isAdmin);
      _cachedUser = _mapFirebaseUser(user, isAdmin: isAdmin).copyWith(name: name);
      return _cachedUser!;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Admin auth: registration failed. Code=${e.code}, Message=${e.message}');
      throw AdminAuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      debugPrint('Admin auth: Firestore registration failed. Code=${e.code}, Message=${e.message}');
      throw AdminAuthException('Firestore admin document could not be created: ${_mapAuthError(e)}');
    }
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
    _cachedUser = _mapFirebaseUser(userCredential.user!);
    return _cachedUser!;
  }

  @override
  Future<AppUser> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    _cachedUser = AppUser(uid: credential.user!.uid, isGuest: true);
    return _cachedUser!;
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
      debugPrint('Warning: Google Sign-In signOut failed: $e');
    }
    await _auth.signOut();
    _cachedUser = null;
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
