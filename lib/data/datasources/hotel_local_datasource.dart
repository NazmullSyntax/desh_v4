import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/hotel_model.dart';

/// Loads the bundled hotel dataset. Like [GuideLocalDataSource], this is a
/// local stand-in for what would eventually be a Firestore collection or a
/// partner booking API (Booking.com / Agoda style integration).
class HotelLocalDataSource {
  List<Hotel>? _cache;

  Future<List<Hotel>> getAllHotels() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/hotels.json');
    final list = json.decode(raw) as List<dynamic>;
    _cache = list.map((e) => Hotel.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  Future<List<Hotel>> getHotelsForDistrict(String districtId) async {
    final hotels = await getAllHotels();
    return hotels.where((h) => h.districtId == districtId).toList();
  }

  Future<Hotel?> getHotelById(String id) async {
    final hotels = await getAllHotels();
    try {
      return hotels.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }
}
