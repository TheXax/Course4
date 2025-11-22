import 'package:flutter/material.dart';
import '../models/film.dart';

class FilmTile extends StatelessWidget {
  final Film film;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FilmTile({
    Key? key,
    required this.film,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.movie, color: Colors.indigo),
      title: Text(
        film.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${film.genre} • ${film.duration} мин\nРежиссёр: ${film.director}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
      onTap: onTap, //нажатие на сам элемент
    );
  }
}