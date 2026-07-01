import 'package:flutter_test/flutter_test.dart';
import 'package:deshexplorer/core/utils/admin_contact.dart';

void main() {
  group('Admin contact helper', () {
    test('builds a welcome message with trip details', () {
      final message = buildSupportChatWelcomeMessage(destinationName: 'Coxs Bazar', tripId: 'trip-123');

      expect(message, contains('Coxs Bazar'));
      expect(message, contains('trip-123'));
    });
  });
}
