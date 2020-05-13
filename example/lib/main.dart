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
  await db.insert('Product', <String, dynamic>{'title': 'Product 1'});
  await db.insert('Product', <String, dynamic>{'title': 'Product 2'});

  var result = await db.query('Product');
  print(result);
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 2}]
  print(await db.getVersion());
  // prints 10
  await db.close();
}
