# sqflite_web

## Obsolete

[Sqflite](https://pub.dev/packages/sqflite) now has an experimental but working web implementation: [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).

This makes this approach obsolete. Please, try that package instead.

## Original

This is a web version of [sqflite](https://pub.dev/packages/sqflite).

There is no persistence and copies of the same app running in different browser tabs would see different, separate databases.
Use it if it fits your requirements and suggest solutions to the missing functionality if you have ideas but don't expect it to be a full Sqflite implementation on the web.

Please, note that this is experimental. It's not on pub.dev and not automatically endorsed by Sqflite as the web implementation because of the persistency issue.

The example runs and creates a test database and writes a few records on web console (F12->console on most web browser or directly on shell if running in debug).


## Install

`pubspec.yaml`:

```yaml
dependencies:
  # Database handling (if you want to support other platforms than web too)
  sqflite: ^1.3.2+2

dev_dependencies:
  # For sqflite web compatibility (will save the database IN MEMORY => not stored)
  sqflite_web:
    git:
      url: https://github.com/deakjahn/sqflite_web.git
      ref: master
```

`main.dart` (or any other dart file)

```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_web/sqflite_web.dart';
import 'package:flutter/foundation.dart';

void main() {
  (...)

  // Open the database and do whatever you want
  Database appDatabase;
  if (kIsWeb) {
    // Use the database from memory (no persistency on web...)
    var databaseFactory = databaseFactoryWeb;
    appDatabase = await databaseFactory.openDatabase(inMemoryDatabasePath);
  } else {
    // Other platforms (store on real file)
     appDatabase = await databaseFactory.openDatabase((await getApplicationDocumentsDirectory()).path + '/app.db');
  }

  (...)
}
```
