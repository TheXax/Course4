import '../models/favorite.dart';

abstract class FavoritesState {}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoadSuccess extends FavoritesState {
  final List<Favorite> favorites;
  FavoritesLoadSuccess(this.favorites);
}

class FavoritesOperationFailure extends FavoritesState {
  final String message;
  FavoritesOperationFailure(this.message);
}
