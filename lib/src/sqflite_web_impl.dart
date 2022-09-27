@JS('sqflite_web')
library sqflite_web;

import 'dart:async';
import 'dart:js' as js;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/batch.dart' show SqfliteBatch, SqfliteDatabaseBatch;
import 'package:sqflite_common/src/collection_utils.dart' show BatchResults;
import 'package:sqflite_common/src/database.dart' show SqfliteDatabase;
import 'package:sqflite_common/src/exception.dart' show SqfliteDatabaseException;
import 'package:sqflite_common/src/sql_builder.dart' show ConflictAlgorithm, SqlBuilder;
import 'package:sqflite_common/src/transaction.dart' show SqfliteTransaction;
import 'package:sqflite_common/src/utils.dart' as utils;
import 'package:synchronized/synchronized.dart';

// ignore_for_file: implementation_imports
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
class SqfliteWebDatabase extends SqfliteDatabase {
  /// Create web database.
  SqfliteWebDatabase({required this.path, required this.readOnly, required this.logLevel}) {
    _dbCreate();
    _isOpen = true;
  }

  /// Open web database from byte data.
  SqfliteWebDatabase.fromData({required this.readOnly, required this.logLevel, required Uint8List data}) {
    _dbOpen(data);
    _isOpen = true;
  }

  /// Path.
  @override
  late String path;

  /// Transaction reference count.
  ///
  /// Only set during inTransaction to allow transaction during open.
  int transactionRefCount = 0;

  /// Non-reentrant lock.
  final Lock rawLock = Lock();

  /// If read-only
  final bool readOnly;

  /// Log level.
  final int logLevel;

  /// Debug map.
  Map<String, dynamic> toDebugMap() => <String, dynamic>{'path': path, 'readOnly': readOnly};

  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen;

  @override
  SqfliteDatabase get db => this;

  /// Set when parsing BEGIN and COMMIT/ROLLBACK
  bool inTransaction = false;

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
    return Future.value();
  }

  @override
  Future<int> delete(String table, {String? where, List? whereArgs}) async {
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
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List? arguments]) {
    throw UnimplementedError('deprecated');
  }

  /// Handle execute.
  @override
  Future<void> execute(String sql, [List? sqlArguments]) {
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
    return Future.value();
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
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
  Future<List<Map<String, dynamic>>> query(String table, {bool? distinct, List<String>? columns, String? where, List? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async {
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
  Future<int> rawDelete(String sql, [List? sqlArguments]) async {
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
  Future<int> rawInsert(String sql, [List? sqlArguments]) async {
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
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List? sqlArguments]) async {
    js.JsObject result;

    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = Statement(_dbPrepareParams(sql, sqlArguments));
      try {
        List<String>? columnNames;
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
  Future<int> rawUpdate(String sql, [List? sqlArguments]) async {
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
  Future<void> setVersion(int version) async {
    _dbRun('PRAGMA user_version = $version;');
  }

  @override
  Batch batch() => SqfliteDatabaseBatch(this);

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final builder = SqlBuilder.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );

    logSql(sql: builder.sql, sqlArguments: builder.arguments);
    _dbRunWithParams(builder.sql, builder.arguments);
    return _getUpdatedRows();
  }

  /// Export the whole database.
  Future<Uint8List> export() async {
    return _dbExport();
  }

  /// Log the result if needed.
  void logResult({String? result}) {
    if (result != null && (logLevel >= sqfliteLogLevelSql)) {
      print(result);
    }
  }

  /// Log the sql statement if needed.
  void logSql({String? sql, List? sqlArguments, String? result}) {
    if (logLevel >= sqfliteLogLevelSql) {
      print('$sql${(sqlArguments?.isNotEmpty ?? false) ? ' $sqlArguments' : ''}');
      logResult(result: result);
    }
  }

  @override
  String toString() => toDebugMap().toString();

  @override
  void checkNotClosed() {
    if (!isOpen) {
      throw SqfliteDatabaseException('error database_closed', null);
    }
  }

  @override
  Future<SqfliteDatabase> doOpen(OpenDatabaseOptions options) async {
    _dbCreate();
    _isOpen = true;
    return this;
  }

  @override
  Future<void> doClose() async => close();

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    checkNotClosed();
    return txnWriteSynchronized<T>(txn, (Transaction? txn) async {
      var ok = false;
      if (transactionRefCount++ == 0) {
        txn = await beginTransaction(exclusive: exclusive);
      }
      T result;
      try {
        result = await action(txn!);
        ok = true;
      } finally {
        if (--transactionRefCount == 0) {
          final sqfliteTransaction = txn as SqfliteTransaction;
          sqfliteTransaction.successful = ok;
          await endTransaction(sqfliteTransaction);
        }
      }
      return result;
    });
  }

  /// synchronized call to the database
  /// not re-entrant
  Future<T> txnWriteSynchronized<T>(Transaction? txn, Future<T> Function(Transaction? txn) action) => txnSynchronized(txn, action);

  /// synchronized call to the database
  /// not re-entrant
  /// Ugly compatibility step to not support older synchronized
  /// mechanism
  Future<T> txnSynchronized<T>(Transaction? txn, Future<T> Function(Transaction? txn) action) async {
    // If in a transaction, execute right away
    if (txn != null) {
      return await action(txn);
    } else {
      // Simple timeout warning if we cannot get the lock after XX seconds
      final handleTimeoutWarning = (utils.lockWarningDuration != null && utils.lockWarningCallback != null);
      late Completer<dynamic> timeoutCompleter;
      if (handleTimeoutWarning) {
        timeoutCompleter = Completer<dynamic>();
      }

      // Grab the lock
      final operation = rawLock.synchronized(() {
        if (handleTimeoutWarning) {
          timeoutCompleter.complete();
        }
        return action(txn);
      });
      // Simply warn the developer as this could likely be a deadlock
      if (handleTimeoutWarning) {
        // ignore: unawaited_futures
        timeoutCompleter.future.timeout(utils.lockWarningDuration!, onTimeout: () {
          utils.lockWarningCallback!();
        });
      }
      return await operation;
    }
  }

  @override
  Future<SqfliteTransaction> beginTransaction({bool? exclusive}) async {
    final txn = SqfliteTransaction(this);
    // never create transaction in read-only mode
    if (readOnly != true) {
      await txnExecute<dynamic>(txn, (exclusive == true) ? 'BEGIN EXCLUSIVE' : 'BEGIN IMMEDIATE');
    }
    return txn;
  }

  @override
  Future<void> endTransaction(SqfliteTransaction? txn) async {
    // never commit transaction in read-only mode
    if (readOnly != true) {
      await txnExecute<dynamic>(txn, (txn!.successful == true) ? 'COMMIT' : 'ROLLBACK');
    }
  }

  @override
  SqfliteTransaction? get txn => null; //???

  @override
  Future<List> txnApplyBatch(SqfliteTransaction? txn, SqfliteBatch batch, {bool? noResult, bool? continueOnError}) {
    return txnWriteSynchronized(txn, (_) async {
      final results = <dynamic>[];

      for (final op in batch.operations) {
        switch (op['method'] as String) {
          case 'execute':
            await txn!.execute(op['sql'] as String, op['arguments'] as List<dynamic>);
            break;
          case 'insert':
            final row = await txn!.rawInsert(op['sql'] as String, op['arguments'] as List<dynamic>);
            if (noResult != true) results.add(row);
            break;
          case 'query':
            final result = await txn!.rawQuery(op['sql'] as String, op['arguments'] as List<dynamic>);
            if (noResult != true) results.add(result);
            break;
          case 'update':
            final row = await txn!.rawUpdate(op['sql'] as String, op['arguments'] as List<dynamic>);
            if (noResult != true) results.add(row);
            break;
          default:
            throw "Batch method ${op['method']} not supported";
        }
      }

      return results.isEmpty ? <dynamic>[] : BatchResults.from(results);
    });
  }

  @override
  Future<T> txnExecute<T>(SqfliteTransaction? txn, String sql, [List? arguments]) {
    return txnWriteSynchronized<T>(txn, (_) {
      var inTransactionChange = utils.getSqlInTransactionArgument(sql);
      if (inTransactionChange ?? false) {
        inTransactionChange = true;
        inTransaction = true;
      } else if (inTransactionChange == false) {
        inTransactionChange = false;
        inTransaction = false;
      }
      return txnWriteSynchronized(txn, (_) async {
        await execute(sql, arguments);
        return Future.value();
      });
    });
  }

  @override
  Future<int> txnRawInsert(SqfliteTransaction? txn, String sql, List? arguments) {
    return txnWriteSynchronized(txn, (_) => rawInsert(sql, arguments));
  }

  @override
  Future<List<Map<String, dynamic>>> txnRawQuery(SqfliteTransaction? txn, String sql, List? arguments) {
    return txnWriteSynchronized(txn, (_) => rawQuery(sql, arguments));
  }

  @override
  Future<int> txnRawUpdate(SqfliteTransaction? txn, String sql, List? arguments) {
    return txnWriteSynchronized(txn, (_) => rawUpdate(sql, arguments));
  }
}

/// Convert to expected sqflite format.
List<Map<String, dynamic>> packResult(js.JsObject? result) {
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
  bool executeWith(List<dynamic>? args) {
    _dbStmtRun(_obj, args);
    return true;
  }

  /// Performs `step` on the underlying js api
  bool step() => _dbStmtStep(_obj);

  /// Reads the current from the underlying js api
  dynamic currentRow(List<dynamic>? params) => _dbStmtGet(_obj, params);

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() => List.from(_dbStmtGetColumnNames(_obj));

  /// Calls `free` on the underlying js api
  void free() => _dbStmtFree(_obj);
}
