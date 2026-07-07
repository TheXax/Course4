import User from "./User.js";
import Role from "./Role.js";
import Book from "./Book.js";
import Author from "./Author.js";
import Publisher from "./Publisher.js";
import Genre from "./Genre.js";
import BookGenre from "./BookGenre.js";
import Collection from "./Collection.js";
import CollectionBook from "./CollectionBook.js";

import Comment from "./Comment.js";
import Favorite from "./Favorite.js";
import ReadingProgress from "./ReadingProgress.js";
import Quote from "./Quote.js";
import Note from "./Note.js";
import Library from "./Library.js";
import Read from "./Read.js";
// USER — ROLE
Role.hasMany(User, { foreignKey: "role_id" });
User.belongsTo(Role, { foreignKey: "role_id" });

// USER — COLLECTION
User.hasMany(Collection, { foreignKey: "user_id", onDelete: 'CASCADE' });
Collection.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

// COLLECTION — BOOK (многие-ко-многим)
Book.belongsToMany(Collection, { through: CollectionBook, foreignKey: "book_id", onDelete: 'CASCADE' });
Collection.belongsToMany(Book, { through: CollectionBook, foreignKey: "collection_id", onDelete: 'CASCADE' });

// BOOK — AUTHOR (при удалении автора — book.author_id = NULL)
Author.hasMany(Book, { foreignKey: "author_id", onDelete: "SET NULL" });
Book.belongsTo(Author, { foreignKey: "author_id", onDelete: "SET NULL" });

// BOOK — PUBLISHER
Publisher.hasMany(Book, { foreignKey: "publisher_id", onDelete: "SET NULL" });
Book.belongsTo(Publisher, { foreignKey: "publisher_id", onDelete: "SET NULL" });

// BOOK — GENRE (многие-ко-многим)
Book.belongsToMany(Genre, { through: BookGenre, foreignKey: "book_id", otherKey: "genre_id", onDelete: 'CASCADE' });
Genre.belongsToMany(Book, { through: BookGenre, foreignKey: "genre_id", otherKey: "book_id", onDelete: 'CASCADE' });

// COMMENTS
User.hasMany(Comment, { foreignKey: "user_id", onDelete: 'CASCADE' });
Comment.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(Comment, { foreignKey: "book_id", onDelete: 'CASCADE' });
Comment.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

Comment.hasMany(Comment, { as: 'Replies', foreignKey: 'parent_id', onDelete: 'CASCADE' });
Comment.belongsTo(Comment, { as: 'Parent', foreignKey: 'parent_id', onDelete: 'CASCADE' });

// FAVORITES
User.hasMany(Favorite, { foreignKey: "user_id", as: "favorites", onDelete: 'CASCADE' });
Favorite.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(Favorite, { foreignKey: "book_id", as: "favorites", onDelete: 'CASCADE' });
Favorite.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

// READING PROGRESS
User.hasMany(ReadingProgress, { foreignKey: "user_id", onDelete: 'CASCADE' });
ReadingProgress.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(ReadingProgress, { foreignKey: "book_id", onDelete: 'CASCADE' });
ReadingProgress.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

// LIBRARY
User.hasMany(Library, { foreignKey: "user_id", onDelete: 'CASCADE' });
Library.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(Library, { foreignKey: "book_id", onDelete: 'CASCADE' });
Library.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

// READ
User.hasMany(Read, { foreignKey: "user_id", onDelete: 'CASCADE' });
Read.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(Read, { foreignKey: "book_id", onDelete: 'CASCADE' });
Read.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

// QUOTES
User.hasMany(Quote, { foreignKey: "user_id", onDelete: 'CASCADE' });
Quote.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(Quote, { foreignKey: "book_id", onDelete: 'CASCADE' });
Quote.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

// NOTES
User.hasMany(Note, { foreignKey: "user_id", onDelete: 'CASCADE' });
Note.belongsTo(User, { foreignKey: "user_id", onDelete: 'CASCADE' });

Book.hasMany(Note, { foreignKey: "book_id", onDelete: 'CASCADE' });
Note.belongsTo(Book, { foreignKey: "book_id", onDelete: 'CASCADE' });

export {
  User, Role, Book, Author, Publisher, Genre,
  Collection, CollectionBook, Comment, Favorite, BookGenre
};

console.log('Associations set');