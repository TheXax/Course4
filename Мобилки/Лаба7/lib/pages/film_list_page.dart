import 'package:flutter/material.dart';
import '../db/film_database.dart';
import '../models/film.dart';
import 'film_detail_page.dart';
import '../widgets/film_tile.dart';
import 'file_page.dart';

class FilmListPage extends StatefulWidget {
  @override
  _FilmListPageState createState() => _FilmListPageState();
}

class _FilmListPageState extends State<FilmListPage> {
  List<Film> _films = [];
  String _search = '';
  bool _sortByDuration = false; //название или длительность

  @override
  void initState() {
    super.initState();
    _loadFilms(); //Запускает загрузку фильмов из БД
  }

  //загрузка фильмов из SQLite
  Future<void> _loadFilms() async {
    final films = await FilmDatabase.instance.getFilms(
      search: _search,
      sortByDuration: _sortByDuration,
    );
    setState(() => _films = films);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильмы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FilePage()),
              );
            },
          ),
          //выбор сортировки
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortByDuration = value == 'duration';
              });
              _loadFilms();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'title',
                child: Text('Сортировать по названию'),
              ),
              const PopupMenuItem(
                value: 'duration',
                child: Text('Сортировать по длительности'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
          //кнопка добавления фильма
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push( //переход на экран добавления фильма
                context,
                MaterialPageRoute(builder: (_) => FilmDetailPage()),
              );
              _loadFilms();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding( //поле поиска
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _search = value;
                _loadFilms();
              },
            ),
          ),
          Expanded(
            child: ListView.builder( //список фильмов
              itemExtent: 80,
              itemCount: _films.length,
              itemBuilder: (context, index) {
                final film = _films[index];
                return FilmTile( //карточка фильма, при нажатии переходим к редактированию
                  film: film,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FilmDetailPage(film: film),
                      ),
                    );
                    _loadFilms();
                  },
                  onDelete: () async {
                    await FilmDatabase.instance.deleteFilm(film.id!);
                    _loadFilms();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}