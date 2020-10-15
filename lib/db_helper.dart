import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:train_reminder/main_page.dart';

class DBHelper {
  Future<Database> database;

  Future<void> init() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'train_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT, datetime TEXT, carriage TEXT, seat TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<int> insert(Info info) async {
    Map map = info.toMap();
    final Database db = await database;
    int id = await db.rawInsert(
        'INSERT INTO records(datetime, carriage, seat) VALUES(?, ?, ?)',
        [map['datetime'], map['carriage'], map['seat']]);
    return id;
  }

  Future<List<Info>> queryAll() async {
    final Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('records');
    return List.generate(maps.length, (i) {
      return Info(
          id: maps[i]['id'],
          datetime: DateTime.tryParse(
            maps[i]['datetime'],
          ),
          seat: maps[i]['seat'],
          carriage: maps[i]['carriage']);
    });
  }

  Future<int> update(Info info) async {
    final Database db = await database;

    return await db
        .update('records', info.toMap(), where: 'id = ?', whereArgs: [info.id]);
  }

  Future<void> delete(int id) async {
    final Database db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }
}
