import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_state.dart';
import '../models/product.dart';
import '../models/favorite.dart';
import '../bloc/favorites_event.dart';
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
      body: BlocBuilder<FavoritesBloc, FavoritesState>(builder: (context, favState) {
        //если данные загружены, то берём список избранных, если нет - используем пустой список
        final List<Favorite> favorites = favState is FavoritesLoadSuccess ? favState.favorites : <Favorite>[];

        if (favorites.isEmpty) {
          return const Center(
            child: Text('No favorite flights yet'),
          );
        }

        //по id избранного получить полный объект рейса
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
                        context.read<FavoritesBloc>().add(RemoveFavoriteEvent(favorite.productId));
                      },
                    ),
                  ),
                );
              },
            );
          });
      }),
    );
  }
}
