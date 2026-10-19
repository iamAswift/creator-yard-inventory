import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:supermarket_inventory/core/reset/reset_database_recovery.dart';

void main() {
  late Directory directory;
  late String livePath;
  late String recoveryPath;
  late String tempPath;
  late String failedPath;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'creator_yard_recovery_failure_',
    );
    livePath = '${directory.path}/live.sqlite';
    recoveryPath = '$livePath.reset_safety';
    tempPath = '$livePath.reset_restore_tmp';
    failedPath = '$livePath.reset_failed_state';
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  void createDatabase(String path, String value) {
    final db = sqlite3.sqlite3.open(path);
    try {
      db.execute('CREATE TABLE records (value TEXT)');
      db.execute('INSERT INTO records (value) VALUES (?)', [value]);
    } finally {
      db.close();
    }
  }

  String readValue(String path) {
    final db = sqlite3.sqlite3.open(path);
    try {
      return db.select('SELECT value FROM records').first['value'] as String;
    } finally {
      db.close();
    }
  }

  test('preflight refuses an existing failed-state sidecar and preserves it', () async {
    final sidecarPath = '$failedPath-wal';
    final sidecar = File(sidecarPath);
    const contents = 'preserve this failed-state sidecar';
    await sidecar.writeAsString(contents);

    await expectLater(
      ResetDatabaseRecovery.ensureNoFailedStateFiles(failedPath),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains(sidecarPath),
        ),
      ),
    );

    expect(await sidecar.exists(), isTrue);
    expect(await sidecar.readAsString(), contents);
    expect(await File(failedPath).exists(), isFalse);
  });

  test('failed install restores prior database and retains snapshot', () async {
    createDatabase(livePath, 'previous live database');
    createDatabase(recoveryPath, 'snapshot to restore');

    var injectedFailure = false;

    Future<File> failingRename(File file, String destination) async {
      if (file.path == tempPath && destination == livePath) {
        injectedFailure = true;
        throw FileSystemException('Injected rename failure', file.path);
      }
      return file.rename(destination);
    }

    await expectLater(
      ResetDatabaseRecovery.restore(
        databasePath: livePath,
        recoveryPath: recoveryPath,
        restoreTempPath: tempPath,
        failedStatePath: failedPath,
        renameFile: failingRename,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Recovery snapshot installation failed'),
        ),
      ),
    );

    expect(injectedFailure, isTrue);
    expect(await File(livePath).exists(), isTrue);
    expect(readValue(livePath), 'previous live database');
    expect(await File(recoveryPath).exists(), isTrue);
    expect(readValue(recoveryPath), 'snapshot to restore');
    expect(await File(failedPath).exists(), isFalse);
  });

  test(
    'partial sidecar staging failure restores original files and retains snapshot',
    () async {
      createDatabase(livePath, 'original live database');
      createDatabase(recoveryPath, 'validated recovery snapshot');

      final walFile = File('$livePath-wal');
      final shmFile = File('$livePath-shm');
      await walFile.writeAsString('test wal sidecar');
      await shmFile.writeAsString('test shm sidecar');

      var walStaged = false;
      var shmFailureInjected = false;

      Future<File> failingRename(File file, String destination) async {
        if (file.path == shmFile.path) {
          shmFailureInjected = true;
          throw FileSystemException(
            'Injected sidecar staging failure',
            file.path,
          );
        }

        final result = await file.rename(destination);
        if (file.path == walFile.path) {
          walStaged = true;
        }
        return result;
      }

      await expectLater(
        ResetDatabaseRecovery.restore(
          databasePath: livePath,
          recoveryPath: recoveryPath,
          restoreTempPath: tempPath,
          failedStatePath: failedPath,
          renameFile: failingRename,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Could not stage the original database'),
              contains(recoveryPath),
              contains(tempPath),
            ),
          ),
        ),
      );

      expect(walStaged, isTrue);
      expect(shmFailureInjected, isTrue);
      expect(await File(livePath).exists(), isTrue);
      expect(await walFile.exists(), isTrue);
      expect(await walFile.readAsString(), 'test wal sidecar');
      expect(await shmFile.exists(), isTrue);
      expect(await shmFile.readAsString(), 'test shm sidecar');
      expect(readValue(livePath), 'original live database');
      expect(await File(recoveryPath).exists(), isTrue);
      expect(readValue(recoveryPath), 'validated recovery snapshot');
      expect(await File('$failedPath-wal').exists(), isFalse);
      expect(await File(failedPath).exists(), isFalse);
    },
  );

  test(
    'successful restore installs snapshot and retains no failed state',
    () async {
      createDatabase(livePath, 'old database');
      createDatabase(recoveryPath, 'recovered database');

      await ResetDatabaseRecovery.restore(
        databasePath: livePath,
        recoveryPath: recoveryPath,
        restoreTempPath: tempPath,
        failedStatePath: failedPath,
      );

      expect(readValue(livePath), 'recovered database');
      expect(await File(recoveryPath).exists(), isTrue);
      expect(await File(failedPath).exists(), isFalse);
    },
  );

  test('failure moving the live database leaves it readable', () async {
    createDatabase(livePath, 'original live database');
    createDatabase(recoveryPath, 'recovery snapshot');

    var injectedFailure = false;

    Future<File> failingRename(File file, String destination) async {
      if (file.path == livePath && destination == failedPath) {
        injectedFailure = true;
        throw FileSystemException('Injected live move failure', file.path);
      }
      return file.rename(destination);
    }

    await expectLater(
      ResetDatabaseRecovery.restore(
        databasePath: livePath,
        recoveryPath: recoveryPath,
        restoreTempPath: tempPath,
        failedStatePath: failedPath,
        renameFile: failingRename,
      ),
      throwsA(isA<StateError>()),
    );

    expect(injectedFailure, isTrue);
    expect(await File(livePath).exists(), isTrue);
    expect(readValue(livePath), 'original live database');
    expect(await File(recoveryPath).exists(), isTrue);
  });

  test('double failure preserves original and recovery files', () async {
    createDatabase(livePath, 'original live database');
    createDatabase(recoveryPath, 'recovery snapshot');

    var installFailureInjected = false;
    var rollbackFailureInjected = false;

    Future<File> failingRename(File file, String destination) async {
      if (file.path == tempPath && destination == livePath) {
        installFailureInjected = true;
        throw FileSystemException('Injected install failure', file.path);
      }
      if (file.path == failedPath && destination == livePath) {
        rollbackFailureInjected = true;
        throw FileSystemException('Injected rollback failure', file.path);
      }
      return file.rename(destination);
    }

    await expectLater(
      ResetDatabaseRecovery.restore(
        databasePath: livePath,
        recoveryPath: recoveryPath,
        restoreTempPath: tempPath,
        failedStatePath: failedPath,
        renameFile: failingRename,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Rollback needs attention'),
        ),
      ),
    );

    expect(installFailureInjected, isTrue);
    expect(rollbackFailureInjected, isTrue);
    expect(await File(livePath).exists(), isFalse);
    expect(await File(failedPath).exists(), isTrue);
    expect(readValue(failedPath), 'original live database');
    expect(await File(recoveryPath).exists(), isTrue);
    expect(readValue(recoveryPath), 'recovery snapshot');
    expect(await File(tempPath).exists(), isTrue);
  });
}
