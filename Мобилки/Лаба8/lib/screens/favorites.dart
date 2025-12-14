import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/favorite.dart';
import '../models/product.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState(); //возвращает экземпляр приватного состояния
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Box favBox; //late — отложенная инициализация
  late Box productsBox;
  late Box appBox;

  @override
  void initState() { //связываем поля с уже открытыми боксами
    super.initState();
    favBox = Hive.box('favorites');
    productsBox = Hive.box('products');
    appBox = Hive.box('app');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = appBox.get('currentUserId') as String?; //читаем из app бокса ключ 'currentUserId'. Получаем текущего пользователя
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ValueListenableBuilder( //виджет, который автоматически перестраивается, когда valueListenable уведомляет об изменении
        valueListenable: favBox.listenable(), //Listenable для бокса: когда в боксе что-то меняется, слушатели уведомляются
        builder: (context, Box box, _) {
          if (currentUserId == null) return const Center(child: Text('No user selected'));
          final favs = box.values.cast<Favorite>().where((f) => f.userId == currentUserId).toList(); //приводим эл-ты к типу Favorite и фильтруем по конкретному пользователю
          if (favs.isEmpty) return const Center(child: Text('No favorites'));
          return ListView.builder(
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final f = favs[index]; //получаем favorite в позиции индекса
              final p = productsBox.get(f.productId) as Product?; //ищем соответсвующий продукт по id
              return ListTile(
                leading: p != null && p.imagePath.isNotEmpty ? Image.asset(p.imagePath, width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.photo),
                title: Text(p?.description ?? f.productId),
                subtitle: Text(p != null ? '${p.location} • ${p.price.toStringAsFixed(2)}' : ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async { //удаление записи из бокса
                    final keyToDelete = box.keys.firstWhere((k) { //ищем ключ по которому лежит объект (значения в Hive хранятся по ключам)
                      final fav = box.get(k) as Favorite;
                      return fav.userId == f.userId && fav.productId == f.productId;
                    });
                    await box.delete(keyToDelete);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
