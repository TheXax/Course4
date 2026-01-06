import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

//Provider для управления перелетами
class FlightsProvider extends ChangeNotifier {
  final List<Flight> _flights = [];
  final List<Flight> _filteredFlights = [];
  String _searchQuery = '';

  List<Flight> get flights => _flights;
  List<Flight> get filteredFlights =>
      _searchQuery.isEmpty ? _flights : _filteredFlights;

  FlightsProvider() {
    _loadFlights();
  }

  //Загрузить все перелеты из Hive
  void _loadFlights() {
    try {
      final flightsBox = Hive.box('products');
      _flights.clear();
      for (var key in flightsBox.keys) {
        final flight = flightsBox.get(key) as Flight;
        _flights.add(flight);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flights: $e');
    }
  }

  //Поиск перелетов по городам или авиакомпании
  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filteredFlights.clear();

    if (_searchQuery.isEmpty) {
      notifyListeners();
      return;
    }

    for (var flight in _flights) {
      if (flight.departureCity.toLowerCase().contains(_searchQuery) ||
          flight.arrivalCity.toLowerCase().contains(_searchQuery) ||
          flight.airline.toLowerCase().contains(_searchQuery) ||
          flight.flightNumber.toLowerCase().contains(_searchQuery)) {
        _filteredFlights.add(flight);
      }
    }
    notifyListeners();
  }

  //Добавить новый перелет
  void addFlight(Flight flight) {
    try {
      final flightsBox = Hive.box('products');
      flightsBox.put(flight.id, flight);
      _flights.add(flight);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding flight: $e');
    }
  }

  //Обновить перелет
  void updateFlight(Flight flight) {
    try {
      final flightsBox = Hive.box('products');
      flightsBox.put(flight.id, flight);

      final index = _flights.indexWhere((f) => f.id == flight.id);
      if (index != -1) {
        _flights[index] = flight;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating flight: $e');
    }
  }

  //Удалить перелет
  void deleteFlight(String flightId) {
    try {
      final flightsBox = Hive.box('products');
      flightsBox.delete(flightId);
      _flights.removeWhere((f) => f.id == flightId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting flight: $e');
    }
  }

  //Получить перелет по ID
  Flight? getFlightById(String id) {
    try {
      return _flights.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  //Переключить статус "лайка" для перелета
  void toggleLike(String flightId) {
    final flight = getFlightById(flightId);
    if (flight != null) {
      flight.isLiked = !flight.isLiked;
      updateFlight(flight);
    }
  }
}
