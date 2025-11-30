import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';

class FavoritesService {
  static const String _favoriteCityNameKey = 'favorite_city_name';
  static const String _favoriteCityCountryKey = 'favorite_city_country';
  static const String _favoriteCityTimezoneKey = 'favorite_city_timezone';

  /// Salva una città come preferita
  static Future<void> saveFavoriteCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoriteCityNameKey, city.name);
    await prefs.setString(_favoriteCityCountryKey, city.country);
    await prefs.setString(_favoriteCityTimezoneKey, city.timezone);
  }

  /// Ottieni la città preferita (se esiste)
  static Future<City?> getFavoriteCity() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_favoriteCityNameKey);
    final country = prefs.getString(_favoriteCityCountryKey);
    final timezone = prefs.getString(_favoriteCityTimezoneKey);

    if (name != null && country != null && timezone != null) {
      return City(
        name: name,
        country: country,
        timezone: timezone,
      );
    }

    return null; // Nessun preferito
  }

  /// Rimuovi la città preferita
  static Future<void> removeFavoriteCity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteCityNameKey);
    await prefs.remove(_favoriteCityCountryKey);
    await prefs.remove(_favoriteCityTimezoneKey);
  }

  /// Controlla se una città è la preferita
  static Future<bool> isFavorite(String cityName, String timezone) async {
    final favoriteCity = await getFavoriteCity();
    if (favoriteCity == null) return false;
    return favoriteCity.name == cityName && favoriteCity.timezone == timezone;
  }
}