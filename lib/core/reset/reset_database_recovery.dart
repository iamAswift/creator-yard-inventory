import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// File-level recovery operations shared by the reset service and tests.
class ResetDatabaseRecovery {
  ResetDatabaseRecovery._();

  static const sidecarSuffixes = ['-wal', '-shm', '-journal'];

  /// Refuses to proceed if a previous failed-state database or sidecar
  /// exists. Existing files are preserved for investigation.
  static Future<void> ensureNoFailedStateFiles(
    String failedStatePath,
  ) async {
    for (final suffix in ['', ...sidecarSuffixes]) {
      final path = '$failedStatePath$suffix';
      if (await File(path).exists()) {
        throw StateError(
          'A failed-state recovery file already exists: $path',
        );
      }
    }
  }

  static Future<void> validateDatabase(String path) async {
    final file = File(path);

    if (!await file.exists() || await file.length() == 0) {
      throw StateError('Database file is missing or empty: $path');
    }

    final database = sqlite3.sqlite3.open(path);
    try {
      final results = database.select('PRAGMA integrity_check');
      if (results.isEmpty || results.first.values.first != 'ok') {
        throw StateError('SQLite integrity check failed: $path');
      }
    } finally {
      database.close();
    }
  }

  /// Installs a validated recovery snapshot while staging the previous
  /// database and sidecars. The recovery snapshot is never deleted here.
  static Future<void> restore({
    required String databasePath,
    required String recoveryPath,
    required String restoreTempPath,
    required String failedStatePath,
    Future<File> Function(File file, String destination)? renameFile,
  }) async {
    final liveFile = File(databasePath);
    final recoveryFile = File(recoveryPath);
    final tempFile = File(restoreTempPath);
    final rename =
        renameFile ?? (file, destination) => file.rename(destination);

    if (!await recoveryFile.exists()) {
      throw StateError('The reset recovery copy is missing: $recoveryPath');
    }
    if (await tempFile.exists()) {
      throw StateError(
        'Rollback temporary file already exists: $restoreTempPath',
      );
    }

    // Never overwrite any previous failed-state file, including sidecars.
    for (final suffix in ['', ...sidecarSuffixes]) {
      if (await File('$failedStatePath$suffix').exists()) {
        throw StateError(
          'A failed-state recovery file already exists: '
          '$failedStatePath$suffix',
        );
      }
    }

    await recoveryFile.copy(restoreTempPath);
    await validateDatabase(restoreTempPath);

    // Stage the live database and sidecars instead of deleting them.
    // Track each successful move so partial staging can be reversed.
    final staged = <({String original, String saved})>[];

    try {
      for (final suffix in ['', ...sidecarSuffixes]) {
        final originalPath = '$databasePath$suffix';
        final savedPath = '$failedStatePath$suffix';
        final original = File(originalPath);

        if (await original.exists()) {
          await rename(original, savedPath);
          staged.add((original: originalPath, saved: savedPath));
        }
      }
    } catch (stageError) {
      final rollbackErrors = <String>[];

      for (final item in staged.reversed) {
        try {
          final saved = File(item.saved);
          if (await saved.exists()) {
            await rename(saved, item.original);
          }
        } catch (error) {
          rollbackErrors.add('${item.saved}: $error');
        }
      }

      throw StateError(
        'Could not stage the original database and sidecars: $stageError. '
        '${rollbackErrors.isEmpty ? "Staged files were restored where possible." : "Some files could not be restored: ${rollbackErrors.join("; ")}. Preserve the recovery snapshot at $recoveryPath and inspect all failed-state files."} '
        'Recovery snapshot retained at $recoveryPath; temporary copy retained at $restoreTempPath.',
      );
    }

    try {
      await rename(tempFile, databasePath);
      await validateDatabase(databasePath);
    } catch (installError) {
      final rollbackErrors = <String>[];

      // Remove only the failed replacement; keep the recovery snapshot.
      try {
        if (await liveFile.exists()) {
          await liveFile.delete();
        }
      } catch (error) {
        rollbackErrors.add('Could not remove failed replacement: $error');
      }

      // Restore the original main database and sidecars in reverse order.
      for (final item in staged.reversed) {
        try {
          final saved = File(item.saved);
          if (await saved.exists()) {
            await rename(saved, item.original);
          }
        } catch (error) {
          rollbackErrors.add('${item.saved}: $error');
        }
      }

      // If no original main database was staged, recover from the snapshot.
      if (!await liveFile.exists() &&
          !staged.any((item) => item.original == databasePath)) {
        try {
          await recoveryFile.copy(databasePath);
          await validateDatabase(databasePath);
        } catch (error) {
          rollbackErrors.add('Snapshot fallback failed: $error');
        }
      }

      throw StateError(
        'Recovery snapshot installation failed: $installError. '
        '${rollbackErrors.isEmpty ? "Rollback completed where applicable." : "Rollback needs attention: ${rollbackErrors.join("; ")}."} '
        'Preserve the recovery snapshot at $recoveryPath and inspect files near $failedStatePath.',
      );
    }

    // The snapshot is installed and validated. Only now clean up staged files.
    // Cleanup failures must not convert a successful restore into a failure.
    for (final item in staged) {
      try {
        final saved = File(item.saved);
        if (await saved.exists()) {
          await saved.delete();
        }
      } catch (_) {
        // Keep any undeletable failed-state file for manual investigation.
      }
    }
  }
}
