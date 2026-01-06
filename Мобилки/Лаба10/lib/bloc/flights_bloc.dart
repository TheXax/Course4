import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import 'flights_event.dart';
import 'flights_state.dart';

class FlightsBloc extends Bloc<FlightsEvent, FlightsState> {
  FlightsBloc() : super(FlightsInitial()) {
    on<LoadFlights>(_onLoadFlights);
    on<SearchFlights>(_onSearchFlights);
    on<AddFlight>(_onAddFlight);
    on<UpdateFlight>(_onUpdateFlight);
    on<DeleteFlight>(_onDeleteFlight);
    on<ToggleLike>(_onToggleLike);
  }

  Future<void> _onLoadFlights(LoadFlights event, Emitter<FlightsState> emit) async {
    emit(FlightsLoadInProgress());
    try {
      final box = Hive.box('products');
      final List<Flight> flights = [];
      for (var key in box.keys) {
        final f = box.get(key) as Flight;
        flights.add(f);
      }
      emit(FlightsLoadSuccess(flights));
    } catch (e) {
      emit(FlightsOperationFailure('Failed to load flights: $e'));
    }
  }

  void _onSearchFlights(SearchFlights event, Emitter<FlightsState> emit) {
    final current = state;
    if (current is FlightsLoadSuccess) {
      emit(FlightsLoadSuccess(current.flights, query: event.query));
    }
  }

  Future<void> _onAddFlight(AddFlight event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      await box.put(event.flight.id, event.flight);
      add(LoadFlights());
    } catch (e) {
      emit(FlightsOperationFailure('Failed to add flight: $e'));
    }
  }

  Future<void> _onUpdateFlight(UpdateFlight event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      await box.put(event.flight.id, event.flight);
      add(LoadFlights());
    } catch (e) {
      emit(FlightsOperationFailure('Failed to update flight: $e'));
    }
  }

  Future<void> _onDeleteFlight(DeleteFlight event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      await box.delete(event.id);
      add(LoadFlights());
    } catch (e) {
      emit(FlightsOperationFailure('Failed to delete flight: $e'));
    }
  }

  Future<void> _onToggleLike(ToggleLike event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      final f = box.get(event.id) as Flight?;
      if (f != null) {
        f.isLiked = !f.isLiked;
        await box.put(f.id, f);
        add(LoadFlights());
      }
    } catch (e) {
      emit(FlightsOperationFailure('Failed to toggle like: $e'));
    }
  }
}
