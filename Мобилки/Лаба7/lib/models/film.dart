class Film {
  int? id;
  String title;
  String genre;
  int duration;
  String director;

  Film({ //именованный конструктор с параметрами
    this.id,
    required this.title, //required заставляет вызывать конструктор с этими полями; компилятор проверит, что они переданы
    required this.genre,
    required this.duration,
    required this.director,
  });

  //нужен для записи в SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'genre': genre,
      'duration': duration,
      'director': director,
    };
  }

  //для чтения данных из БД
  factory Film.fromMap(Map<String, dynamic> map) {
    return Film(
      id: map['id'],
      title: map['title'],
      genre: map['genre'],
      duration: map['duration'],
      director: map['director'],
    );
  }
}