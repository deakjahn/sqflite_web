import 'package:meta/meta.dart';

import 'sqflite_import.dart';
import 'sqflite_web_impl.dart';

/// Web exception.
class SqfliteWebException extends SqfliteDatabaseException {
  /// Web exception.
  SqfliteWebException(
      {@required this.code, @required String message, this.details})
      : super(message, details);

  /// The database.
  SqfliteWebDatabase database;

  /// SQL statement.
  String sql;

  /// SQL arguments.
  List<dynamic> sqlArguments;

  /// Error code.
  final String code;

  /// Error details.
  Map<String, dynamic> details;

  @override
  String toString() {
    var map = <String, dynamic>{};
    if (details != null) map['details'] = details;
    return 'SqfliteWebException($code, $message} ${super.toString()} $map';
  }
}
