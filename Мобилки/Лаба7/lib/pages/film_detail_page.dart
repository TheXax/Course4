import 'package:flutter/material.dart';
import '../models/film.dart';
import '../db/film_database.dart';
import '../services/file_service.dart';

class FilmDetailPage extends StatefulWidget {
  final Film? film; //если передан Film, значит мы редактируем существующую запись; если null — создаём новый фильм
  FilmDetailPage({this.film});

  @override
  _FilmDetailPageState createState() => _FilmDetailPageState();
}

class _FilmDetailPageState extends State<FilmDetailPage> { //поле для хранения логики и поля формы
  //контроллеры для управления текстовыми полями
  final _titleCtrl = TextEditingController();
  final _genreCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _directorCtrl = TextEditingController();
  final _fileService = FileService(); //экземпляр сервиса для сохранения/чтения файла

  String _selectedDir = 'Temporary'; //выбранная

  @override
  void initState() { //заполнение полей при редактировании
    super.initState(); //вызывается один раз при создании состояния
    if (widget.film != null) { //именно редактирование
      _titleCtrl.text = widget.film!.title;
      _genreCtrl.text = widget.film!.genre;
      _durationCtrl.text = widget.film!.duration.toString();
      _directorCtrl.text = widget.film!.director;
    }
  }

  //Сохранение в БД
  Future<void> _saveFilmToDB() async {
    final film = Film( //создаёт объект Film из значений контроллеров
      id: widget.film?.id,
      title: _titleCtrl.text,
      genre: _genreCtrl.text,
      duration: int.tryParse(_durationCtrl.text) ?? 0,
      director: _directorCtrl.text,
    );

    if (widget.film == null) {
      await FilmDatabase.instance.addFilm(film); //вставка новой записи в БД, иначе
    } else {
      await FilmDatabase.instance.updateFilm(film); //обновление
    }

    Navigator.pop(context);
  }
 //Сохранение в файл
  Future<void> _saveFilmToFile() async {
    try {
      final film = Film(
        id: widget.film?.id,
        title: _titleCtrl.text,
        genre: _genreCtrl.text,
        duration: int.tryParse(_durationCtrl.text) ?? 0,
        director: _directorCtrl.text,
      );
      await _fileService.saveFilmToFile(film, _selectedDir); //сервис сохраняет фильм в файл в выбранной папке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сохранено в $_selectedDir')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.film == null ? 'Добавить' : 'Редактировать'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Название')),
              TextField(controller: _genreCtrl, decoration: const InputDecoration(labelText: 'Жанр')),
              TextField(controller: _durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Длительность (мин)')),
              TextField(controller: _directorCtrl, decoration: const InputDecoration(labelText: 'Режиссёр')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFilmToDB,
                child: const Text('Сохранить в БД'),
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                value: _selectedDir,
                items: _fileService.availableDirs
                    .map((dir) => DropdownMenuItem(value: dir, child: Text(dir)))
                    .toList(), //список доступных директорий
                onChanged: (val) => setState(() => _selectedDir = val!),
              ),
              ElevatedButton(
                onPressed: _saveFilmToFile,
                child: const Text('Сохранить в файл'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}