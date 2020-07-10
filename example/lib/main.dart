import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_web/sqflite_web.dart';

Future main() async {
  var databaseFactory = databaseFactoryWeb;
  var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
  await db.setVersion(10);
  await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT
  )
  ''');

  final ok = await db.transaction<bool>((txn) async {
    await txn.insert('Product', <String, dynamic>{'title': 'Product 1'});
    await txn.insert('Product', <String, dynamic>{'title': 'Product 2'});
    await txn.rawInsert('INSERT INTO Product(title) VALUES(?)', ['Product 3']);
    return true;
  });

  if (ok) {
    var result = await db.query('Product');
    print(result); // [{columns: [id, title], rows: [[1, Product 1], [2, Product 2], [3, Product 3]]}]

    print(await db.getVersion()); // 10

    result = await db.rawQuery('SELECT * FROM Product', []);
    print(result); // [{columns: [id, title], rows: [[1, Product 1], [2, Product 2], [3, Product 3]]}]

    result = await db.rawQuery('SELECT * FROM Product WHERE title = ?', ['Product 1']);
    print(result); // [{columns: [id, title], rows: [[1, Product 1]]}]
  }

  await db.close();
}
