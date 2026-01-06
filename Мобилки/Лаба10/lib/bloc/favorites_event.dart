abstract class FavoritesEvent {}

class LoadFavorites extends FavoritesEvent {}

class AddFavoriteEvent extends FavoritesEvent {
  final String productId;
  final String productName;
  AddFavoriteEvent(this.productId, this.productName);
}

class RemoveFavoriteEvent extends FavoritesEvent {
  final String productId;
  RemoveFavoriteEvent(this.productId);
}

class ClearFavorites extends FavoritesEvent {}
