@JS('sqflite_web')
library sqflite_web;

import 'dart:js' as js;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/sql_builder.dart'; // ignore: implementation_imports

// https://sql-js.github.io/sql.js/documentation/class/Database.html

@JS('create')
external void _dbCreate();

@JS('open')
external void _dbOpen(Uint8List data);

@JS('close')
external void _dbClose();

@JS('run')
external void _dbRun(String sql);

@JS('runParams')
external void _dbRunWithParams(String sql, dynamic params);

@JS('execute')
external js.JsObject _dbExecute(String sql);

@JS('executeScalar')
external int _dbExecuteScalar(String sql);

@JS('stmt_prepare')
external js.JsObject _dbPrepare(String sql);

@JS('stmt_prepare')
external js.JsObject _dbPrepareParams(String sql, dynamic params);

@JS('stmt_bind')
external bool _dbStmtBind(js.JsObject statement, dynamic values);

@JS('stmt_run')
external void _dbStmtRun(js.JsObject statement, dynamic values);

@JS('stmt_step')
external bool _dbStmtStep(js.JsObject statement);

@JS('stmt_get')
external js.JsObject _dbStmtGet(js.JsObject statement, dynamic params);

@JS('stmt_getColumnNames')
external js.JsArray _dbStmtGetColumnNames(js.JsObject statement);

@JS('stmt_free')
external void _dbStmtFree(js.JsObject statement);

@JS('getRowsModified')
external int _dbGetRowsModified();

@JS('export')
external Uint8List _dbExport();

final _debug = false; // devWarning(true); // false

/// Web log level.
int logLevel = sqfliteLogLevelNone;

/// Web database
class SqfliteWebDatabase extends Database {
  /// Create web database.
  SqfliteWebDatabase({@required this.path, @required this.readOnly, @required this.logLevel}) {
    _dbCreate();
    _isOpen = true;
  }

  /// Open web database from byte data.
  SqfliteWebDatabase.fromData({@required this.path, @required this.readOnly, @required this.logLevel, Uint8List data}) {
    _dbOpen(data);
    _isOpen = true;
  }

  /// P$ath.
  @override
  final String path;

  /// If read-only
  final bool readOnly;

  /// Log level.
  final int logLevel;

  /// Debug map.
  Map<String, dynamic> toDebugMap() => <String, dynamic>{'path': path, 'readOnly': readOnly};

  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen;

  /// Last insert id.
  int _getLastInsertId() {
    // Check the row count first, if 0 it means no insert
    // Fix issue #402
    if (_getUpdatedRows() == 0) {
      return 0;
    } else {
      return _dbExecuteScalar('SELECT last_insert_rowid();');
    }
  }

  /// Return the count of updated rows.
  int _getUpdatedRows() {
    var rowCount = _dbGetRowsModified();
    if (logLevel >= sqfliteLogLevelSql) {
      print('Modified $rowCount rows');
    }
    return rowCount;
  }

  /// Close the database.
  @override
  Future<void> close() {
    logResult(result: 'Closing database $this');
    _dbClose();
    _isOpen = false;
    return null;
  }

  @override
  Future<int> delete(String table, {String where, List whereArgs}) async {
    final builder = SqlBuilder.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );

    logSql(sql: builder.sql, sqlArguments: builder.arguments);
    _dbRunWithParams(builder.sql, builder.arguments);
    return _getUpdatedRows();
  }

  @override
  @deprecated
  Future<T> devInvokeMethod<T>(String method, [arguments]) {
    throw UnimplementedError('deprecated');
  }

  @override
  @deprecated
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List arguments]) {
    throw UnimplementedError('deprecated');
  }

  /// Handle execute.
  @override
  Future<void> execute(String sql, [List sqlArguments]) {
    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = Statement(_dbPrepare(sql));
      try {
        preparedStatement.executeWith(sqlArguments);
      } finally {
        preparedStatement.free();
      }
    } else {
      _dbExecute(sql);
    }
    return null;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values, {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) async {
    final builder = SqlBuilder.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );

    logSql(sql: builder.sql, sqlArguments: builder.arguments);
    _dbRunWithParams(builder.sql, builder.arguments);

    var id = _getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('Inserted id $id');
    }
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {bool distinct, List<String> columns, String where, List whereArgs, String groupBy, String having, String orderBy, int limit, int offset}) async {
    final builder = SqlBuilder.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    logSql(sql: builder.sql);
    var result = _dbExecute(builder.sql);
    logResult(result: 'Found 1 row');

    return packResult(result);
  }

  @override
  Future<int> rawDelete(String sql, [List sqlArguments]) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = Statement(_dbPrepareParams(sql, sqlArguments));
      try {
        preparedStatement.executeWith(sqlArguments);
      } finally {
        preparedStatement.free();
      }
    } else {
      _dbExecute(sql);
    }

    return _getUpdatedRows();
  }

  @override
  Future<int> rawInsert(String sql, [List sqlArguments]) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = Statement(_dbPrepareParams(sql, sqlArguments));
      try {
        preparedStatement.executeWith(sqlArguments);
      } finally {
        preparedStatement.free();
      }
    } else {
      _dbExecute(sql);
    }

    var id = _getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('Inserted id $id');
    }
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List sqlArguments]) async {
    js.JsObject result;

    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = Statement(_dbPrepareParams(sql, sqlArguments));
      try {
        List<String> columnNames;
        final rows = [];

        while (preparedStatement.step()) {
          columnNames ??= preparedStatement.columnNames();
          rows.add(preparedStatement.currentRow(sqlArguments));
        }

        columnNames ??= []; // assume no column names when there were no rows
        return toSqfliteFormat(columnNames, rows);
      } finally {
        preparedStatement.free();
      }
    } else {
      result = _dbExecute(sql);
      return packResult(result);
    }
  }

  @override
  Future<int> rawUpdate(String sql, [List sqlArguments]) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = Statement(_dbPrepare(sql));
      try {
        preparedStatement.executeWith(sqlArguments);
      } finally {
        preparedStatement.free();
      }
    } else {
      _dbExecute(sql);
    }

    return _getUpdatedRows();
  }

  @override
  Future<int> getVersion() async {
    return _dbExecuteScalar('PRAGMA user_version;');
  }

  @override
  Future<void> setVersion(int version) {
    _dbRun('PRAGMA user_version = $version;');
    return null;
  }

  @override
  Batch batch() {
    // TODO: implement batch
    throw UnimplementedError();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool exclusive}) {
    // TODO: implement transaction
    throw UnimplementedError();
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) async {
    final builder = SqlBuilder.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );

    logSql(sql: builder.sql);
    _dbExecute(builder.sql);
    return _getUpdatedRows();
  }

  /// Export the whole database.
  Future<Uint8List> export() async {
    return _dbExport();
  }

  /// Log the result if needed.
  void logResult({String result}) {
    if (result != null && (logLevel >= sqfliteLogLevelSql)) {
      print(result);
    }
  }

  /// Log the sql statement if needed.
  void logSql({String sql, List sqlArguments, String result}) {
    if (logLevel >= sqfliteLogLevelSql) {
      print('$sql${(sqlArguments?.isNotEmpty ?? false) ? ' $sqlArguments' : ''}');
      logResult(result: result);
    }
  }

  @override
  String toString() => toDebugMap().toString();
}

/// Convert to expected sqflite format.
List<Map<String, dynamic>> packResult(js.JsObject result) {
  // SQL.js returns: [{columns:['a','b'], values:[[0,'hello'],[1,'world']]}]
  if (result != null) {
    final columns = getProperty(result, 'columns') as List;
    final values = getProperty(result, 'values') as List;
    // This is what sqflite expects
    return toSqfliteFormat(columns, values);
  } else {
    return [];
  }
}

/// Pack the result in the expected sqflite format.
List<Map<String, dynamic>> toSqfliteFormat(List columns, List values) {
  final dataList = <Map<String, dynamic>>[];
  for (var row = 0; row < values.length; row++) {
    final dataRow = <String, dynamic>{};
    for (var col = 0; col < columns.length; col++) {
      dataRow[columns[col].toString()] = values[row][col];
    }
    dataList.add(dataRow);
  }
  return dataList;
}

/// Dart api wrapping an underlying prepared statement object from the sql.js
/// library.
class Statement {
  /// Create new Statement from JS object
  Statement(this._obj);

  final js.JsObject _obj;

  /// Executes this statement with the bound [args].
  bool executeWith(List<dynamic> args) {
    _dbStmtRun(_obj, args);
    return true;
  }

  /// Performs `step` on the underlying js api
  bool step() => _dbStmtStep(_obj);

  /// Reads the current from the underlying js api
  dynamic currentRow(List<dynamic> params) => _dbStmtGet(_obj, params);

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() => _dbStmtGetColumnNames(_obj).cast<String>();

  /// Calls `free` on the underlying js api
  void free() => _dbStmtFree(_obj);
}
