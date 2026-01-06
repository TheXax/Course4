import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_edit.dart';
import '../services/hive_service.dart';
import 'product_details.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_state.dart';
import '../bloc/user_event.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_state.dart';
import '../bloc/favorites_event.dart';
import '../bloc/flights_bloc.dart';
import '../bloc/flights_state.dart';
import '../bloc/flights_event.dart';

class ProductsListPage extends StatelessWidget {
  const ProductsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Flights'),
        actions: [
          BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
            final canEdit = userState is UserLoadSuccess && (userState.isAdmin || userState.isManager);
            return canEdit
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProductEditPage()),
                      );
                    },
                  )
                : const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Compact flights box',
            onPressed: () async {
              await HiveService.compactBox('products');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Flights box compacted'))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_off),
            tooltip: 'Test wrong key',
            onPressed: () async {
              final wrong = HiveService.generateNewKey();
              final result = await HiveService.tryOpenWithKey(wrong);
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Wrong key test'),
                  content: Text(result),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FlightsBloc, FlightsState>(builder: (context, state) {
        final flights = state is FlightsLoadSuccess ? state.filtered : [];
        return BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
          final canEdit = userState is UserLoadSuccess && (userState.isAdmin || userState.isManager);

          if (flights.isEmpty) {
            return const Center(child: Text('No flights available'));
          }

          return ListView.builder(
            itemCount: flights.length,
            itemBuilder: (context, index) {
              final flight = flights[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(productId: flight.id),
                    ),
                  ),
                  leading: const Icon(Icons.flight, color: Colors.blue),
                  title: Text(
                    flight.flightNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${flight.route} • ${flight.price.toStringAsFixed(2)} USD'
                  ),
                  trailing: canEdit
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                    ProductEditPage(productId: flight.id),
                                ),
                              );
                            } else if (value == 'delete') {
                              context.read<FlightsBloc>().add(DeleteFlight(flight.id));
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : BlocBuilder<FavoritesBloc, FavoritesState>(builder: (context, favState) {
                          final favs = favState is FavoritesLoadSuccess ? favState.favorites : [];
                          final isFav = favs.any((f) => f.productId == flight.id);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  if (isFav) {
                                    context.read<FavoritesBloc>().add(RemoveFavoriteEvent(flight.id));
                                  } else {
                                    context.read<FavoritesBloc>().add(AddFavoriteEvent(flight.id, flight.flightNumber));
                                  }
                                },
                              ),
                            ],
                          );
                        }),
                ),
              );
            },
          );
        });
      }),
    );
  }
}
