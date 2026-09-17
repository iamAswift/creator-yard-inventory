// lib/features/settings/backup_data_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/backup/backup_service.dart';
import '../../core/app/app_refresh.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/styles.dart';
import '../../database/daos/settings_dao.dart';

class BackupDataScreen extends StatefulWidget {
  final SettingsDao settingsDao;

  const BackupDataScreen({super.key, required this.settingsDao});

  @override
  State<BackupDataScreen> createState() => _BackupDataScreenState();
}

class _BackupDataScreenState extends State<BackupDataScreen> {
  List<File> _backups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final backups = await BackupService.getBackups();

      if (!mounted) return;

      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load backups: $e';
      });
    }
  }

  Future<void> _restoreBackup(File backup) async {
    if (_isRestoring || _isCreatingBackup) return;

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Database?'),
          content: Text(
            'This will replace the current inventory database with:\n\n'
            '${_fileName(backup)}\n\n'
            'Your current data will be replaced. A safety backup will be '
            'created before the restore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (shouldRestore != true || !mounted) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      await BackupService.validateBackup(backup);

      final safetyBackup = await BackupService.backupNow();

      debugPrint(
        'Restore safety backup created: ${safetyBackup.path}',
      );

      await BackupService.replaceLiveDatabase(backup);

      AppRefresh.refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database restored successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database restore failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _createBackup() async {
    if (_isCreatingBackup) return;

    setState(() {
      _isCreatingBackup = true;
    });

    try {
      final backup = await BackupService.backupNow();

      if (!mounted) return;

      await _loadBackups();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup created successfully: ${_formatFileSize(await backup.length())}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
      }
    }
  }

  String _formatDate(File file) {
    final date = file.lastModifiedSync();

    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  Widget _buildBackupCard(File backup, int index) {
    final isLatest = index == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: AppSizes.iconButton,
          height: AppSizes.iconButton,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.storage_outlined, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isLatest ? 'Latest Backup' : 'Database Backup',
                style: AppTextStyles.title,
              ),
            ),
            if (isLatest)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('LATEST', style: AppTextStyles.bodySecondary),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: FutureBuilder<int>(
            future: backup.length(),
            builder: (context, snapshot) {
              final size = snapshot.hasData
                  ? _formatFileSize(snapshot.data!)
                  : 'Calculating size...';

              return Text(
                '${_formatDate(backup)}\n$size\n${_fileName(backup)}',
                style: AppTextStyles.bodySecondary,
              );
            },
          ),
        ),
        trailing: TextButton.icon(
          onPressed: (_isRestoring || _isCreatingBackup)
              ? null
              : () => _restoreBackup(backup),
          icon: const Icon(Icons.restore),
          label: const Text('Restore'),
        ),
      ),
    );
  }

  Widget _buildBackupHistory() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(_errorMessage!, style: AppTextStyles.body),
        ),
      );
    }

    if (_backups.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Icon(
                Icons.backup_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No backups found', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your database backups will appear here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _backups.length; i++)
          _buildBackupCard(_backups[i], i),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Data'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadBackups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding,
          vertical: responsive.verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: AppSizes.iconButton,
                          height: AppSizes.iconButton,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.backup,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Database Backup',
                            style: AppTextStyles.title,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Your inventory database is automatically backed up once per day. '
                      'You can also create a manual backup at any time.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingBackup ? null : _createBackup,
                        icon: _isCreatingBackup
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isCreatingBackup
                              ? 'Creating Backup...'
                              : 'Backup Now',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Backup History', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            _buildBackupHistory(),
          ],
        ),
      ),
    );
  }
}
