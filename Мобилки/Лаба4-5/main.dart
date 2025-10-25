import 'package:flutter/material.dart';

void main() {
  runApp(const TravelApp()); //запускает Flutter-приложение
}

//корневой виджет TravelApp
class TravelApp extends StatelessWidget {
  const TravelApp({super.key}); //передаёт ключ в класс

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Travel App",
      theme: ThemeData( //тема приложения
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[200], // фон темнее
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false, //убирает баннер «debug» при запуске в режиме отладки
      home: const SearchScreen(), //стартовый экран приложения
    );
  }
}

/// ----------------- ЭКРАН 1: Поиск -----------------
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( //базовая структура экрана
      body: SafeArea( //отступы
        child: Column( //вертикальный стек
          children: [
            // Верхний синий блок
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF3E4EB8),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: const Center(
                child: Icon(Icons.directions_car,
                    color: Colors.white, size: 100),
              ),
            ),

            const SizedBox(height: 16), //просто отступ

            Padding( //создание внутреннего поля
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Card( //верхняя часть формы
                  color: const Color(0xFF3E4EB8),
                  elevation: 4, //тень
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Column(
                      children: [
                        // One way / Round trip
                        Row(
                          children: [
                            Expanded( //чтобы поделить ширину поровну
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                    child: Text("One Way",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: const Center(
                                    child: Text("Round Trip",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        //это приватный метод (ниже) который строит строку с иконкой и текстом
                        _buildInputRow(Icons.flight_takeoff, "From",
                            "Rome, Italy", Colors.white, Colors.white),

                        const SizedBox(height: 8),
                        Row( //визуальное переключение From/To
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.swap_vert,
                                color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildInputRow(Icons.flight_land, "To",
                            "Florence, Italy", Colors.white, Colors.white),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                //Date и Passengers
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: _buildInputRow(
                        Icons.calendar_today, "Date", "Friday, 10 Sep"),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: _buildInputRow(Icons.people, "Passengers",
                        "Adult 02 : child 03"),
                  ),
                ),

                const SizedBox(height: 20),

                //кнопка Search
                ElevatedButton( //при нажатии выполняет навигацию
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResultsScreen()), //открывает экран ResultsScreen
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Search",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )
              ]),
            ),

            const Spacer(), //отталкивает нижний бар к низу экрана

            // Bottom nav bar
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8), //фиксированная стилистика
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 6)
                ],
              ),
              child: Row( //строка с иконками
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.search, size: 28, color: Colors.indigo),
                  Icon(Icons.bookmark_border,
                      size: 28, color: Colors.grey),
                  Icon(Icons.person_outline,
                      size: 28, color: Colors.grey),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  //метод-строитель строки
  Widget _buildInputRow(
      IconData icon,
      String label,
      String value, [
        Color? textColor,
        Color? iconColor,
      ]) {
    return Row(children: [
      Icon(icon, color: iconColor ?? Colors.indigo, size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.black54,
                ),
              ),
            ]),
      )
    ]);
  }
}

/// ----------------- ЭКРАН 2: Результаты -----------------
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( //используется стек, чтобы список «наезжал» на header
      body: Stack(
        children: [
          // Синий header
          Container(
            height: 300,
            padding: const EdgeInsets.only(
                top: 60, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF3E4EB8),
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context), //вызов, чтобы при нажатии возвращало на предыдущий экран
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Rome, Italy → Florence, Italy",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Fri, 20 Sep",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Row( //строка с иконками
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Icon(Icons.directions_bus,
                        color: Colors.white, size: 28),
                    Icon(Icons.directions_car,
                        color: Colors.white70, size: 28),
                    Icon(Icons.train, color: Colors.white70, size: 28),
                    Icon(Icons.flight, color: Colors.white70, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Sorted by Cheapest",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Icon(Icons.filter_list, color: Colors.white, size: 26),
                  ],
                ),
              ],
            ),
          ),

          // Список билетов со сдвигом вверх (наезжает на header)
          Transform.translate(
            offset: const Offset(0, 220), // регулируй это значение
            child: ListView( //карточки
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTicketCard(
                  company: "Eurolines",
                  price: "\$122",
                  timeFrom: "18:30",
                  duration: "0h 35m",
                  timeTo: "19:25",
                  from:
                  "Rome Leonardo da Vinci\nFiumicino Airport (FCO)",
                  to: "Florence Peretola Airport (FLR)",
                ),
                _buildTicketCard(
                  company: "Eurolines",
                  price: "\$122",
                  timeFrom: "12:30",
                  duration: "1h 42m",
                  timeTo: "18:29",
                  from: "Beijing Capital\nInternational Airport",
                  to: "Al Ghaidah International",
                ),
                _buildTicketCard(
                  company: "Eurolines",
                  price: "\$122",
                  timeFrom: "07:10",
                  duration: "3h 12m",
                  timeTo: "10:33",
                  from: "Dubai International Airport",
                  to: "Hartsfield Atlanta International",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard({
    required String company,
    required String price,
    required String timeFrom,
    required String duration,
    required String timeTo,
    required String from,
    required String to,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // верх карточки с ценой
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(company,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(price,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo)),
              ],
            ),
            const SizedBox(height: 6),
            const Text("Cheapest & Fastest",
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row( //время отправления
              children: [
                Text(timeFrom,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(duration, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(timeTo,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Row( //точки полёта
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(from,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward,
                    size: 18, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(to,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
