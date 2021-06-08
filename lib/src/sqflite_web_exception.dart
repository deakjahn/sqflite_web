import 'sqflite_import.dart';
import 'sqflite_web_impl.dart';

/// Web exception.
class SqfliteWebException extends SqfliteDatabaseException {
  /// Web exception.
  SqfliteWebException({required this.code, required String message, this.details}) : super(message, details);

  /// The database.
  late SqfliteWebDatabase database;

  /// SQL statement.
  late String sql;

  /// SQL arguments.
  late List<dynamic> sqlArguments;

  /// Error code.
  final String code;

  /// Error details.
  Map<String, dynamic>? details;

  @override
  String toString() {
    var map = <String, dynamic>{};
    if (details != null) map['details'] = details;
    return 'SqfliteWebException($code, $message} ${super.toString()} $map';
  }
}
