import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import 'flights_event.dart';
import 'flights_state.dart';

class FlightsBloc extends Bloc<FlightsEvent, FlightsState> {
  final FirebaseService _fs = FirebaseService(); //Создаём экземпляр сервиса Firebase для работы с Firestore
  StreamSubscription<QuerySnapshot>? _subscription; //для подписки на поток данных Firestore, чтобы получать обновления в реальном времени и корректно отменить подписку
  FlightsBloc() : super(FlightsInitial()) {
    on<LoadFlights>(_onLoadFlights);
    on<SearchFlights>(_onSearchFlights);
    on<AddFlight>(_onAddFlight);
    on<UpdateFlight>(_onUpdateFlight);
    on<DeleteFlight>(_onDeleteFlight);
    on<ToggleLike>(_onToggleLike);
    on<LoadFlightsFromSnapshot>(_onLoadFlightsFromSnapshot); //бновление списка после получения данных из Firestore
  }

  Future<void> _onLoadFlights(LoadFlights event, Emitter<FlightsState> emit) async {
    emit(FlightsLoadInProgress());
    try {
      final box = Hive.box('products');
      //список для перелётов из кэша
      final List<Flight> cached = [];
      for (var key in box.keys) {
        final f = box.get(key) as Flight;
        cached.add(f);
      }
      //Если есть локальные данные, сразу их отображаем. Быстрый UI, даже без интернета
      if (cached.isNotEmpty) emit(FlightsLoadSuccess(cached, fromCache: true));

      //Если уже подписаны на Firestore — не подписываемся повторно
      if (_subscription != null) return;
      //Подписываемся на реальный поток данных Firestore
      _subscription = _fs.collectionStream('flights').listen((snapshot) async {
        final List<Flight> flights = [];
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>; //берём данные
          //добавляем id
          data['id'] = doc.id;
          final f = Flight.fromMap(data);
          flights.add(f);
          //обновляем локальный кэш
          try {
            await box.put(f.id, f);
          } catch (_) {}
        }
        //Отправляем новое событие с актуальными данными
        add(LoadFlightsFromSnapshot(flights, fromCache: snapshot.metadata.isFromCache));
      });
    } catch (e) {
      emit(FlightsOperationFailure('Failed to load flights: $e'));
    }
  }

  Future<void> _onLoadFlightsFromSnapshot(LoadFlightsFromSnapshot event, Emitter<FlightsState> emit) async {
    emit(FlightsLoadSuccess(event.flights, fromCache: event.fromCache));
  }

  void _onSearchFlights(SearchFlights event, Emitter<FlightsState> emit) {
    final current = state;
    //Поиск делается по уже загруженным данным, без повторной загрузки
    if (current is FlightsLoadSuccess) {
      emit(FlightsLoadSuccess(current.flights, query: event.query, fromCache: current.fromCache));
    }
  }

  Future<void> _onAddFlight(AddFlight event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      //Сохраняем перелёт в Firestore
      await _fs.setDocument('flights', event.flight.id, event.flight.toMap());
      //сохранияем в Hive
      await box.put(event.flight.id, event.flight);
      try {
        //Отправляем событие в аналитику
        await AnalyticsService.instance.logEvent('flight_added', parameters: {'id': event.flight.id});
      } catch (_) {}
      add(LoadFlights());
    } catch (e) {
      emit(FlightsOperationFailure('Failed to add flight: $e'));
    }
  }

  Future<void> _onUpdateFlight(UpdateFlight event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      await _fs.updateDocument('flights', event.flight.id, event.flight.toMap());
      await box.put(event.flight.id, event.flight);
      add(LoadFlights());
    } catch (e) {
      emit(FlightsOperationFailure('Failed to update flight: $e'));
    }
  }

  Future<void> _onDeleteFlight(DeleteFlight event, Emitter<FlightsState> emit) async {
    try {
      final box = Hive.box('products');
      await _fs.deleteDocument('flights', event.id);
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
        try {
          await _fs.updateDocument('flights', f.id, f.toMap());
          try {
            await AnalyticsService.instance.logEvent('flight_liked', parameters: {'id': f.id, 'liked': f.isLiked});
          } catch (_) {}
        } catch (_) {}
        add(LoadFlights());
      }
    } catch (e) {
      emit(FlightsOperationFailure('Failed to toggle like: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
