import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/city.dart';
import '../models/country.dart';
import '../providers/city_provider.dart';
import '../providers/country_provider.dart';

/// A two-level dropdown that lets the user pick a country first,
/// then shows only the cities that belong to that country.
///
/// Pass [initialCity] to pre-select a city (e.g. on edit screens).
/// The [onCityChanged] callback fires every time the city selection changes.
class CountryCitySelector extends StatefulWidget {
  final City? initialCity;
  final void Function(City?) onCityChanged;

  const CountryCitySelector({
    required this.onCityChanged,
    this.initialCity,
    super.key,
  });

  @override
  State<CountryCitySelector> createState() => _CountryCitySelectorState();
}

class _CountryCitySelectorState extends State<CountryCitySelector> {
  List<Country> _countries = [];
  List<City> _allCities = [];
  List<City> _filteredCities = [];

  Country? _selectedCountry;
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _load();
  }

  Future<void> _load() async {
    final countryProvider = context.read<CountryProvider>();
    final cityProvider = context.read<CityProvider>();

    final countriesResult = await countryProvider.get();
    final citiesResult = await cityProvider.get();

    if (!mounted) return;

    final countries = countriesResult.result;
    final allCities = citiesResult.result;

    Country? initCountry;
    if (widget.initialCity != null) {
      try {
        initCountry = countries.firstWhere(
          (c) => c.id == widget.initialCity!.countryId,
        );
      } catch (_) {
        initCountry = countries.isNotEmpty ? countries[0] : null;
      }
    } else {
      initCountry = countries.isNotEmpty ? countries[0] : null;
    }

    final filtered = initCountry != null
        ? allCities.where((c) => c.countryId == initCountry!.id).toList()
        : allCities;

    City? initCity = widget.initialCity;
    if (initCity == null && filtered.isNotEmpty) {
      initCity = filtered[0];
      widget.onCityChanged(initCity);
    }

    setState(() {
      _countries = countries;
      _allCities = allCities;
      _selectedCountry = initCountry;
      _filteredCities = filtered;
      _selectedCity = initCity;
    });
  }

  void _onCountryChanged(Country? country) {
    final filtered = country != null
        ? _allCities.where((c) => c.countryId == country.id).toList()
        : _allCities;
    final newCity = filtered.isNotEmpty ? filtered[0] : null;
    setState(() {
      _selectedCountry = country;
      _filteredCities = filtered;
      _selectedCity = newCity;
    });
    widget.onCityChanged(newCity);
  }

  void _onCityChanged(City? city) {
    setState(() => _selectedCity = city);
    widget.onCityChanged(city);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Country>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Država',
              border: OutlineInputBorder(),
            ),
            items: _countries
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? '')))
                .toList(),
            onChanged: _onCountryChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<City>(
            value: _filteredCities.contains(_selectedCity) ? _selectedCity : null,
            decoration: const InputDecoration(
              labelText: 'Grad',
              border: OutlineInputBorder(),
            ),
            items: _filteredCities
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? '')))
                .toList(),
            onChanged: _onCityChanged,
          ),
        ),
      ],
    );
  }
}
