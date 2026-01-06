import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Flights'),
        elevation: 0,
      ),
      body: Consumer2<FavoritesProvider, FlightsProvider>( //подпись на 2 провайдера
        builder: (context, favoritesProvider, flightsProvider, _) {
          final favorites = favoritesProvider.favorites; //получаем список избранных

          if (favorites.isEmpty) {
            return const Center(
              child: Text('No favorite flights yet'),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              final flight = flightsProvider.getFlightById(favorite.productId);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.flight, color: Colors.blue),
                  title: Text(flight?.flightNumber ?? favorite.productId),
                  subtitle: flight != null
                      ? Text(
                          '${flight.route} • ${flight.price.toStringAsFixed(2)} USD'
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      favoritesProvider.removeFavorite(favorite.productId);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
