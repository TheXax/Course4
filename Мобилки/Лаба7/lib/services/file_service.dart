import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/film.dart';
import 'package:flutter/foundation.dart';

//это отдельная топ-левел функция, чтобы её можно было передать в compute()
Future<void> _saveFilmIsolate(Map<String, dynamic> args) async { //получаем аргументы
  final filmMap = args['film'] as Map<String, dynamic>;
  final dirPath = args['dirPath'] as String;

  //создаём текстовый файл
  final file = File('$dirPath/${filmMap["title"]}.txt');
  final jsonString = jsonEncode(filmMap);
  await file.writeAsString(jsonString);
}

class FileService {
  Future<Directory?> _getDirectory(String type) async { //получение директории по типу
    switch (type) {
      case 'Temporary':
        return getTemporaryDirectory();
      case 'Application Support':
        return getApplicationSupportDirectory(); //поддерживающие данные приложения
      case 'Application Library':
        if (Platform.isIOS) {
          return getLibraryDirectory();
        } else {
          throw Exception('Application Library не поддерживается на Android');
        }
      case 'Application Documents':
        return getApplicationDocumentsDirectory(); //для пользовательских данных
      case 'Application Cache':
        return getApplicationCacheDirectory(); //внешние хранилища
      case 'External Storage':
        if (Platform.isAndroid) {
          return getExternalStorageDirectory(); //внешние хранилища
        } else {
          throw Exception('External Storage не поддерживается на iOS');
        }
      case 'External Cache Directories':
        if (Platform.isAndroid) {
          final dirs = await getExternalCacheDirectories();
          return dirs?.first;
        } else {
          throw Exception('External Cache Directories не поддерживается на iOS');
        }
      case 'External Storage Directories':
        if (Platform.isAndroid) {
          final dirs = await getExternalStorageDirectories();
          return dirs?.first;
        } else {
          throw Exception('External Storage Directories не поддерживается на iOS');
        }
      case 'Downloads':
        return getDownloadsDirectory();
      default:
        throw Exception('Неизвестный тип директории: $type');
    }
  }

  //сохранение фильма в файл
  Future<void> saveFilmToFile(Film film, String dirType) async {
    final dir = await _getDirectory(dirType);
    if (dir == null) throw Exception('Директория $dirType недоступна');

    await compute(_saveFilmIsolate, {
      'film': film.toMap(),
      'dirPath': dir.path,
    });
  }

  //чтение файла фильма
  Future<String> readFilmFromFile(String title, String dirType) async { //получаем директорию по типу
    final dir = await _getDirectory(dirType);
    if (dir == null) throw Exception('Директория $dirType недоступна');

    final file = File('${dir.path}/$title.txt');
    if (!file.existsSync()) return 'Файл не найден';
    return await file.readAsString();
  }

  //Импорт фильма из файла в БД
  Future<Film> importFilmFromFile(String filename, String dirType) async {
    final dir = await _getDirectory(dirType);
    if (dir == null) throw Exception('Директория $dirType недоступна');

    final file = File('${dir.path}/$filename');
    if (!file.existsSync()) {
      throw Exception('Файл не найден');
    }

    final content = await file.readAsString();
    final Map<String, dynamic> map = jsonDecode(content);
    return Film.fromMap(map);
  }

  //Получить список файлов в директории
  Future<List<FileSystemEntity>> listFiles(String dirType) async {
    final dir = await _getDirectory(dirType);
    if (dir == null) throw Exception('Директория $dirType недоступна');
    return dir.listSync();
  }

  List<String> get availableDirs => [ //доступные директории
    'Temporary', //
    'Application Support', //для служебных настроек, пользователь не видит её
    'Application Library', //внутренняя системная папка iOS
    'Application Documents', //пользовательска, можно увидеть на Android
    'Application Cache', //
    'External Storage', //нужны разрешения для Android
    'External Cache Directories', //внешний кэш. Android
    'External Storage Directories', //все внешние корневые папки. Android
    'Downloads', //
  ];
}