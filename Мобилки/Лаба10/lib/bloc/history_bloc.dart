import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'history_event.dart';
import 'history_state.dart';
import '../models/history.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(HistoryInitial()) {
    on<LoadHistory>(_onLoad);
    on<AddPurchase>(_onAdd);
    on<ClearHistoryEvent>(_onClear);
  }

  Future<void> _onLoad(LoadHistory event, Emitter<HistoryState> emit) async {
    try {
      final box = Hive.box('history');
      final List<History> items = [];
      for (var key in box.keys) items.add(box.get(key) as History);
      items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      emit(HistoryLoadSuccess(items));
    } catch (e) {
      emit(HistoryOperationFailure('Failed to load history: $e'));
    }
  }

  Future<void> _onAdd(AddPurchase event, Emitter<HistoryState> emit) async {
    try {
      final box = Hive.box('history');
      final historyItem = History(
        productId: event.productId,
        productName: event.productName,
        price: event.price,
        quantity: event.quantity,
        purchaseDate: DateTime.now(),
      );
      final key = '${event.productId}_${DateTime.now().millisecondsSinceEpoch}';
      await box.put(key, historyItem);
      add(LoadHistory());
    } catch (e) {
      emit(HistoryOperationFailure('Failed to add history: $e'));
    }
  }

  Future<void> _onClear(ClearHistoryEvent event, Emitter<HistoryState> emit) async {
    try {
      final box = Hive.box('history');
      await box.clear();
      emit(HistoryLoadSuccess([]));
    } catch (e) {
      emit(HistoryOperationFailure('Failed to clear history: $e'));
    }
  }
}
