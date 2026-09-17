// lib/core/backup/backup_service.dart

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';

/// Handles local SQLite database backups.
///
/// Backups are created through SQLite's VACUUM INTO command rather than
/// copying the live database file directly. This gives us a consistent
/// SQLite snapshot while the application database remains open.
class BackupService {
  BackupService._();

  static const int maxBackups = 7;

  static const String _backupDirectoryName = 'database_backups';

  static Future<Directory> _getBackupDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();

    final backupDirectory = Directory(
      p.join(supportDirectory.path, _backupDirectoryName),
    );

    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }

    return backupDirectory;
  }

  /// Creates a new timestamped SQLite backup.
  ///
  /// Returns the created backup file.
  static Future<File> backupNow() async {
    final backupDirectory = await _getBackupDirectory();

    final now = DateTime.now();

    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final backupPath = p.join(
      backupDirectory.path,
      'supermarket_$timestamp.sqlite',
    );

    final backupFile = File(backupPath);

    if (await backupFile.exists()) {
      throw StateError('A backup with this timestamp already exists.');
    }

    final escapedPath = backupPath.replaceAll("'", "''");

    final db = getDatabase();

    try {
      await db.customStatement("VACUUM INTO '$escapedPath'");
    } catch (e) {
      if (await backupFile.exists()) {
        try {
          await backupFile.delete();
        } catch (_) {}
      }

      throw StateError('Database backup failed: $e');
    }

    if (!await backupFile.exists()) {
      throw StateError(
        'Database backup completed without creating the backup file.',
      );
    }

    final size = await backupFile.length();

    if (size == 0) {
      try {
        await backupFile.delete();
      } catch (_) {}

      throw StateError('Database backup was created but is empty.');
    }

    await _removeOldBackups();

    return backupFile;
  }

  /// Validates that [backupFile] is a readable and structurally
  /// valid SQLite database.
  ///
  /// The backup is opened independently so the live application database
  /// remains untouched.
  static Future<void> validateBackup(File backupFile) async {
    if (!await backupFile.exists()) {
      throw StateError('Backup file does not exist.');
    }

    final size = await backupFile.length();

    if (size == 0) {
      throw StateError('Backup file is empty.');
    }

    final database = sqlite3.open(backupFile.path);

    try {
      final results = database.select('PRAGMA integrity_check');

      if (results.isEmpty) {
        throw StateError('Backup database integrity check returned no result.');
      }

      final integrityResult = results.first.values.first;

      if (integrityResult != 'ok') {
        throw StateError(
          'Backup database failed SQLite integrity check: $integrityResult',
        );
      }
    } finally {
      database.close();
    }
  }

  /// Replaces the live database with a validated backup.
  ///
  /// The current live database is moved to a temporary safety file before
  /// the replacement. If anything fails, the original database is restored.
  static Future<void> replaceLiveDatabase(File backupFile) async {
    await validateBackup(backupFile);

    final liveDatabasePath = await getDatabaseFilePath();
    final liveDatabaseFile = File(liveDatabasePath);

    if (!await liveDatabaseFile.exists()) {
      throw StateError('Live database file does not exist.');
    }

    final safetyPath = '$liveDatabasePath.restore_safety';
    final safetyFile = File(safetyPath);

    if (await safetyFile.exists()) {
      await safetyFile.delete();
    }

    await closeDatabase();

    try {
      await liveDatabaseFile.rename(safetyPath);

      try {
        await backupFile.copy(liveDatabasePath);

        final restoredFile = File(liveDatabasePath);
        await validateBackup(restoredFile);

        await safetyFile.delete();
      } catch (e) {
        final restoredFile = File(liveDatabasePath);

        if (await restoredFile.exists()) {
          try {
            await restoredFile.delete();
          } catch (_) {}
        }

        if (await safetyFile.exists()) {
          await safetyFile.rename(liveDatabasePath);
        }

        throw StateError('Database restore failed: $e');
      }
    } catch (e) {
      if (await safetyFile.exists() &&
          !await liveDatabaseFile.exists()) {
        try {
          await safetyFile.rename(liveDatabasePath);
        } catch (_) {}
      }

      rethrow;
    }
  }

  /// Returns all local backups, newest first.
  static Future<List<File>> getBackups() async {
    final backupDirectory = await _getBackupDirectory();

    final files = <File>[];

    await for (final entity in backupDirectory.list()) {
      if (entity is! File) {
        continue;
      }

      final filename = p.basename(entity.path);

      if (!filename.startsWith('supermarket_') ||
          !filename.endsWith('.sqlite')) {
        continue;
      }

      files.add(entity);
    }

    files.sort((a, b) => b.path.compareTo(a.path));

    return files;
  }

  /// Removes backups beyond the configured retention count.
  static Future<void> _removeOldBackups() async {
    final backups = await getBackups();

    if (backups.length <= maxBackups) {
      return;
    }

    for (final backup in backups.skip(maxBackups)) {
      try {
        await backup.delete();
      } catch (_) {
        // Retention cleanup should never make a successful backup fail.
      }
    }
  }

  /// Creates today's automatic backup only if today's backup does not exist.
  ///
  /// This can safely be called every time the application starts.
  static Future<File?> createDailyBackupIfNeeded() async {
    final backups = await getBackups();

    final now = DateTime.now();

    final prefix =
        'supermarket_'
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_';

    final alreadyBackedUpToday = backups.any(
      (file) => p.basename(file.path).startsWith(prefix),
    );

    if (alreadyBackedUpToday) {
      return null;
    }

    return backupNow();
  }
}
