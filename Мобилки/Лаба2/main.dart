// Лабораторная №2: Hobbies

// ----------------- Интерфейс -----------------
abstract interface class IHobby {
  void start();
  void stop();
}

// ----------------- Абстрактный класс -----------------
abstract class Hobby implements IHobby {
  String name;
  int duration;

  Hobby(this.name, this.duration);

  Hobby.short(this.name) : duration = 30;

  int get hobbyDuration => duration;

  set hobbyDuration(int value) {
    if (value > 0) {
      duration = value;
    }
  }

  void enjoy();

  static int hobbyCount = 0;

  static void printTotalHobbies() {
    print("Всего создано хобби: $hobbyCount");
  }
}

// ----------------- Классы -----------------
class Reading extends Hobby {
  String genre;

  Reading(String name, int duration, this.genre) : super(name, duration) {
    Hobby.hobbyCount++;
  }

  Reading.short(String name, this.genre) : super.short(name) {
    Hobby.hobbyCount++;
  }

  @override
  void enjoy() {
    print("Читаю книгу в жанре $genre...");
  }

  @override
  void start() => print("Начал читать $name");
  @override
  void stop() => print("Закончил читать $name");
}

class Gaming extends Hobby {
  String platform;

  Gaming(String name, int duration, this.platform) : super(name, duration) {
    Hobby.hobbyCount++;
  }

  @override
  void enjoy() {
    print("Играю на $platform в $name...");
  }

  @override
  void start() => print("Запустил игру $name");
  @override
  void stop() => print("Выключил игру $name");
}

class Painting extends Hobby {
  String style;

  Painting(String name, int duration, this.style) : super(name, duration) {
    Hobby.hobbyCount++;
  }

  @override
  void enjoy() {
    print("Рисую в стиле $style...");
  }

  @override
  void start() => print("Начал рисовать $name");
  @override
  void stop() => print("Закончил рисовать $name");
}


void describeHobby(Hobby hobby, [String mood = "спокойном"]) {
  print("Занимаюсь хобби '${hobby.name}' в $mood настроении.");
}

void scheduleHobby(Hobby hobby, {required String day, int hour = 18}) {
  print("Запланировано '${hobby.name}' на $day в $hour:00.");
}

void doWithHobby(Hobby hobby, Function action) {
  print("Делаю действие с хобби: ${hobby.name}");
  action();
}

void main() {
  try {
    var reading = Reading("Властелин колец", 120, "Фэнтези");
    var gaming = Gaming("The Witcher 3", 180, "PC");
    var painting = Painting("Пейзаж", 60, "Акварель");

    reading.start();
    reading.enjoy();
    reading.stop();

    gaming.start();
    gaming.enjoy();
    gaming.stop();

    painting.start();
    painting.enjoy();
    painting.stop();

    print("Продолжительность чтения: ${reading.hobbyDuration} мин.");
    reading.hobbyDuration = 200;
    print("Новая продолжительность: ${reading.hobbyDuration} мин.");

    Hobby.printTotalHobbies();

    describeHobby(gaming);
    scheduleHobby(painting, day: "Суббота");
    doWithHobby(reading, () => print("Дочитал до конца!"));

    List<Hobby> hobbies = [reading, gaming, painting];
    Set<String> uniqueNames = hobbies.map((h) => h.name).toSet();
    Map<String, int> hobbyDurations =
    {for (var h in hobbies) h.name: h.duration};

    print("Список хобби: ${hobbies.map((h) => h.name).toList()}");
    print("Уникальные названия: $uniqueNames");
    print("Длительности: $hobbyDurations");

    for (var h in hobbies) {
      if (h.duration < 70) {
        continue; // пропускаем короткие
      }
      print("Долгое хобби: ${h.name}");
      if (h.duration > 150) {
        print("Слишком долгое хобби, выходим из цикла!");
        break;
      }
    }

    reading.hobbyDuration = -10; // вызовет setter
  } catch (e) {
    print("Ошибка: $e");
  }
}
