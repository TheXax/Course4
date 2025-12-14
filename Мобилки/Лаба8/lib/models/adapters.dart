//файл содержит адаптеры для Hive — классы, которые говорят Hive, как сериализовать (записать) и десериализовать (прочитать) пользовательские объекты (User, Product, Favorite, Cart, History) в/из бинарного формата. Hive хранит объекты компактно в файлах; TypeAdapter — мост между твоими моделями и бинарным представлением.
import 'package:hive/hive.dart';
import 'user.dart';
import 'product.dart';
import 'favorite.dart';
import 'cart.dart';
import 'history.dart';

class UserAdapter extends TypeAdapter<User> { //наследует TypeAdapter<User>, значит умеет (де)сериализовать объекты User
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) { //метод, который Hive вызывает, чтобы создать объект User из бинарных данных
    final id = reader.readString();
    final name = reader.readString();
    final role = reader.readString();
    final avatarPath = reader.readString();
    return User(id: id, name: name, role: role, avatarPath: avatarPath);
  }

  @override
  void write(BinaryWriter writer, User obj) { //метод, который Hive вызывает, когда нужно записать объект User в файл
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
    writer.writeString(obj.avatarPath);
  }
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 1;

  @override
  Product read(BinaryReader reader) {
    final id = reader.readString();
    final imagePath = reader.readString();
    final price = reader.readDouble();
    final location = reader.readString();
    final reviewsCount = reader.readInt();
    final description = reader.readString();
    final isLiked = reader.readBool();
    return Product(
      id: id,
      imagePath: imagePath,
      price: price,
      location: location,
      reviewsCount: reviewsCount,
      description: description,
      isLiked: isLiked,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.imagePath);
    writer.writeDouble(obj.price);
    writer.writeString(obj.location);
    writer.writeInt(obj.reviewsCount);
    writer.writeString(obj.description);
    writer.writeBool(obj.isLiked);
  }
}

class FavoriteAdapter extends TypeAdapter<Favorite> {
  @override
  final int typeId = 2;

  @override
  Favorite read(BinaryReader reader) {
    final userId = reader.readString();
    final productId = reader.readString();
    return Favorite(userId: userId, productId: productId);
  }

  @override
  void write(BinaryWriter writer, Favorite obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.productId);
  }
}

class CartAdapter extends TypeAdapter<Cart> {
  @override
  final int typeId = 3;

  @override
  Cart read(BinaryReader reader) {
    final userId = reader.readString();
    final productId = reader.readString();
    final quantity = reader.readInt();
    return Cart(userId: userId, productId: productId, quantity: quantity);
  }

  @override
  void write(BinaryWriter writer, Cart obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.productId);
    writer.writeInt(obj.quantity);
  }
}

class HistoryAdapter extends TypeAdapter<History> {
  @override
  final int typeId = 4;

  @override
  History read(BinaryReader reader) {
    final userId = reader.readString();
    final query = reader.readString();
    final dateMillis = reader.readInt();
    return History(userId: userId, query: query, date: DateTime.fromMillisecondsSinceEpoch(dateMillis));
  }

  @override
  void write(BinaryWriter writer, History obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.query);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
  }
}

void registerAdapters() {
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(FavoriteAdapter());
  Hive.registerAdapter(CartAdapter());
  Hive.registerAdapter(HistoryAdapter());
}
