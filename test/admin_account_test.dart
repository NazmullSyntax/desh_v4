import 'package:flutter_test/flutter_test.dart';
import 'package:deshexplorer/data/repositories/firebase_auth_repository.dart';
import 'package:deshexplorer/data/repositories/mock_auth_repository.dart';

void main() {
  group('Admin account flow', () {
    test('resolveAdminRole accepts admin status from the admin document', () {
      final resolved = resolveAdminRole(
        userData: {'isAdmin': false},
        adminData: {'isAdmin': true, 'role': 'admin'},
      );

      expect(resolved.isAdmin, isTrue);
      expect(resolved.role, 'admin');
    });

    test('resolveAdminRole falls back to the legacy users document flag', () {
      final resolved = resolveAdminRole(
        userData: {'isAdmin': true},
        adminData: {},
      );

      expect(resolved.isAdmin, isTrue);
      expect(resolved.role, 'admin');
    });

    test('registering as admin creates an admin user that can sign in', () async {
      final repo = MockAuthRepository();

      final created = await repo.registerWithEmail(
        name: 'Support Admin',
        email: 'admin@example.com',
        password: 'secret123',
        isAdmin: true,
      );

      expect(created.isAdmin, isTrue);

      final signedIn = await repo.signInWithEmail(
        email: 'admin@example.com',
        password: 'secret123',
      );

      expect(signedIn.isAdmin, isTrue);
      expect(signedIn.email, 'admin@example.com');
    });
  });
}
