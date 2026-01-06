import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../bloc/flights_state.dart';
import '../bloc/flights_bloc.dart';
import '../providers/favorites_provider.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flight Details')),
      body: BlocBuilder<FlightsBloc, FlightsState>(builder: (context, state) {
        Flight? flight;
        if (state is FlightsLoadSuccess) {
          try {
            flight = state.flights.firstWhere((f) => f.id == productId);
          } catch (_) {
            flight = null;
          }
        }

        if (flight == null) {
          return const Center(child: Text('Flight not found'));
        }

        return Padding(
            padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.flight, size: 64, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        flight.flightNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, _) {
                        final isFav = favoritesProvider.isFavorite(productId);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            if (isFav) {
                              favoritesProvider.removeFavorite(productId);
                            } else {
                              favoritesProvider.addFavorite(
                                productId,
                                flight!.flightNumber,
                              );
                            }
                          },
                        );
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text('Route: ${flight.route}'),
                const SizedBox(height: 4),
                Text('Airline: ${flight.airline}'),
                const SizedBox(height: 4),
                Text('Departure: ${flight.departureTime}'),
                const SizedBox(height: 4),
                Text('Arrival: ${flight.arrivalTime}'),
                const SizedBox(height: 4),
                Text('Duration: ${flight.duration}'),
                const SizedBox(height: 4),
                Text('Available Seats: ${flight.availableSeats}'),
                const SizedBox(height: 4),
                Text('Price: ${flight.price.toStringAsFixed(2)} USD'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flight added to cart')),
                    );
                  },
                  child: const Text('Book Flight'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
