import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/city.dart';

class CityService {
  static const String _username = 'world_clock_app'; // Username GeoNames
  
  // Cache per le ricerche
  static final Map<String, List<City>> _searchCache = {};

  /// Cerca città usando l'API di GeoNames
  static Future<List<City>> searchCities(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    // Controlla la cache
    if (_searchCache.containsKey(query.toLowerCase())) {
      return _searchCache[query.toLowerCase()]!;
    }

    try {
      final url = Uri.parse(
        'http://api.geonames.org/searchJSON?'
        'name_startsWith=$query'
        '&maxRows=50'
        '&username=$_username'
        '&featureClass=P' // Solo città/paesi
        '&orderby=population' // Ordina per popolazione
        '&style=full'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> geonames = data['geonames'] ?? [];
        
        final cities = geonames.map((json) => City.fromJson(json)).toList();
        
        // Salva in cache
        _searchCache[query.toLowerCase()] = cities;
        
        return cities;
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      print('Errore nella ricerca città: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}