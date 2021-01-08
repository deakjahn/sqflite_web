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

    final batch = txn.batch();
    batch.rawInsert('INSERT INTO Product(title) VALUES(?)', ['Product 4']);
    batch.rawInsert('INSERT INTO Product(title) VALUES(?)', ['Product 5']);
    batch.commit();

    return true;
  });

  if (ok) {
    var result = await db.query('Product');
    print(result); // [{columns: [id, title], rows: [[1, Product 1], [2, Product 2], [3, Product 3], [4, Product 4], [5, Product 5]]}]

    print(await db.getVersion()); // 10

    var update = await db.update('Product', <String, dynamic>{'title': 'PRODUCT 1'}, where: 'id = ?', whereArgs: [1]);
    print(update);

    result = await db.rawQuery('SELECT * FROM Product', []);
    print(result); // [{columns: [id, title], rows: [[1, PRODUCT 1], [2, Product 2], [3, Product 3], [4, Product 4], [5, Product 5]]}]

    result = await db.rawQuery('SELECT * FROM Product WHERE title = ?', ['PRODUCT 1']);
    print(result); // [{columns: [id, title], rows: [[1, PRODUCT 1]]}]
  }

  await db.close();
}
