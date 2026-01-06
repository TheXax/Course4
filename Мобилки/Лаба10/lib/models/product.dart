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
}
