import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';

import 'sqflite_web.dart';
import 'sqflite_web_impl.dart';

DatabaseFactory? _databaseFactoryWebImpl;

/// The web database factory.
DatabaseFactory get databaseFactoryWebImpl {
  return _databaseFactoryWebImpl ??= DatabaseFactoryWeb();
}

/// The web database factory.
class DatabaseFactoryWeb extends DatabaseFactory {
  SqfliteWebDatabase? _db;

  @override
  Future<bool> databaseExists(String path) async {
    //TODO
    return _db != null;
  }

  @override
  Future<void> deleteDatabase(String path) async {
    //TODO
    return _db = null;
  }

  @override
  Future<String> getDatabasesPath() async {
    //TODO
    return '';
  }

  @override
  Future<void> setDatabasesPath(String path) {
    //TODO
    return Future.value();
  }

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options}) async {
    await SqflitePluginWeb.isReady;
    _db ??= SqfliteWebDatabase(path: path, readOnly: options?.readOnly ?? false, logLevel: sqfliteLogLevelNone);
    options?.onConfigure?.call(_db!);
    options?.onCreate?.call(_db!, options.version ?? 0);
    options?.onOpen?.call(_db!);
    return _db!;
  }

  /// Load a database from byte data
  Future<Database> loadDatabase(Uint8List data, {OpenDatabaseOptions? options}) async {
    await SqflitePluginWeb.isReady;
    _db ??= SqfliteWebDatabase.fromData(readOnly: options?.readOnly ?? false, logLevel: sqfliteLogLevelNone, data: data);
    options?.onConfigure?.call(_db!);
    options?.onCreate?.call(_db!, options.version ?? 0);
    options?.onOpen?.call(_db!);
    return _db!;
  }
}
