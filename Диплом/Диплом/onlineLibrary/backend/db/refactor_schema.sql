-- 1. Ненужные поля пользователя
ALTER TABLE users
  DROP COLUMN IF EXISTS first_name,
  DROP COLUMN IF EXISTS last_name,
  DROP COLUMN IF EXISTS avatar_url,
  DROP COLUMN IF EXISTS bio;

-- 2. Ненужные поля книги
ALTER TABLE books
  DROP COLUMN IF EXISTS genre_id;

ALTER TABLE books
  RENAME COLUMN file_path TO book_file;

ALTER TABLE books
  ADD COLUMN IF NOT EXISTS isbn VARCHAR(20);

ALTER TABLE books
  ADD CONSTRAINT IF NOT EXISTS books_isbn_key UNIQUE (isbn);

-- 3. Неиспользуемое поле
ALTER TABLE authors
  DROP COLUMN IF EXISTS description;

-- 4. Неиспользуемое поле
ALTER TABLE publishers
  DROP COLUMN IF EXISTS country,
  DROP COLUMN IF EXISTS description;

-- 5. изменения внешнего ключа
ALTER TABLE collections
  ALTER COLUMN user_id SET NOT NULL;

ALTER TABLE collections
  ADD CONSTRAINT IF NOT EXISTS collections_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- 6. изменение заметок
ALTER TABLE notes
  ADD COLUMN IF NOT EXISTS selection_text TEXT,
  ADD COLUMN IF NOT EXISTS user_text TEXT;

-- миграция данных из текста в новые поля
UPDATE notes
SET selection_text = SPLIT_PART(text, E'\n\n', 1),
    user_text = CASE
      WHEN array_length(string_to_array(text, E'\n\n'), 1) > 1
      THEN array_to_string((string_to_array(text, E'\n\n'))[2:], E'\n\n')
      ELSE NULL
    END;

ALTER TABLE notes
  ALTER COLUMN selection_text SET NOT NULL;

ALTER TABLE notes
  DROP COLUMN IF EXISTS text;

-- 7. изменение цитат
ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS quote_text TEXT;

-- миграция данных
UPDATE quotes
SET quote_text = text;

ALTER TABLE quotes
  ALTER COLUMN quote_text SET NOT NULL;

ALTER TABLE quotes
  DROP COLUMN IF EXISTS text;
