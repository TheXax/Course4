import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/favorite.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId; //final значит — неизменяемое после создания виджета
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState(); //возвращает приватный класс состояния
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Box productsBox;
  late Box favBox;
  late Box appBox;
  Product? product;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    productsBox = Hive.box('products'); //получает уже открытый box
    favBox = Hive.box('favorites');
    appBox = Hive.box('app');
    currentUserId = appBox.get('currentUserId') as String?;
    product = productsBox.get(widget.productId) as Product?;
  }

  bool isFavorited() { //проверяет находится ли продукт в избранном
    if (currentUserId == null) return false;
    return favBox.values.cast<Favorite>().any((f) => f.userId == currentUserId && f.productId == widget.productId);
  }

  Future<void> toggleFavorite() async { //меняет состояние на избранное/не избранное
    if (currentUserId == null) return;
    final existingKey = favBox.keys.cast<dynamic>().firstWhere( //firstWhere перебирает ключи и для каждого k берёт favBox.get(k) и проверяет поля
      (k) {
        final f = favBox.get(k) as Favorite; //получаем значчение и приводим к Favorite
        return f.userId == currentUserId && f.productId == widget.productId;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      await favBox.delete(existingKey); //удаляем запись из избранного
      product?.isLiked = false;
      await productsBox.put(product!.id, product); //сохраняем обновление
    } else { //если записи нет
      final fav = Favorite(userId: currentUserId!, productId: widget.productId); //создаём новый объект
      await favBox.add(fav);
      product?.isLiked = true;
      await productsBox.put(product!.id, product);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) return Scaffold(body: const Center(child: Text('Not found')));
    return Scaffold(
      appBar: AppBar(title: const Text('Offer details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (product!.imagePath.isNotEmpty)
            Image.asset(product!.imagePath, width: double.infinity, height: 200, fit: BoxFit.cover)
          else
            Container(height: 200, color: Colors.grey[300], child: const Center(child: Icon(Icons.photo, size: 64))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(product!.description, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(
              icon: Icon(isFavorited() || product!.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              onPressed: () async {
                await toggleFavorite();
              },
            )
          ]),
          const SizedBox(height: 8),
          Text('Location: ${product!.location}'),
          const SizedBox(height: 4),
          Text('Price: ${product!.price.toStringAsFixed(2)} USD'),
          const SizedBox(height: 4),
          Text('Reviews: ${product!.reviewsCount}'),
          const SizedBox(height: 12),
          Text(product!.description),
        ]),
      ),
    );
  }
}
