// main.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Travel App",
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[200],
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      // роути для pushNamed
      routes: {
        '/pageview': (context) => const PageViewScreen(),
        '/platform': (context) => const PlatformScreen(),
      },
      home: const SearchScreen(),
    );
  }
}

/// ----------------- ЭКРАН 1: Поиск (твоя верстка сохранена) -----------------
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  // Значения, которые мы будем передавать в DetailScreen
  final String _fromValue = "Rome, Italy";
  final String _toValue = "Florence, Italy";
  final String _dateValue = "Friday, 10 Sep";
  final String _passengersValue = "Adult 02 : child 03";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                child: Icon(Icons.directions_car, color: Colors.white, size: 100),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Card(
                  color: const Color(0xFF3E4EB8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      children: [
                        // One way / Round trip
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text("One Way",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: const Center(
                                  child: Text("Round Trip",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // From
                        _buildInputRow(Icons.flight_takeoff, "From", _fromValue, Colors.white, Colors.white),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Icon(Icons.swap_vert, color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // To
                        _buildInputRow(Icons.flight_land, "To", _toValue, Colors.white, Colors.white),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: _buildInputRow(Icons.calendar_today, "Date", _dateValue),
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: _buildInputRow(Icons.people, "Passengers", _passengersValue),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ResultsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Search",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),

                const SizedBox(height: 8),

                // Кнопка "Details" — пример передачи данных с первой страницы в детальный экран (push с аргументами)
                OutlinedButton(
                  onPressed: () {
                    // Передаём данные (from/to/date/passengers) в DetailScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          from: _fromValue,
                          to: "123",
                          date: _dateValue,
                          passengers: _passengersValue,
                        ),
                      ),
                    );
                  },
                  child: const Text("Open Details (pass data)"),
                ),
              ]),
            ),

            const Spacer(),

            // Bottom nav bar (заменил иконки на навигационные действия — демонстрируем 3 метода Navigator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1) push -> ResultsScreen (уже есть)
                  IconButton(
                    icon: const Icon(Icons.search, size: 28, color: Colors.indigo),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
                    },
                  ),

                  // 2) pushNamed -> PageViewScreen (демонстрация именованного перехода)
                  IconButton(
                    icon: const Icon(Icons.slideshow, size: 28, color: Colors.grey),
                    onPressed: () {
                      Navigator.pushNamed(context, '/pageview');
                    },
                  ),

                  // 3) pushReplacement -> PlatformScreen (демонстрация pushReplacement)
                  IconButton(
                    icon: const Icon(Icons.phone_android, size: 28, color: Colors.grey),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/platform');
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(IconData icon, String label, String value, [Color? textColor, Color? iconColor]) {
    return Row(children: [
      Icon(icon, color: iconColor ?? Colors.indigo, size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? Colors.black54)),
        ]),
      )
    ]);
  }
}

/// ----------------- ЭКРАН: Детализация (передаем данные сюда) -----------------
class DetailScreen extends StatelessWidget {
  final String from;
  final String to;
  final String date;
  final String passengers;

  const DetailScreen({super.key, required this.from, required this.to, required this.date, required this.passengers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: $from', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('To: $to', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Date: $date', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Passengers: $passengers', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // пример pop
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------- ЭКРАН 2: Результаты (оставлена твоя верстка, не менял) -----------------
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Синий header
          Container(
            height: 300,
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(color: Color(0xFF3E4EB8), borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text("Rome, Italy → Florence, Italy", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Fri, 20 Sep", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ]),
                )
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
                Icon(Icons.directions_bus, color: Colors.white, size: 28),
                Icon(Icons.directions_car, color: Colors.white70, size: 28),
                Icon(Icons.train, color: Colors.white70, size: 28),
                Icon(Icons.flight, color: Colors.white70, size: 28),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                Text("Sorted by Cheapest", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Icon(Icons.filter_list, color: Colors.white, size: 26),
              ]),
            ]),
          ),

          // Список билетов со сдвигом вверх (наезжает на header)
          Transform.translate(
            offset: const Offset(0, 220),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTicketCard(
                  company: "Eurolines",
                  price: "\$122",
                  timeFrom: "18:30",
                  duration: "0h 35m",
                  timeTo: "19:25",
                  from: "Rome Leonardo da Vinci\nFiumicino Airport (FCO)",
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // верх карточки с ценой
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(company, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ]),
          const SizedBox(height: 6),
          const Text("Cheapest & Fastest", style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(children: [
            Text(timeFrom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(duration, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            Text(timeTo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(from, style: const TextStyle(fontSize: 13, color: Colors.black87))),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, size: 18, color: Colors.indigo),
            const SizedBox(width: 10),
            Expanded(child: Text(to, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          ])
        ]),
      ),
    );
  }
}

  /// ----------------- PageView screen -----------------
class PageViewScreen extends StatelessWidget {
  const PageViewScreen({super.key});

  final List<String> pages = const [
    "📖 Reading books improves knowledge",
    "🎸 Music relaxes the mind",
    "⚽ Sport keeps you healthy",
    "🎮 Gaming develops reaction",
    "✈️ Travel broadens horizons"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hobbies PageView")),
      body: PageView.builder(
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return Container(
            color: Colors.white,
            child: Center(
              child: Text(pages[index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}

/// ----------------- Platform screen: MethodChannel + camera -----------------
class PlatformScreen extends StatefulWidget {
  const PlatformScreen({super.key});

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  // канал для platform methods
  static const platform = MethodChannel('travel/platform');

  String _battery = 'Unknown';
  String _bluetooth = 'Unknown';
  File? _image;

  Future<void> _getBattery() async {
    try {
      final int level = await platform.invokeMethod('getBatteryLevel');
      setState(() => _battery = '$level%');
    } on PlatformException catch (e) {
      setState(() => _battery = 'Error: ${e.message}');
    } on MissingPluginException {
      setState(() => _battery = 'Platform implementation not found');
    }
  }

  Future<void> _getBluetooth() async {
    try {
      final String status = await platform.invokeMethod('getBluetoothStatus');
      setState(() => _bluetooth = status);
    } on PlatformException catch (e) {
      setState(() => _bluetooth = 'Error: ${e.message}');
    } on MissingPluginException {
      setState(() => _bluetooth = 'Platform implementation not found');
    }
  }

  Future<void> _openBrowser() async {
    try {
      await platform.invokeMethod('openBrowser', {'url': 'https://www.mixamo.com/#/?page=1&query=&type=Motion%2CMotionPack'});
    } on PlatformException catch (e) {
      debugPrint('Browser error: ${e.message}');
    } on MissingPluginException {
      debugPrint('Open browser: platform implementation not found');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      debugPrint('Image error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Methods & Camera')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          ElevatedButton(onPressed: _getBattery, child: const Text('Get Battery Level')),
          const SizedBox(height: 8),
          Text('Battery: $_battery', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _getBluetooth, child: const Text('Get Bluetooth Status')),
          const SizedBox(height: 8),
          Text('Bluetooth: $_bluetooth', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _openBrowser, child: const Text('Open Browser (flutter.dev)')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _takePhoto, child: const Text('Take Photo (camera)')),
          if (_image != null) ...[
            const SizedBox(height: 16),
            Image.file(_image!, height: 250, fit: BoxFit.cover),
          ],
        ]),
      ),
    );
  }
}
