import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';
import 'reset_database_recovery.dart';
import '../../database/business_settings.dart';
import '../session.dart';

/// Clears Creator Yard's local business data without uninstalling the app,
/// changing Android kiosk settings, or deleting remote server records.
class LocalDataResetService {
  LocalDataResetService._();

  // Keep the identity and licensing information so resetting business data
  // does not unnecessarily create a new server-side installation.
  static const List<String> _preservedSettings = [
    BusinessSettings.installationId,
    BusinessSettings.emailApiCredential,
    BusinessSettings.licenseStatus,
    BusinessSettings.licenseInstallationId,
    BusinessSettings.demoStartedAt,
    BusinessSettings.demoExpiresAt,
    BusinessSettings.licenseLastSeenAt,
    BusinessSettings.commercialEntitlement,
  ];

  static Future<void> reset() async {
    final settingsDao = getSettingsDao();

    // Capture the business image references and installation/licensing
    // settings before closing the database.
    final products = await getProductDao().getAllProducts();
    final categories = await getCategoryDao().getAllCategories();

    final preserved = <String, String>{};
    for (final key in _preservedSettings) {
      final value = await settingsDao.getSetting(key);
      if (value != null) preserved[key] = value;
    }

    final logoPath = await settingsDao.getSetting(
      BusinessSettings.businessLogo,
    );

    final imagePaths = <String>{
      for (final product in products)
        if (product.imagePath != null && product.imagePath!.isNotEmpty)
          product.imagePath!,
      for (final category in categories)
        if (category.imagePath != null && category.imagePath!.isNotEmpty)
          category.imagePath!,
      if (logoPath != null && logoPath.isNotEmpty) logoPath,
    };

    final documents = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final databasePath = await getDatabaseFilePath();
    final recoveryPath = '$databasePath.reset_safety';
    final restoreSafetyPath = '$databasePath.restore_safety';
    final restoreTempPath = '$databasePath.reset_restore_tmp';
    final failedStatePath = '$databasePath.reset_failed_state';

    final liveDatabase = File(databasePath);
    final recoveryFile = File(recoveryPath);
    final restoreSafetyFile = File(restoreSafetyPath);
    final restoreTempFile = File(restoreTempPath);

    // Never overwrite an earlier recovery copy or interfere with a
    // restore operation that may have left its safety file behind.
    if (await recoveryFile.exists()) {
      throw StateError(
        'A reset recovery file already exists. Preserve it and investigate '
        'before attempting another reset: $recoveryPath',
      );
    }
    if (await restoreSafetyFile.exists()) {
      throw StateError(
        'A database restore safety file already exists. Preserve it and '
        'investigate before resetting: $restoreSafetyPath',
      );
    }
    if (await restoreTempFile.exists()) {
      throw StateError(
        'A reset rollback temporary file already exists. Preserve it and '
        'investigate before resetting: $restoreTempPath',
      );
    }

    await ResetDatabaseRecovery.ensureNoFailedStateFiles(
      failedStatePath,
    );
    if (!await liveDatabase.exists()) {
      throw StateError(
        'The live database file does not exist. Reset was not started.',
      );
    }

    // Close Drift before creating a standalone SQLite snapshot.
    // Keep the user's session intact until the snapshot is validated.
    try {
      await closeDatabase();
    } catch (closeError) {
      String? connectionCheckError;

      // Do not delete files or log out if closing the database failed.
      // Check whether the existing database connection remains usable.
      try {
        await getDatabase().customSelect('SELECT 1').get();
      } catch (error) {
        connectionCheckError = '$error';
      }

      throw StateError(
        'Could not close the database, so the reset did not proceed. '
        'No reset database files were deliberately deleted by this step. '
        'Close error: $closeError. '
        '${connectionCheckError == null ? "The database connection still responds to a query." : "The database connection could not be verified: $connectionCheckError. Preserve the database and do not delete app data."}',
      );
    }

    // Use SQLite to create a consistent standalone snapshot after Drift
    // has closed the live database. Keep it until the reset commits.
    try {
      final escapedRecoveryPath = recoveryPath.replaceAll("'", "''");
      final sourceDatabase = sqlite3.sqlite3.open(databasePath);

      try {
        sourceDatabase.execute("VACUUM INTO '$escapedRecoveryPath'");
      } finally {
        sourceDatabase.close();
      }

      if (!await recoveryFile.exists()) {
        throw StateError('The recovery snapshot was not created.');
      }

      if (await recoveryFile.length() == 0) {
        throw StateError('The recovery snapshot is empty.');
      }

      final recoveryDatabase = sqlite3.sqlite3.open(recoveryPath);
      try {
        final results = recoveryDatabase.select('PRAGMA integrity_check');

        if (results.isEmpty) {
          throw StateError(
            'Recovery database integrity check returned no result.',
          );
        }

        final integrityResult = results.first.values.first;
        if (integrityResult != 'ok') {
          throw StateError(
            'Recovery database failed SQLite integrity check: '
            '$integrityResult',
          );
        }
      } finally {
        recoveryDatabase.close();
      }
    } catch (error) {
      // Preserve any incomplete snapshot for investigation. The original
      // database has not been removed, so reopen it without resetting data.
      String? reopenError;
      try {
        await getDatabase().customSelect('SELECT 1').get();
      } catch (error) {
        reopenError = '$error';
      }

      throw StateError(
        'Could not create and validate the reset recovery snapshot. '
        'The original database has not been deleted. '
        '${reopenError == null ? "The original database connection was reopened." : "Reopening the database also failed: $reopenError. Do not delete app data."} '
        'Snapshot error: $error',
      );
    }

    // Only log out after a valid recovery snapshot exists. If snapshot
    // creation fails, the existing session is not unnecessarily cleared.
    try {
      await Session.logout();
    } catch (error) {
      String? reopenError;
      try {
        await getDatabase().customSelect('SELECT 1').get();
      } catch (databaseError) {
        reopenError = '$databaseError';
      }

      throw StateError(
        'The recovery snapshot was created, but logout failed: $error. '
        'The reset has not started. Preserve the recovery snapshot at '
        '$recoveryPath. '
        '${reopenError == null ? "The database connection was reopened." : "Reopening the database also failed: $reopenError."}',
      );
    }

    try {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final file = File('$databasePath$suffix');
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Create the fresh database and restore only installation/licensing
      // settings. No remote registration or license endpoint is called.
      final freshDatabase = getDatabase();
      await freshDatabase.customSelect('SELECT 1').get();

      final freshSettingsDao = getSettingsDao();
      for (final entry in preserved.entries) {
        await freshSettingsDao.setSetting(entry.key, entry.value);
      }

      await initializeDatabaseSettings();
    } catch (error) {
      // Roll back to the saved database if any core reset step fails.
      try {
        await closeDatabase();

        // Restore from the validated safety snapshot using guarded file replacement.
        await ResetDatabaseRecovery.restore(
          databasePath: databasePath,
          recoveryPath: recoveryPath,
          restoreTempPath: restoreTempPath,
          failedStatePath: failedStatePath,
        );

        final restoredDatabase = getDatabase();
        await restoredDatabase.customSelect('SELECT 1').get();
        await initializeDatabaseSettings();
      } catch (rollbackError) {
        throw StateError(
          'Reset failed: $error. Database recovery also failed: '
          '$rollbackError. Preserve the recovery file at $recoveryPath '
          'and do not delete app data.',
        );
      }

      throw StateError(
        'Reset failed. The previous database was restored: $error',
      );
    }

    // The fresh database is now committed. Best-effort cleanup must not
    // turn a successful reset into a reported failure.
    final documentsPath = p.normalize(p.absolute(documents.path));

    for (final imagePath in imagePaths) {
      try {
        final resolvedPath = p.normalize(p.absolute(imagePath));
        if (!p.isWithin(documentsPath, resolvedPath)) continue;

        final file = File(resolvedPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Leave an inaccessible image in place rather than fail the reset.
      }
    }

    // Remove only recognized Creator Yard backup files.
    try {
      final backupDirectory = Directory(
        p.join(support.path, 'database_backups'),
      );

      if (await backupDirectory.exists()) {
        await for (final entity in backupDirectory.list(followLinks: false)) {
          if (entity is! File) continue;

          final name = p.basename(entity.path);
          if (name.startsWith('supermarket_') && name.endsWith('.sqlite')) {
            try {
              await entity.delete();
            } catch (_) {
              // Backup cleanup is best-effort after reset commits.
            }
          }
        }
      }
    } catch (_) {
      // Do not roll back a committed reset because cleanup failed.
    }

    // Remove the recovery copy only after the fresh database is ready.
    try {
      if (await recoveryFile.exists()) {
        await recoveryFile.delete();
      }
    } catch (_) {
      // Keep the recovery file if it cannot safely be removed.
    }
  }
}
