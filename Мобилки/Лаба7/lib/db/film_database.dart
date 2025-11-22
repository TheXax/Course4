import 'package:sqflite/sqflite.dart'; //плагин SQLite
import 'package:path/path.dart'; //библиотека для работы с путями и файлами
import '../models/film.dart'; //модель данных

class FilmDatabase {
  static final FilmDatabase instance = FilmDatabase._init(); //один экземпляр БД на всё приложение
  static Database? _database;

  FilmDatabase._init(); //приватный конструктор (вызов только внутри класса)

  Future<Database> get database async { //если база открыта, то возвращаем. Если нет, то создаём файл БД и открываем
    if (_database != null) return _database!;
    _database = await _initDB('films.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); //полкучаем путь к БД
    final path = join(dbPath, filePath); //формирование путя к файлу

    return await openDatabase( //если файла нет, то создаём
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  //выполняется только один раз, при первом запуске
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE films (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      genre TEXT NOT NULL,
      duration INTEGER NOT NULL,
      director TEXT NOT NULL
    )
    ''');
  }

  //сортировка по длительности, иначе по названию фильма
  Future<List<Film>> getFilms({String? search, bool sortByDuration = false}) async {
    final db = await instance.database;
    final maps = await db.query(
      'films',
      where: search != null && search.isNotEmpty ? 'title LIKE ?' : null,
      whereArgs: search != null && search.isNotEmpty ? ['%$search%'] : null,
      orderBy: sortByDuration ? 'duration DESC' : 'title ASC',
    );

    return maps.map((e) => Film.fromMap(e)).toList(); //преобразование Map в объект Film
  }

  Future<int> addFilm(Film film) async {
    final db = await instance.database;
    return db.insert('films', film.toMap());
  }

  Future<int> updateFilm(Film film) async {
    final db = await instance.database;
    return db.update(
      'films',
      film.toMap(),
      where: 'id = ?',
      whereArgs: [film.id],
    );
  }

  Future<int> deleteFilm(int id) async {
    final db = await instance.database;
    return db.delete('films', where: 'id = ?', whereArgs: [id]);
  }
}