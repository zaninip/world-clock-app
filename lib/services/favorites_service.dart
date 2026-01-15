import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_cities';
  static const int maxFavorites = 5;

  /// Restituisce la lista di preferiti (ordine preservato)
  static Future<List<City>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoritesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map<City>((item) {
        return City(
          name: item['name']?.toString() ?? '',
          country: item['country']?.toString() ?? '',
          timezone: item['timezone']?.toString() ?? 'UTC',
          lat: item['lat'] != null ? double.tryParse(item['lat'].toString()) : null,
          lng: item['lng'] != null ? double.tryParse(item['lng'].toString()) : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Aggiunge una città ai preferiti, rispettando il massimo di 5.
  /// Restituisce `true` se la città è stata aggiunta (o era già presente),
  /// `false` se non è stata aggiunta perché il limite è stato raggiunto.
  static Future<bool> saveFavoriteCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    // Se è già presente, non aggiungere nuovamente
    final already = favorites.any((c) => c.isSameAs(city.name, city.timezone));
    if (already) return true;

    if (favorites.length >= maxFavorites) return false;

    favorites.add(city);
    final encoded = jsonEncode(favorites.map((c) => {
          'name': c.name,
          'country': c.country,
          'timezone': c.timezone,
          'lat': c.lat,
          'lng': c.lng,
        }).toList());

    await prefs.setString(_favoritesKey, encoded);
    return true;
  }

  /// Rimuove una città dai preferiti identificandola per nome+timezone.
  static Future<void> removeFavoriteCity(String name, String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    final newList = favorites
        .where((c) => !(c.name == name && c.timezone == timezone))
        .toList();

    if (newList.isEmpty) {
      await prefs.remove(_favoritesKey);
    } else {
      final encoded = jsonEncode(newList.map((c) => {
            'name': c.name,
            'country': c.country,
            'timezone': c.timezone,
            'lat': c.lat,
            'lng': c.lng,
          }).toList());
      await prefs.setString(_favoritesKey, encoded);
    }
  }

  /// Controlla se una città è tra i preferiti
  static Future<bool> isFavorite(String cityName, String timezone) async {
    final favorites = await getFavorites();
    return favorites.any((c) => c.isSameAs(cityName, timezone));
  }
}