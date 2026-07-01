import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/guide_local_datasource.dart';
import '../models/division_model.dart';
import '../models/tourist_place_model.dart';

final guideDataSourceProvider = Provider<GuideLocalDataSource>((ref) {
  return GuideLocalDataSource();
});

final divisionsProvider = FutureProvider<List<Division>>((ref) async {
  return ref.watch(guideDataSourceProvider).getDivisions();
});

final allTouristPlacesProvider = FutureProvider<List<TouristPlace>>((ref) async {
  return ref.watch(guideDataSourceProvider).getTouristPlaces();
});

final districtsForDivisionProvider = FutureProvider.family<List<District>, String>((ref, divisionId) async {
  return ref.watch(guideDataSourceProvider).getDistrictsForDivision(divisionId);
});

final districtByIdProvider = FutureProvider.family<District?, String>((ref, districtId) async {
  return ref.watch(guideDataSourceProvider).getDistrictById(districtId);
});

final placesForDistrictProvider = FutureProvider.family<List<TouristPlace>, String>((ref, districtId) async {
  return ref.watch(guideDataSourceProvider).getPlacesForDistrict(districtId);
});

final placeByIdProvider = FutureProvider.family<TouristPlace?, String>((ref, placeId) async {
  return ref.watch(guideDataSourceProvider).getPlaceById(placeId);
});

final popularPlacesProvider = FutureProvider<List<TouristPlace>>((ref) async {
  return ref.watch(guideDataSourceProvider).getPopularPlaces();
});

final trendingPlacesProvider = FutureProvider<List<TouristPlace>>((ref) async {
  return ref.watch(guideDataSourceProvider).getTrendingPlaces();
});

/// Holds the current search-bar query (home screen + guide search).
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<TouristPlace>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.watch(guideDataSourceProvider).searchPlaces(query);
});
