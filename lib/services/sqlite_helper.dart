
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../modal/modal.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();

  static Database? _db;

  DBHelper._init();

  Future<Database?> get databse async {
    if (_db != null) return _db;

    _db = await _initDB('docs.db');
    return _db;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
    CREATE TABLE $tableNotes(
    ${PDFFields.id} $idType,
    ${PDFFields.title} $textType,
    ${PDFFields.location} $textType,
    ${PDFFields.timeCreated} $textType
    )
    ''');
  }

  Future create(PDFItems pdf) async {
    final db = await instance.databse;

    return await db!.insert(tableNotes, pdf.toJson());
  }

  Future<List<PDFItems>> readAllPDFs() async {
    final db = await instance.databse;

    const orderBy = '${PDFFields.timeCreated} DESC';

    final result = await db!.query(tableNotes, orderBy: orderBy);

    return result.map((json) => PDFItems.fromJson(json)).toList();
  }

  Future<int> update(PDFItems pdfItems) async {
    final db = await instance.databse;

    return db!.update(tableNotes, pdfItems.toJson(),
        where: '${PDFFields.id} = ?', whereArgs: [pdfItems.id]);
  }

  Future<int> delete(int id) async {
    final db = await instance.databse;

    return db!
        .delete(tableNotes, where: '${PDFFields.id} = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.databse;
    _db = null;
    db!.close();
  }
}
