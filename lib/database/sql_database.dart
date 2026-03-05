import 'package:magtapp/support/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDatabase {
  late String database, path;
  late int type;

  Database? db;

  SqlDatabase({required this.database});
  

  void getDatabasePath() async {
    print("getting path");
    var databasesPath = await getDatabasesPath();
    path = join(databasesPath, database);
    createDatabase();
    // print(path);
    // createHistoryDatabase();
  }

  void deleteDatabases() async {
    await deleteDatabase(path);
  }

  void createDatabase() async {
    print("initializing");
    db = await openDatabase(
      readOnly: false,
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE tbl_history (id INTEGER PRIMARY KEY, url TEXT, timestamp BIGINT)",
        );

        await db.execute(
          "CREATE TABLE tbl_downloads (id INTEGER PRIMARY KEY, path TEXT, timestamp BIGINT)",
        );

        await db.execute(
          "CREATE TABLE tbl_summary (id INTEGER PRIMARY KEY, url TEXT, title TEXT, summary TEXT, timestamp BIGINT)",
        );

        await db.execute(
          "CREATE TABLE tbl_pages (id INTEGER PRIMARY KEY, page TEXT, url TEXT, tab INTEGER)"
        );
      },
    );
  }

  void insertPage(String page, String url, int tab) async {

  }

  void insertHistory(String url) async {
    await db!.transaction((action) async {
      int id = await action.rawInsert(
        "INSERT INTO tbl_history (url, timestamp) VALUES (?, ?)",
        [url, DateTime.now().millisecondsSinceEpoch],
      );
      print(id);
    });
  }

  void insertDownload(String path) async {
    await db!.transaction((action) async {
      await action.rawInsert(
        "INSERT INTO tbl_download (path, timestamp) VALUES (?, ?)",
        [path, DateTime.now().millisecondsSinceEpoch],
      );
    });
  }

  void insertSummary(String url, String title, String summary) async {
    await db!.transaction((action) async {
      await action.rawInsert(
        "INSERT INTO tbl_summary (url, title, summary) VALUES (?, ?, ?)",
        [url, title, summary],
      );
    });
  }

  Future<List<Map>> getAllHistory() async {
    if (db == null) {
      createDatabase();
      List<Map> list = await db!.rawQuery("SELECT * FROM tbl_history");
      return list;
    } else {
      List<Map> list = await db!.rawQuery("SELECT * FROM tbl_history");
      return list;
    }
  }

  Future<List<Map>> getAllSummary() async {
    List<Map> list = await db!.rawQuery("SELECT * FROM tbl_summary");
    return list;
  }

  void deleteHistory(int id) async {
    await db!.rawDelete("DELETE FROM tbl_history WHERE id=$id");
  }

  void deleteSummary(int id) async {
    await db!.rawDelete("DELETE FROM tbl_summary WHERE id=$id");
  }

  void deleteAllHistory() async {
    await db!.rawDelete("DELETE FROM tbl_history");
  }
}
