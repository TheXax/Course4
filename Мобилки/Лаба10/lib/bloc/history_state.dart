import '../models/history.dart';

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoadSuccess extends HistoryState {
  final List<History> history;
  HistoryLoadSuccess(this.history);

  double get totalSpent => history.fold(0.0, (s, h) => s + (h.price * h.quantity));
}

class HistoryOperationFailure extends HistoryState {
  final String message;
  HistoryOperationFailure(this.message);
}
