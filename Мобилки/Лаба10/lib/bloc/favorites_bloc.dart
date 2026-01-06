import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';
import '../models/favorite.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc() : super(FavoritesInitial()) {
    //регистрация обработчиков
    on<LoadFavorites>(_onLoad);
    on<AddFavoriteEvent>(_onAdd);
    on<RemoveFavoriteEvent>(_onRemove);
    on<ClearFavorites>(_onClear);
  }

  Future<void> _onLoad(LoadFavorites event, Emitter<FavoritesState> emit) async { //отправляет новое состояние через emit
    try {
      final box = Hive.box('favorites');
      final List<Favorite> favs = [];
      for (var key in box.keys) {
        favs.add(box.get(key) as Favorite);
      }
      emit(FavoritesLoadSuccess(favs)); //отправляет состояние
    } catch (e) {
      emit(FavoritesOperationFailure('Failed to load favorites: $e'));
    }
  }

  Future<void> _onAdd(AddFavoriteEvent event, Emitter<FavoritesState> emit) async {
    try {
      final box = Hive.box('favorites');
      final favorite = Favorite(productId: event.productId, productName: event.productName);
      final key = '${event.productId}_${DateTime.now().millisecondsSinceEpoch}'; //создаём уникальный ключ
      await box.put(key, favorite);
      add(LoadFavorites());
    } catch (e) {
      emit(FavoritesOperationFailure('Failed to add favorite: $e'));
    }
  }

  Future<void> _onRemove(RemoveFavoriteEvent event, Emitter<FavoritesState> emit) async {
    try {
      final box = Hive.box('favorites');
      final keysToRemove = <dynamic>[];
      for (var key in box.keys) {
        final fav = box.get(key) as Favorite;
        if (fav.productId == event.productId) keysToRemove.add(key);
      }
      for (var k in keysToRemove) box.delete(k);
      add(LoadFavorites()); //перезагружаем список
    } catch (e) {
      emit(FavoritesOperationFailure('Failed to remove favorite: $e'));
    }
  }

  Future<void> _onClear(ClearFavorites event, Emitter<FavoritesState> emit) async {
    try {
      final box = Hive.box('favorites');
      await box.clear();
      emit(FavoritesLoadSuccess([]));
    } catch (e) {
      emit(FavoritesOperationFailure('Failed to clear favorites: $e'));
    }
  }
}
