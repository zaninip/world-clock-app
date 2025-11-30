import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _geonamesUsername = 'world_clock_app'; // Username GeoNames

  /// Ottieni il timezone locale
  static Future<String> getLocalTimezone() async {
    try {
      // Controlla se i servizi di localizzazione sono abilitati
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servizi di localizzazione disabilitati');
        return 'UTC'; // Fallback a Greenwich
      }

      // Controlla i permessi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permesso di localizzazione negato');
          return 'UTC'; // Fallback a Greenwich
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permesso di localizzazione negato permanentemente');
        return 'UTC'; // Fallback a Greenwich
      }

      // Ottieni la posizione
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      print('Posizione ottenuta: ${position.latitude}, ${position.longitude}');

      // Usa l'API di GeoNames per ottenere il timezone preciso
      final timezone = await _getTimezoneFromAPI(
        position.latitude,
        position.longitude,
      );

      print('Timezone locale trovato: $timezone');
      return timezone;
    } catch (e) {
      print('Errore nell\'ottenere la posizione: $e');
      return 'UTC'; // Fallback a Greenwich
    }
  }

  /// Ottieni il timezone dalle coordinate usando l'API GeoNames
  static Future<String> _getTimezoneFromAPI(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'http://api.geonames.org/timezoneJSON?'
        'lat=$lat'
        '&lng=$lng'
        '&username=$_geonamesUsername'
      );

      print('Chiamata API timezone: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] != null) {
          print('Errore API GeoNames: ${data['status']['message']}');
          return 'UTC';
        }

        final timezoneId = data['timezoneId'];
        if (timezoneId != null && timezoneId.isNotEmpty) {
          print('Timezone trovato dall\'API: $timezoneId');
          return timezoneId;
        }
      }

      print('Fallback a UTC - response: ${response.body}');
      return 'UTC';
    } catch (e) {
      print('Errore nell\'ottenere timezone da API: $e');
      return 'UTC';
    }
  }
}