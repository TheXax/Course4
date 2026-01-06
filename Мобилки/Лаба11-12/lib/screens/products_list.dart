import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'product_edit.dart';
import '../services/hive_service.dart';
import 'product_details.dart';
import '../providers/user_provider.dart';
import '../providers/favorites_provider.dart';
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
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isAdmin || userProvider.isManager) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push( //переход на экран создания перелёта
                      context,
                      MaterialPageRoute(builder: (_) => const ProductEditPage()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
        final banner = (state is FlightsLoadSuccess && state.fromCache) //данные из Hive (offline)
            ? Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Text(
                  'Offline mode: showing cached flights. Syncs when online.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              )
            : const SizedBox.shrink();

        return Column(
          children: [
            if (state is FlightsLoadInProgress) //индикатор загрузки
              const LinearProgressIndicator(minHeight: 2),
            banner,
            Expanded(
              child: Consumer<UserProvider>(builder: (context, userProvider, _) {
                final canEdit = userProvider.isAdmin || userProvider.isManager;

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
                            : Consumer<FavoritesProvider>(
                                builder: (context, favProvider, _) {
                                  final isFav = favProvider.isFavorite(flight.id);
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
                                            favProvider.removeFavorite(flight.id);
                                          } else {
                                            favProvider.addFavorite(
                                              flight.id,
                                              flight.flightNumber,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}
