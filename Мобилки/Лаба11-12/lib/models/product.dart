import 'package:hive/hive.dart';

class Flight extends HiveObject {
  String id;
  String flightNumber;
  String departureCity;
  String arrivalCity;
  String departureTime;
  String arrivalTime;
  double price;
  int availableSeats;
  String airline;
  bool isLiked;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.airline,
    required this.isLiked,
  });

  // Вычисляемое свойство для отображения маршрута
  String get route => '$departureCity → $arrivalCity';

  // Вычисляемое свойство для длительности полета (упрощенное)
  String get duration {
    try {
      final depTime = int.parse(departureTime.split(':')[0]);
      final arrTime = int.parse(arrivalTime.split(':')[0]);
      final diff = (arrTime - depTime + 24) % 24;
      return '${diff}h';
    } catch (e) {
      return 'N/A';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flightNumber': flightNumber,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'price': price,
      'availableSeats': availableSeats,
      'airline': airline,
      'isLiked': isLiked,
    };
  }

  factory Flight.fromMap(Map<String, dynamic> map) {
    return Flight(
      id: map['id'] as String? ?? '',
      flightNumber: map['flightNumber'] as String? ?? '',
      departureCity: map['departureCity'] as String? ?? '',
      arrivalCity: map['arrivalCity'] as String? ?? '',
      departureTime: map['departureTime'] as String? ?? '',
      arrivalTime: map['arrivalTime'] as String? ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse('${map['price']}') ?? 0.0,
      availableSeats: map['availableSeats'] is int ? map['availableSeats'] as int : int.tryParse('${map['availableSeats']}') ?? 0,
      airline: map['airline'] as String? ?? '',
      isLiked: map['isLiked'] as bool? ?? false,
    );
  }
}
