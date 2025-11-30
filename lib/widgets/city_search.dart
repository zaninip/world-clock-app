import 'package:flutter/material.dart';
import '../models/city.dart';
import '../services/city_service.dart';

class CitySearch extends StatefulWidget {
  final Function(City) onCitySelected;
  final bool enabled;

  const CitySearch({
    super.key,
    required this.onCitySelected,
    this.enabled = true,
  });

  @override
  State<CitySearch> createState() => _CitySearchState();
}

class _CitySearchState extends State<CitySearch> {
  final TextEditingController _controller = TextEditingController();
  List<City> _suggestions = [];
  bool _isSearching = false;

  Future<void> _searchCities(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    print('Ricerca città: $query');  // Debug
    final results = await CityService.searchCities(query);
    print('Risultati trovati: ${results.length}');  // Debug

    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          onChanged: _searchCities,
          decoration: InputDecoration(
            hintText: 'Search city...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final city = _suggestions[index];
                return ListTile(
                  title: Text(city.name),
                  subtitle: Text(city.country),
                  onTap: () {
                    widget.onCitySelected(city);
                    _controller.clear();
                    setState(() {
                      _suggestions = [];
                    });
                    FocusScope.of(context).unfocus(); // chiude la tastiera
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}