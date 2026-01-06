import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/history.dart';

/// Provider для управления историей покупок
class HistoryProvider extends ChangeNotifier {
  final List<History> _history = [];

  List<History> get history => _history;
  int get historyCount => _history.length;

  HistoryProvider() {
    _loadHistory();
  }

  /// Загрузить историю покупок
  void _loadHistory() {
    try {
      final historyBox = Hive.box('history');
      _history.clear();
      for (var key in historyBox.keys) {
        final item = historyBox.get(key) as History;
        _history.add(item);
      }
      // Сортировать по дате (новые сверху)
        _history.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  /// Добавить покупку в историю
  void addPurchase(String productId, String productName, double price, int quantity) {
    try {
      final historyBox = Hive.box('history');
      final historyItem = History(
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        purchaseDate: DateTime.now(),
      );
      final key = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
      historyBox.put(key, historyItem);
      _history.insert(0, historyItem); // Добавить в начало (новые сверху)
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to history: $e');
    }
  }

  /// Очистить историю
  void clearHistory() {
    try {
      final historyBox = Hive.box('history');
      historyBox.clear();
      _history.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  /// Получить сумму потраченных денег
  double getTotalSpent() {
    return _history.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// Получить количество покупок
  int getTotalPurchases() {
    return _history.fold(0, (sum, item) => sum + item.quantity as int);
  }
}
