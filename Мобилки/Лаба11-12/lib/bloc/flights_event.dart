import '../models/product.dart';

abstract class FlightsEvent {}

class LoadFlights extends FlightsEvent {}

class SearchFlights extends FlightsEvent {
  final String query;
  SearchFlights(this.query);
}

class AddFlight extends FlightsEvent {
  final Flight flight;
  AddFlight(this.flight);
}

class UpdateFlight extends FlightsEvent {
  final Flight flight;
  UpdateFlight(this.flight);
}

class DeleteFlight extends FlightsEvent {
  final String id;
  DeleteFlight(this.id);
}

class ToggleLike extends FlightsEvent {
  final String id;
  ToggleLike(this.id);
}

class LoadFlightsFromSnapshot extends FlightsEvent {
  final List<Flight> flights;
  final bool fromCache;
  LoadFlightsFromSnapshot(this.flights, {this.fromCache = false});
}
