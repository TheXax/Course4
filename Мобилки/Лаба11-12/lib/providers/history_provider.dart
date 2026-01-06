import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/history.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';

/// Provider для управления историей покупок (с Firestore + Hive cache)
class HistoryProvider extends ChangeNotifier {
  final List<History> _history = [];
  final FirebaseService _fs = FirebaseService();
  StreamSubscription? _subscription;

  List<History> get history => _history;
  int get historyCount => _history.length;

  HistoryProvider() {
    _loadHistory();
    _subscribeFirestore();
  }

  void _loadHistory() {
    try {
      final historyBox = Hive.box('history');
      _history.clear();
      for (var key in historyBox.keys) {
        final item = historyBox.get(key) as History;
        _history.add(item);
      }
      _history.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  void _subscribeFirestore() {
    try {
      _subscription = _fs.collectionStream('history').listen((snapshot) async {
        final box = Hive.box('history');
        _history.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final h = History.fromMap(data);
          _history.add(h);
          try {
            await box.put(doc.id, h);
          } catch (_) {}
        }
        _history.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error subscribing to history: $e');
    }
  }

  Future<void> addPurchase(String productId, String productName, double price, int quantity) async {
    try {
      final historyItem = History(
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        purchaseDate: DateTime.now(),
      );
      final docRef = await _fs.addDocument('history', historyItem.toMap());
      final box = Hive.box('history');
      await box.put(docRef.id, historyItem);
      _history.insert(0, historyItem);
      try {
        // Log analytics for completed purchase
        // keep parameters minimal to avoid PII
        await AnalyticsService.instance.logEvent('purchase_completed', parameters: {
          'productId': productId,
          'price': price,
          'quantity': quantity,
        });
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final box = Hive.box('history');
      for (var key in box.keys) {
        try {
          await _fs.deleteDocument('history', key as String);
        } catch (_) {}
      }
      box.clear();
      _history.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  double getTotalSpent() {
    return _history.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int getTotalPurchases() {
    return _history.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
