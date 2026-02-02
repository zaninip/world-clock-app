import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/city.dart';
import 'services/location_service.dart';
import 'services/favorites_service.dart';
import 'widgets/city_search.dart';
import 'widgets/world_clock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
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
  bool _isLocalTime = true; // Flag per sapere se stiamo mostrando l'ora locale
  bool _isShowingDialog = false;

  List<City> _favorites = [];
  City? _transientCity; // città selezionata ma non ancora salvata
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadInitialTime();
  }

  /// Carica l'ora iniziale: prima controlla i preferiti, poi l'ora locale
  Future<void> _loadInitialTime() async {
    final favorites = await FavoritesService.getFavorites();
    if (favorites.isNotEmpty) {
      setState(() {
        _favorites = favorites;
        _currentPageIndex = 0;
        _transientCity = null;
        _currentTimezone = _favorites[0].timezone;
        _currentCityName = _favorites[0].name;
        _isFavorite = true;
        _isLocalTime = false;
        _isLoadingLocation = false;
        _pageController = PageController(initialPage: _currentPageIndex);
      });
    } else {
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
      _favorites = [];
      _transientCity = null;
    });
  }

  /// Quando l'utente seleziona una città dalla ricerca
  Future<void> _onCitySelected(City city) async {
    final isFav = await FavoritesService.isFavorite(city.name, city.timezone);

    if (isFav) {
      final idx = _favorites.indexWhere((c) => c.isSameAs(city.name, city.timezone));
      if (idx >= 0) {
        setState(() {
          _transientCity = null;
          _currentPageIndex = idx;
          _currentTimezone = _favorites[idx].timezone;
          _currentCityName = _favorites[idx].name;
          _isFavorite = true;
          _isLocalTime = false;
        });
        // Usa jumpToPage per evitare l'animazione visibile che scorre attraverso tutte le pagine
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageController.jumpToPage(idx);
          }
        });
        return;
      }
    }

    setState(() {
      _transientCity = city;
      _currentTimezone = city.timezone;
      _currentCityName = city.name;
      _isFavorite = false;
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
      // Rimuovi dai preferiti la città corrente
      final name = _transientCity?.name ?? _currentCityName;
      final timezone = _transientCity?.timezone ?? _currentTimezone;
      await FavoritesService.removeFavoriteCity(name, timezone);
      final updated = await FavoritesService.getFavorites();

      if (updated.isEmpty) {
        // Nessun preferito rimasto: mostra subito Local Time (non bloccare l'UI)
        setState(() {
          _favorites = [];
          _transientCity = null;
          _isFavorite = false;
          _isLocalTime = true;
          _isLoadingLocation = false; // non mostrare spinner; aggiorneremo in background
          _currentCityName = 'Local Time';
        });
        // Carica il timezone locale in background e aggiorna quando disponibile
        _loadLocalTimezone();
      } else {
        setState(() {
          _favorites = updated;
          _transientCity = null;
          _currentPageIndex = _currentPageIndex.clamp(0, _favorites.length - 1);
          _currentTimezone = _favorites[_currentPageIndex].timezone;
          _currentCityName = _favorites[_currentPageIndex].name;
          _isFavorite = true;
          _isLocalTime = false;
        });
        _pageController.jumpToPage(_currentPageIndex);
      }
      _showMessage('Favorite removed');
    } else {
      // Aggiungi ai preferiti la città corrente (transient o corrente)
      final city = _transientCity ?? City(name: _currentCityName, country: '', timezone: _currentTimezone);
      final added = await FavoritesService.saveFavoriteCity(city);
      if (!added) {
        _showMessage('Maximum 5 favorites allowed');
        return;
      }

      final updated = await FavoritesService.getFavorites();
      setState(() {
        _favorites = updated;
        _isFavorite = true;
        _transientCity = null;
        // Dopo l'aggiunta, porta l'indice all'ultimo elemento (il nuovo favorito)
        _currentPageIndex = _favorites.length - 1;
        if (_currentPageIndex < 0) _currentPageIndex = 0;
        _currentTimezone = _favorites[_currentPageIndex].timezone;
        _currentCityName = _favorites[_currentPageIndex].name;
        _isLocalTime = false;
      });
      // Assicura che la PageView sia già rebuildata prima di animare
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Usa jumpToPage per evitare l'animazione visibile che scorre attraverso tutte le pagine
          _pageController.jumpToPage(_currentPageIndex);
        }
      });
      _showMessage('New favorite location selected');
    }
  }

  /// Mostra un messaggio temporaneo
  void _showMessage(String message) {
    FocusScope.of(context).unfocus(); // Chiudi la tastiera PRIMA di aprire il dialog
    setState(() {
      _isShowingDialog = true; // 👈 Disabilita il TextField
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-chiudi dopo 2 secondi
        final navigator = Navigator.of(context);
        final focus = FocusScope.of(context);
        Future.delayed(const Duration(seconds: 2), () {
          if (navigator.canPop()) {
            navigator.pop();
            focus.unfocus(); // Assicurati che la tastiera rimanga chiusa
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
      if (!mounted) return;
      final focusThen = FocusScope.of(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        focusThen.unfocus();
      });
    });
  }

  Widget _buildClockArea() {
    if (_transientCity != null) {
      return WorldClock(
        timezone: _transientCity!.timezone,
        cityName: _transientCity!.name,
        isFavorite: false,
        isLocalTime: false,
        onToggleFavorite: _toggleFavorite,
      );
    }

    if (_favorites.isNotEmpty) {
      return Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _favorites.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                  _currentTimezone = _favorites[index].timezone;
                  _currentCityName = _favorites[index].name;
                  _isFavorite = true;
                  _isLocalTime = false;
                });
              },
              itemBuilder: (context, index) {
                final city = _favorites[index];
                return WorldClock(
                  timezone: city.timezone,
                  cityName: city.name,
                  isFavorite: true,
                  isLocalTime: false,
                  onToggleFavorite: _toggleFavorite,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_favorites.length, (i) {
              final selected = i == _currentPageIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                width: selected ? 12 : 8,
                height: selected ? 12 : 8,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      );
    }

    // Nessun preferito: mostra orario locale
    return WorldClock(
      timezone: _currentTimezone,
      cityName: _currentCityName,
      isFavorite: _isFavorite,
      isLocalTime: _isLocalTime,
      onToggleFavorite: _toggleFavorite,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                        : _buildClockArea(),
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
              // Shortcut: vai ai preferiti (mostra solo quando esiste almeno un favorito
              // e stiamo visualizzando una città non salvata - ovvero _transientCity != null)
              if (_favorites.isNotEmpty && _transientCity != null)
                Positioned(
                  top: 80,
                  right: 20,
                  child: Semantics(
                    label: 'Go to favorites',
                    button: true,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _currentPageIndex = 0;
                          _currentTimezone = _favorites[0].timezone;
                          _currentCityName = _favorites[0].name;
                          _isFavorite = true;
                          _isLocalTime = false;
                          _transientCity = null;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _pageController.jumpToPage(0);
                        });
                      },
                      backgroundColor: Colors.blue.shade800.withValues(alpha: 0.95),
                      elevation: 4,
                      child: Icon(Icons.star, color: Colors.yellow[700]),
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