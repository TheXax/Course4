import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import 'product_edit.dart';
import '../services/hive_service.dart';
import 'product_details.dart';
import '../models/favorite.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  late Box productsBox;

  @override
  void initState() {
    super.initState();
    productsBox = Hive.box('products');
  }

  @override
  Widget build(BuildContext context) {
    final appBox = Hive.box('app');
    final usersBox = Hive.box('users');
    final currentId = appBox.get('currentUserId') as String?;
    final currentUser = currentId != null ? usersBox.get(currentId) : null;
    final role = currentUser != null ? ((currentUser as dynamic).role as String? ?? 'user') : 'user';
    final canEdit = role == 'admin' || role == 'manager';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers / Tours'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductEditPage()));
              },
            ),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Compact products box',
            onPressed: () async {
              await HiveService.compactBox('products');
                if (!mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Products box compacted')));
                });
            },
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_off),
            tooltip: 'Test wrong key',
            onPressed: () async {
              final wrong = HiveService.generateNewKey(); //для генерации случайного неверного ключа
              final result = await HiveService.tryOpenWithKey(wrong);
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Wrong key test'), content: Text(result)));
              });
            },
          ),
        ],
      ),
      body: ValueListenableBuilder( //уведомляет слушателей при изменениях в box
        valueListenable: productsBox.listenable(),
        builder: (context, Box box, _) {
          final keys = box.keys.cast<String>().toList();
          if (keys.isEmpty) return const Center(child: Text('No offers yet'));
          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final Product p = box.get(key) as Product;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: p.id))),
                  leading: p.imagePath.isNotEmpty ? Image.asset(p.imagePath, width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.photo),
                  title: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${p.location} • ${p.price.toStringAsFixed(2)} USD'),
                  trailing: (canEdit) //если пользователь имеет права, то показывает на карточке кнопки редактирования и удаления
                      ? PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditPage(productId: p.id)));
                            } else if (v == 'delete') {
                              await box.delete(p.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: Icon(p.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                            onPressed: () async {
                              // логика переключения избранных
                              final appBox = Hive.box('app');
                              final favBox = Hive.box('favorites');
                              final current = appBox.get('currentUserId') as String?;
                              if (current == null) return;
                              final existingKey = favBox.keys.cast<dynamic>().firstWhere(
                                (k) {
                                  final f = favBox.get(k) as dynamic;
                                  return f.userId == current && f.productId == p.id;
                                },
                                orElse: () => null,
                              );
                              if (existingKey != null) {
                                await favBox.delete(existingKey);
                                p.isLiked = false;
                                await productsBox.put(p.id, p);
                              } else {
                                await favBox.add(Favorite(userId: current, productId: p.id));
                                p.isLiked = true;
                                await productsBox.put(p.id, p);
                              }
                              setState(() {});
                            },
                          ),
                        ],),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
