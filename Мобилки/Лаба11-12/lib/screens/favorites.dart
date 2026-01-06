import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../models/product.dart';
import '../bloc/flights_state.dart';
import '../bloc/flights_bloc.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Flights'),
        elevation: 0,
      ),
      body: Consumer<FavoritesProvider>( //хранит только id
        builder: (context, favoritesProvider, _) {
          final favorites = favoritesProvider.favorites;

          if (favorites.isEmpty) {
            return const Center(
              child: Text('No favorite flights yet'),
            );
          }

          //хранит полную информацию о рейсах
          return BlocBuilder<FlightsBloc, FlightsState>(builder: (context, state) {
            return ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                Flight? flight;
                if (state is FlightsLoadSuccess) {
                  try {
                    flight = state.flights.firstWhere((f) => f.id == favorite.productId);
                  } catch (_) {
                    flight = null;
                  }
                }

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
          });
        },
      ),
    );
  }
}
