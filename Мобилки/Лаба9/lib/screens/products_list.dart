import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import 'product_edit.dart';
import '../services/hive_service.dart';
import 'product_details.dart';
import '../providers/user_provider.dart';
import '../providers/products_provider.dart';
import '../providers/favorites_provider.dart';

class ProductsListPage extends StatelessWidget {
  const ProductsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Flights'),
        actions: [
          // Кнопка добавления перелета через Provider
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isAdmin || userProvider.isManager) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
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
          IconButton( //неправильный ключ
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
      //подписка на провайдеры
      body: Consumer2<FlightsProvider, UserProvider>(
        builder: (context, flightsProvider, userProvider, _) {
          final flights = flightsProvider.flights;
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
                              flightsProvider.deleteFlight(flight.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                  //если нельзя редактировать, то показываем иконку избранного
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
        },
      ),
    );
  }
}
