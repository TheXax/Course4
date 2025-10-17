import 'dart:async';
import 'dart:collection';
import 'dart:convert';

mixin Describable {
  String describe() => "Описание объекта";
}

class Hobby with Describable implements Comparable<Hobby> {
  final String name;
  final int level; // 1–10

  Hobby(this.name, this.level);

  @override
  int compareTo(Hobby other) => level.compareTo(other.level);

  Map<String, dynamic> toJson() => {
    'name': name,
    'level': level,
  };

  factory Hobby.fromJson(Map<String, dynamic> json) =>
      Hobby(json['name'], json['level']);

  @override
  String toString() => "$name (уровень $level)";
}

class HobbiesIterator implements Iterator<Hobby> {
  final List<Hobby> _items;

  int _index = -1;

  HobbiesIterator(this._items);

  @override
  Hobby get current =>
      (_index >= 0 && _index < _items.length) ? _items[_index] : null as Hobby;

  @override
  bool moveNext() {
    if (_index + 1 < _items.length) {
      _index++;
      return true;
    }
    return false;
  }
}

class HobbiesCollection extends IterableBase<Hobby> {
  final List<Hobby> _items;
  HobbiesCollection(this._items);

  @override
  Iterator<Hobby> get iterator => HobbiesIterator(_items);

  void add(Hobby h) => _items.add(h);

  @override
  int get length => _items.length;
}

Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return "Данные успешно загружены!";
}

Stream<int> numberStream() async* {
  for (int i = 1; i <= 5; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    yield i;
  }
}

void main() async {
  var h1 = Hobby("Игра на гитаре", 5);
  var h2 = Hobby("Футбол", 8);

  print("=== MIXIN + Comparable ===");
  print(h1.describe());
  print("Сравнение: ${h1.compareTo(h2)}");

  print("\n=== Iterable + Iterator ===");

  var hobbies = HobbiesCollection([h1, h2, Hobby("Шахматы", 3)]);

  for (var h in hobbies) {
    print(h);
  }

  print("\n=== JSON сериализация ===");

  var jsonStr = jsonEncode(h1.toJson());
  print("В JSON: $jsonStr");

  var fromJson = Hobby.fromJson(jsonDecode(jsonStr));
  print("Из JSON: $fromJson");

  print("\n=== Future ===");

  var data = await fetchData();
  print(data);

  print("\n=== Stream (Single subscription) ===");

  await for (var n in numberStream()) {
    print("Получено число: $n");
  }

  print("\n=== BroadcastStream ===");

  var controller = StreamController<String>.broadcast();

  controller.stream.listen((event) {
    print("Подписчик 1: $event");
  });

  controller.stream.listen((event) {
    print("Подписчик 2: $event");
  });

  controller.add("Событие А");
  controller.add("Событие B");

  await controller.close();
}