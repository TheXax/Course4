import '../models/product.dart';

abstract class FlightsState {}

class FlightsInitial extends FlightsState {}

class FlightsLoadInProgress extends FlightsState {}

class FlightsLoadSuccess extends FlightsState {
  final List<Flight> flights;
  final String query;
  final bool fromCache;

  FlightsLoadSuccess(this.flights, {this.query = '', this.fromCache = false});

  List<Flight> get filtered {
    if (query.isEmpty) return flights;
    final q = query.toLowerCase();
    return flights.where((f) {
      return f.departureCity.toLowerCase().contains(q) ||
          f.arrivalCity.toLowerCase().contains(q) ||
          f.airline.toLowerCase().contains(q) ||
          f.flightNumber.toLowerCase().contains(q);
    }).toList();
  }
}

class FlightsOperationFailure extends FlightsState {
  final String message;
  FlightsOperationFailure(this.message);
}
