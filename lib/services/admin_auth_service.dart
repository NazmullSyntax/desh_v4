import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import '../constants/firebase_constants.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _log(String message, {bool isError = false}) {
    developer.log(
      message,
      name: 'ADMIN_AUTH_SYSTEM',
      level: isError ? 1000 : 0,
    );
  }

  Future<UserCredential> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    _log('🚀 Registration Flow Started for: $email');
    UserCredential? userCredential;

    try {
      _log('⏳ Step 1: Creating Firebase Auth User...');
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final String uid = userCredential.user!.uid;
      _log('✅ Firebase Auth Success | UID: $uid');

      _log('⏳ Step 2: Preparing Firestore Document...');
      final Map<String, dynamic> adminData = {
        FirebaseConstants.fieldUid: uid,
        FirebaseConstants.fieldName: name.trim(),
        FirebaseConstants.fieldEmail: email.trim().toLowerCase(),
        FirebaseConstants.fieldRole: FirebaseConstants.roleAdmin,
        FirebaseConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
      };

      _log("⏳ Step 3: Saving Firestore Document to '${FirebaseConstants.userCollection}/$uid'...");
      await _firestore.collection(FirebaseConstants.userCollection).doc(uid).set(adminData);

      _log('✅ Firestore Saved Successfully. Admin account is fully synchronized.');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _log('❌ Firebase Auth Exception during registration: [${e.code}] ${e.message}', isError: true);
      throw _handleAuthException(e);
    } catch (e) {
      _log('❌ Critical Error during Firestore write execution: $e', isError: true);
      if (userCredential?.user != null) {
        _log('⚠️ Rolling back changes: Deleting orphaned Firebase Auth user...');
        await userCredential!.user!.delete();
        _log('🗑️ Rollback complete. Auth user removed.');
      }
      throw Exception('Registration aborted: Database initialization failed. Details: $e');
    }
  }

  Future<User> loginAdmin({
    required String email,
    required String password,
  }) async {
    _log('🚀 Login Flow Started for: $email');

    try {
      _log('⏳ Step 1: Requesting Firebase Auth Sign-In...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Authentication system returned an empty user session.');
      }
      _log('✅ Firebase Login Success | UID: ${user.uid}');

      _log('⏳ Step 2: Fetching Firestore document to check Admin Role...');
      var doc = await _firestore.collection(FirebaseConstants.userCollection).doc(user.uid).get();

      if (!doc.exists) {
        _log('⚠️ WARNING: Auth User exists, but Firestore document is missing!', isError: true);
        _log('⚡ Triggering Auto-Migration: Rebuilding missing admin document...');
        await _healMissingAdminDocument(user);
        _log('🔄 Re-fetching freshly migrated document...');
        doc = await _firestore.collection(FirebaseConstants.userCollection).doc(user.uid).get();
      }

      final data = doc.data();
      final assignedRole = data?[FirebaseConstants.fieldRole];
      _log("🔍 Document Found | Role value in DB: '$assignedRole'");

      if (assignedRole == FirebaseConstants.roleAdmin) {
        _log('🎉 Verification Passed! Role = admin. Access Granted.');
        return user;
      }

      _log("❌ Verification Failed: Role is '$assignedRole', expected '${FirebaseConstants.roleAdmin}'", isError: true);
      await _auth.signOut();
      throw Exception('Access Denied: This account is not assigned an administrator role.');
    } on FirebaseAuthException catch (e) {
      _log('❌ Firebase Auth Exception during login: [${e.code}] ${e.message}', isError: true);
      throw _handleAuthException(e);
    } catch (e) {
      _log('❌ Application Login Process Halted: $e', isError: true);
      rethrow;
    }
  }

  Future<void> _healMissingAdminDocument(User user) async {
    try {
      final migratedData = {
        FirebaseConstants.fieldUid: user.uid,
        FirebaseConstants.fieldName: user.displayName ?? 'Restored Admin Account',
        FirebaseConstants.fieldEmail: user.email!.toLowerCase(),
        FirebaseConstants.fieldRole: FirebaseConstants.roleAdmin,
        FirebaseConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
      };

      await _firestore.collection(FirebaseConstants.userCollection).doc(user.uid).set(migratedData);
      _log('✅ Auto-Migration Complete: Missing admin document structural integrity restored for UID: ${user.uid}');
    } catch (e) {
      _log('🚨 Critical System Failure: Self-healing data migration failed: $e', isError: true);
      await _auth.signOut();
      throw Exception('Critical: Account database reference missing, and recovery synchronization failed. $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found matching that email address.';
      case 'wrong-password':
        return 'Incorrect password. Please verify credentials.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please log in instead.';
      case 'invalid-email':
        return 'The format of the email address is invalid.';
      case 'user-disabled':
        return 'This admin account has been disabled by security policies.';
      case 'network-request-failed':
        return 'Network connection failure. Please verify connection.';
      default:
        return e.message ?? 'An unexpected authentication error occurred (${e.code}).';
    }
  }
}
