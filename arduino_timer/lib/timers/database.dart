import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:arduino_timer/timers/timer.dart';

class Database {
  Future<sqflite.Database?>? _database;
  static const _tableName = 'timers';
  static final instance = Database._internal();

  Database._internal();

  Future<void> init() async {
    // Open the database and store the reference.
    _database = sqflite.openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await sqflite.getDatabasesPath(), 'timers_database.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE $_tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, beginHour INTEGER, beginMinute INTEGER, endHour INTEGER, endMinute INTEGER, pin INTEGER, pinValue INTEGER, isActive INTEGER)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  Future<void> insertTimer(Timer timer) async {
    final db = await _database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db?.insert(
      _tableName,
      timer.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTimer(Timer timer) async {
    final db = await _database;

    // Update the given Dog.
    await db?.update(
      _tableName,
      timer.toMap(),
      // Ensure that the Dog has a matching id.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [timer.id],
    );
  }

  Future<void> deleteTimer(int id) async {
    final db = await _database;

    await db?.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Timer>> getAllTimers() async {
    final db = await _database;

    final List<Map<String, dynamic>>? maps = await db?.query(_tableName);

    if (maps != null) {
      return List.generate(maps.length, (i) {
        return Timer.fromMap(maps[i]);
      });
    } else {
      return [];
    }
  }
}
