import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../db/film_database.dart';
import '../models/film.dart';

class FilePage extends StatefulWidget { //изменяемое состояние
  @override
  _FilePageState createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  final _fileService = FileService(); //через данный экземпляр работаем с файлами
  String _selectedDir = 'Temporary'; //текущая выбранная папка
  List<String> _files = []; //список отображаемых файлов

  Future<void> _loadFiles() async {
    try {
      final files = await _fileService.listFiles(_selectedDir); //попытка получения списка файлов в выбранной папке
      setState(() {
        _files = files.map((f) => f.path.split('/').last).toList(); //преобразование пути в название файла
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  //вызывается при нажатии на файл
  Future<void> _readFile(String filename) async {
    final content = await _fileService.readFilmFromFile(
      filename.replaceAll('.txt', ''),
      _selectedDir,
    );
    showDialog( //всплывающее окно с содержимым
      context: context,
      builder: (_) => AlertDialog(
        title: Text(filename),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  //импорт из файла в БД
  Future<void> _importToDB(String filename) async {
    try {
      final film = await _fileService.importFilmFromFile(filename, _selectedDir); //читаем из файла и получаем объект Film
      await FilmDatabase.instance.addFilm(film); //добавляем в SQLite
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Фильм "${film.title}" успешно импортирован 📥')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Файлы')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8), //выпадающий список папок
            child: DropdownButton<String>(
              value: _selectedDir,
              items: _fileService.availableDirs
                  .map((dir) => DropdownMenuItem(value: dir, child: Text(dir)))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedDir = val!);
                _loadFiles();
              },
            ),
          ),
          Expanded( //чтение содержимого файла
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(file),
                  onTap: () => _readFile(file),
                  trailing: IconButton( //кнопка импорта в базу
                    icon: const Icon(Icons.download, color: Colors.green),
                    onPressed: () => _importToDB(file),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton( //кнопка обновления
        onPressed: _loadFiles,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}