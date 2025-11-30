import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/city.dart';
import 'services/location_service.dart';
import 'services/favorites_service.dart';
import 'widgets/city_search.dart';
import 'widgets/world_clock.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WorldClockPage(),
    );
  }
}

class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  String _currentTimezone = 'UTC';
  String _currentCityName = 'Greenwich Time';
  bool _isLoadingLocation = true;
  bool _isFavorite = false;
  bool _isLocalTime = true;  // Flag per sapere se stiamo mostrando l'ora locale
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    _loadInitialTime();
  }

  /// Carica l'ora iniziale: prima controlla i preferiti, poi l'ora locale
  Future<void> _loadInitialTime() async {
    // 1. Controlla se c'è una città preferita
    final favoriteCity = await FavoritesService.getFavoriteCity();
    
    if (favoriteCity != null) {
      // C'è una città preferita, mostrala
      setState(() {
        _currentTimezone = favoriteCity.timezone;
        _currentCityName = favoriteCity.name;
        _isFavorite = true;
        _isLocalTime = false;
        _isLoadingLocation = false;
      });
    } else {
      // Nessun preferito, mostra l'ora locale
      await _loadLocalTimezone();
    }
  }

  /// Carica il timezone locale
  Future<void> _loadLocalTimezone() async {
    final timezone = await LocationService.getLocalTimezone();
    setState(() {
      _currentTimezone = timezone;
      _currentCityName = timezone == 'UTC' ? 'Greenwich Time' : 'Local Time';
      _isFavorite = false;
      _isLocalTime = true;
      _isLoadingLocation = false;
    });
  }

  /// Quando l'utente seleziona una città dalla ricerca
  Future<void> _onCitySelected(City city) async {
    // Controlla se questa città è già nei preferiti
    final isFav = await FavoritesService.isFavorite(city.name, city.timezone);
    
    setState(() {
      _currentTimezone = city.timezone;
      _currentCityName = city.name;
      _isFavorite = isFav;
      _isLocalTime = false;
    });
  }

  /// Toggle preferito (aggiungi/rimuovi)
  Future<void> _toggleFavorite() async {
  
    FocusScope.of(context).unfocus(); // Chiudi la tastiera PRIMA di fare qualsiasi altra cosa

    if (_isLocalTime) {
      // Non puoi aggiungere "Local Time" ai preferiti
      _showMessage('Cannot add local time to favorites');
      return;
    }

    if (_isFavorite) {
      // Rimuovi dai preferiti
      await FavoritesService.removeFavoriteCity();
      setState(() {
        _isFavorite = false;
      });
      _showMessage('Favorite removed');
    } else {
      // Aggiungi ai preferiti
      final city = City(
        name: _currentCityName,
        country: '', // Non abbiamo bisogno del paese per i preferiti
        timezone: _currentTimezone,
      );
      await FavoritesService.saveFavoriteCity(city);
      setState(() {
        _isFavorite = true;
      });
      _showMessage('New favorite location selected');
    }
  }

  /// Mostra un messaggio temporaneo
  void _showMessage(String message) {
    FocusScope.of(context).unfocus(); // Chiudi la tastiera PRIMA di aprire il dialog
    setState(() {
      _isShowingDialog = true;  // 👈 Disabilita il TextField
    });
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-chiudi dopo 2 secondi
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
            FocusScope.of(this.context).unfocus(); // Assicurati che la tastiera rimanga chiusa
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700.withValues(alpha: 0.95),
                  Colors.blue.shade900.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icona
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    message.contains('selected') ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                // Messaggio
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isShowingDialog = false;
      });
      // Chiudi la tastiera anche quando l'utente chiude manualmente il dialog
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).unfocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // L'orologio occupa tutto lo spazio
              Column(
                children: [
                  const SizedBox(height: 100),
                  Expanded(
                    child: _isLoadingLocation
                        ? const Center(child: CircularProgressIndicator())
                        : WorldClock(
                            timezone: _currentTimezone,
                            cityName: _currentCityName,
                            isFavorite: _isFavorite,
                            isLocalTime: _isLocalTime,
                            onToggleFavorite: _toggleFavorite,
                          ),
                  ),
                ],
              ),
              // La barra di ricerca si sovrappone sopra
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CitySearch(
                    onCitySelected: _onCitySelected,
                    enabled: !_isShowingDialog,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}