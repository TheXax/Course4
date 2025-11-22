import 'package:flutter/material.dart';
import 'pages/film_list_page.dart'; //импорт файла со страницей со списком фильмов
import 'db/film_database.dart'; //испорт работы с бд

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FilmDatabase.instance.database; //инициализация подключения БД
  runApp(const MyApp());
}

class MyApp extends StatelessWidget { //не хранит внутреннее состояние
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Фильмы',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
      home: FilmListPage(),
    );
  }
}