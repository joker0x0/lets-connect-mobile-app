import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/models/advertisement_model.dart';

class LocalAdStorage {
  static const _key = 'ads';

  static Future<void> saveAd(Advertisement ad) async {
    final prefs = await SharedPreferences.getInstance();
    final ads = await getAds();
    ads.add(ad);
    final adsJson = ads.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(adsJson));
  }

  static Future<List<Advertisement>> getAds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((e) => Advertisement.fromJson(e)).toList();
    } catch (e) {
      print('Error decoding ads: $e');
      return [];  // return an empty list if the decoding fails
    }
  }
}
