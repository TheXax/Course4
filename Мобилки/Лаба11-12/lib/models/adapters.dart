import 'package:hive/hive.dart';
import 'user.dart';
import 'product.dart';
import 'favorite.dart';
import 'cart.dart';
import 'history.dart';

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final role = reader.readString();
    final avatarPath = reader.readString();
    return User(id: id, name: name, role: role, avatarPath: avatarPath);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
    writer.writeString(obj.avatarPath);
  }
}

class FlightAdapter extends TypeAdapter<Flight> {
  @override
  final int typeId = 1;

  @override
  Flight read(BinaryReader reader) {
    final id = reader.readString();
    final flightNumber = reader.readString();
    final departureCity = reader.readString();
    final arrivalCity = reader.readString();
    final departureTime = reader.readString();
    final arrivalTime = reader.readString();
    final price = reader.readDouble();
    final availableSeats = reader.readInt();
    final airline = reader.readString();
    final isLiked = reader.readBool();

    return Flight(
      id: id,
      flightNumber: flightNumber,
      departureCity: departureCity,
      arrivalCity: arrivalCity,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      price: price,
      availableSeats: availableSeats,
      airline: airline,
      isLiked: isLiked,
    );
  }

  @override
  void write(BinaryWriter writer, Flight obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.flightNumber);
    writer.writeString(obj.departureCity);
    writer.writeString(obj.arrivalCity);
    writer.writeString(obj.departureTime);
    writer.writeString(obj.arrivalTime);
    writer.writeDouble(obj.price);
    writer.writeInt(obj.availableSeats);
    writer.writeString(obj.airline);
    writer.writeBool(obj.isLiked);
  }
}

class FavoriteAdapter extends TypeAdapter<Favorite> {
  @override
  final int typeId = 2;

  @override
  Favorite read(BinaryReader reader) {
    final productId = reader.readString();
    final productName = reader.readString();
    return Favorite(productId: productId, productName: productName);
  }

  @override
  void write(BinaryWriter writer, Favorite obj) {
    writer.writeString(obj.productId);
    writer.writeString(obj.productName);
  }
}

class CartAdapter extends TypeAdapter<Cart> {
  @override
  final int typeId = 3;

  @override
  Cart read(BinaryReader reader) {
    final productId = reader.readString();
    final productName = reader.readString();
    final price = reader.readDouble();
    final quantity = reader.readInt();
    return Cart(productId: productId, productName: productName, price: price, quantity: quantity);
  }

  @override
  void write(BinaryWriter writer, Cart obj) {
    writer.writeString(obj.productId);
    writer.writeString(obj.productName);
    writer.writeDouble(obj.price);
    writer.writeInt(obj.quantity);
  }
}

class HistoryAdapter extends TypeAdapter<History> {
  @override
  final int typeId = 4;

  @override
  History read(BinaryReader reader) {
    final productId = reader.readString();
    final productName = reader.readString();
    final price = reader.readDouble();
    final quantity = reader.readInt();
    final dateMillis = reader.readInt();
    return History(
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity,
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(dateMillis),
    );
  }

  @override
  void write(BinaryWriter writer, History obj) {
    writer.writeString(obj.productId);
    writer.writeString(obj.productName);
    writer.writeDouble(obj.price);
    writer.writeInt(obj.quantity);
    writer.writeInt(obj.purchaseDate.millisecondsSinceEpoch);
  }
}

void registerAdapters() {
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(FlightAdapter());
  Hive.registerAdapter(FavoriteAdapter());
  Hive.registerAdapter(CartAdapter());
  Hive.registerAdapter(HistoryAdapter());
}
