import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/division_model.dart';
import '../../models/tourist_place_model.dart';

/// Loads the Bangladesh travel-guide dataset bundled as JSON assets.
///
/// This is a local/offline data source by design: the guide should work
/// with zero network calls for the curated districts, and degrade
/// gracefully (showing "coming soon" stubs) for districts without rich
/// data yet. When the backend is ready, swap this out for a Firestore- or
/// API-backed implementation behind the same method signatures.
class GuideLocalDataSource {
  List<Division>? _divisionsCache;
  List<District>? _districtsCache;
  List<TouristPlace>? _placesCache;

  Future<List<Division>> getDivisions() async {
    if (_divisionsCache != null) return _divisionsCache!;
    final raw = await rootBundle.loadString('assets/data/divisions.json');
    final list = json.decode(raw) as List<dynamic>;
    _divisionsCache = list.map((e) => Division.fromJson(e as Map<String, dynamic>)).toList();
    return _divisionsCache!;
  }

  Future<List<District>> getDistricts() async {
    if (_districtsCache != null) return _districtsCache!;
    final raw = await rootBundle.loadString('assets/data/districts.json');
    final list = json.decode(raw) as List<dynamic>;
    _districtsCache = list.map((e) => District.fromJson(e as Map<String, dynamic>)).toList();
    return _districtsCache!;
  }

  Future<List<TouristPlace>> getTouristPlaces() async {
    if (_placesCache != null) return _placesCache!;
    final raw = await rootBundle.loadString('assets/data/tourist_places.json');
    final list = json.decode(raw) as List<dynamic>;
    _placesCache = list.map((e) => TouristPlace.fromJson(e as Map<String, dynamic>)).toList();
    return _placesCache!;
  }

  Future<List<District>> getDistrictsForDivision(String divisionId) async {
    final districts = await getDistricts();
    return districts.where((d) => d.divisionId == divisionId).toList();
  }

  Future<List<TouristPlace>> getPlacesForDistrict(String districtId) async {
    final places = await getTouristPlaces();
    return places.where((p) => p.districtId == districtId).toList();
  }

  Future<TouristPlace?> getPlaceById(String id) async {
    final places = await getTouristPlaces();
    try {
      return places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<District?> getDistrictById(String id) async {
    final districts = await getDistricts();
    try {
      return districts.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<TouristPlace>> getPopularPlaces() async {
    final places = await getTouristPlaces();
    return places.where((p) => p.isPopular).toList();
  }

  Future<List<TouristPlace>> getTrendingPlaces() async {
    final places = await getTouristPlaces();
    return places.where((p) => p.isTrending).toList();
  }

  Future<List<TouristPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    final places = await getTouristPlaces();
    final q = query.toLowerCase();
    return places.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.shortDescription.toLowerCase().contains(q) ||
          p.category.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }
}
