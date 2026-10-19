import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  late Directory tempDirectory;
  late String databasePath;
  late String recoveryPath;
  late String restoreTempPath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'creator_yard_reset_test_',
    );

    databasePath = '${tempDirectory.path}/test.sqlite';
    recoveryPath = '$databasePath.reset_safety';
    restoreTempPath = '$databasePath.reset_restore_tmp';
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  String escapeSqlString(String value) => value.replaceAll("'", "''");

  void expectIntegrityOk(String path) {
    final database = sqlite3.sqlite3.open(path);
    try {
      final results = database.select('PRAGMA integrity_check');
      expect(results, isNotEmpty);
      expect(results.first.values.first, 'ok');
    } finally {
      database.close();
    }
  }

  test('VACUUM INTO creates a valid independent recovery snapshot', () async {
    final database = sqlite3.sqlite3.open(databasePath);

    database.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)',
    );
    database.execute('INSERT INTO settings (key, value) VALUES (?, ?)', [
      'creator_yard_installation_id',
      'isolated-test-installation',
    ]);
    database.execute('INSERT INTO settings (key, value) VALUES (?, ?)', [
      'sample_business_name',
      'Test Shop',
    ]);

    final escapedRecoveryPath = escapeSqlString(recoveryPath);
    database.execute("VACUUM INTO '$escapedRecoveryPath'");
    database.close();

    expect(await File(recoveryPath).exists(), isTrue);
    expect(await File(recoveryPath).length(), greaterThan(0));
    expectIntegrityOk(recoveryPath);

    final snapshot = sqlite3.sqlite3.open(recoveryPath);
    try {
      final rows = snapshot.select(
        'SELECT key, value FROM settings ORDER BY key',
      );

      expect(rows, hasLength(2));
      expect(
        rows.firstWhere(
          (row) => row['key'] == 'creator_yard_installation_id',
        )['value'],
        'isolated-test-installation',
      );
    } finally {
      snapshot.close();
    }
  });

  test(
    'a validated recovery copy can restore a damaged test database',
    () async {
      final database = sqlite3.sqlite3.open(databasePath);

      database.execute(
        'CREATE TABLE records (id INTEGER PRIMARY KEY, value TEXT)',
      );
      database.execute('INSERT INTO records (value) VALUES (?)', [
        'original record',
      ]);

      final escapedRecoveryPath = escapeSqlString(recoveryPath);
      database.execute("VACUUM INTO '$escapedRecoveryPath'");
      database.close();

      // Simulate a failed reset by changing the isolated live database.
      final failedDatabase = sqlite3.sqlite3.open(databasePath);
      failedDatabase.execute('DROP TABLE records');
      failedDatabase.close();

      // Prepare and validate a separate restore copy before replacing the file.
      await File(recoveryPath).copy(restoreTempPath);
      expectIntegrityOk(restoreTempPath);

      // Mirror the service's replacement sequence in this temporary directory.
      await File(databasePath).delete();
      await File(restoreTempPath).rename(databasePath);

      expectIntegrityOk(databasePath);

      final restoredDatabase = sqlite3.sqlite3.open(databasePath);
      try {
        final rows = restoredDatabase.select('SELECT value FROM records');
        expect(rows, hasLength(1));
        expect(rows.first['value'], 'original record');
      } finally {
        restoredDatabase.close();
      }
    },
  );
}
