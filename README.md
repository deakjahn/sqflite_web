# sqflite_web

This is a web version of [sqflite](https://pub.dev/packages/sqflite).

## Integration

`pubspec.yaml`:

```yaml
dependencies:
  # Database handling (if you want to support)
  sqflite: ^1.3.2+2

dev_dependencies:
  # For sqflite web compatibility (will save the database IN MEMORY => not stored)
  sqflite_web:
    git:
      url: https://github.com/FunnyLabz/sqflite_web.git
      ref: master
```

`main.dart` (or any other dart file)

```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_web/sqflite_web.dart';

void main() {
  // Add web compatibility
  if (kIsWeb) {
    databaseFactory = databaseFactoryWeb;
  }

  (...)

  // Open the database and do whatever you want
  Database appDatabase;
  if (kIsWeb) {
    // Use the database from memory (no persistency on web...)
    appDatabase = await databaseFactory.openDatabase(inMemoryDatabasePath);
  } else {
    // Other platforms (store on real file)
     appDatabase = await databaseFactory.openDatabase((await getApplicationDocumentsDirectory()).path + '/app.db');
  }

}
```


Right now, it already runs and creates a test database and writes a few records.

Please, note that this is experimental. It's not on pub.dev and not automatically endorsed by Sqflite as the web implementation because these are just the first steps to see if it's feasible at all.

While the code itself is functional, the database stays in the memory. There is no persistence and copies of the same app running in different browser tabs would see different, separate databases.
Use it if it fits your requirements and suggest solutions to the missing functionality if you have ideas but don't expect it to be a full Sqflite implementation on the web.

## Install

Add this line in `index.html`:
```html
<body>
  <script src="assets/packages/sqflite_web/assets/require.js" type="application/javascript"></script>
  (...)
</body>
```

Note: The `require.js` library will be added dynamically if you forget to add this line in `index.html`
(but this will imply users do a 'refresh' of the web page every time they want to access it because of dynamic include issues).
