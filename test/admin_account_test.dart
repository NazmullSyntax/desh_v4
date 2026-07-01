import 'package:flutter_test/flutter_test.dart';
import 'package:deshexplorer/data/repositories/mock_auth_repository.dart';

void main() {
  group('Admin account flow', () {
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
