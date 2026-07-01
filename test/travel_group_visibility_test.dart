import 'package:flutter_test/flutter_test.dart';
import 'package:deshexplorer/models/travel_group_model.dart';

void main() {
  group('TravelGroup destination matching', () {
    test('matches by destination name when place ids differ', () {
      final group = TravelGroup(
        id: 'g1',
        placeId: 'coxs-bazar-legacy',
        destinationName: 'Coxs Bazar',
        coverImage: '',
        title: 'Sunset trip',
        tripDate: DateTime(2026, 7, 20),
        meetingPoint: 'Dhaka',
        budgetBdt: 4000,
        maxMembers: 6,
        description: 'Test group',
        createdByUid: 'u1',
        createdAt: DateTime(2026, 7, 1),
        members: const [],
      );

      expect(
        group.matchesDestination(placeId: 'coxsbazar', destinationName: 'Coxs Bazar'),
        isTrue,
      );
    });

    test('matches by normalized place id when the values are formatted differently', () {
      final group = TravelGroup(
        id: 'g2',
        placeId: 'Sundarbans National Park',
        destinationName: 'Sundarbans',
        coverImage: '',
        title: 'Mangrove trip',
        tripDate: DateTime(2026, 8, 10),
        meetingPoint: 'Khulna',
        budgetBdt: 5000,
        maxMembers: 8,
        description: 'Test group',
        createdByUid: 'u2',
        createdAt: DateTime(2026, 7, 5),
        members: const [],
      );

      expect(
        group.matchesDestination(placeId: 'sundarbansnationalpark', destinationName: 'Somewhere else'),
        isTrue,
      );
    });

    test('does not match a different destination', () {
      final group = TravelGroup(
        id: 'g3',
        placeId: 'coxs-bazar',
        destinationName: 'Coxs Bazar',
        coverImage: '',
        title: 'Beach trip',
        tripDate: DateTime(2026, 9, 1),
        meetingPoint: 'Teknaf',
        budgetBdt: 3500,
        maxMembers: 5,
        description: 'Test group',
        createdByUid: 'u3',
        createdAt: DateTime(2026, 8, 1),
        members: const [],
      );

      expect(
        group.matchesDestination(placeId: 'sylhet', destinationName: 'Sylhet'),
        isFalse,
      );
    });
  });
}
