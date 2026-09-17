import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/system/installation_identity.dart';
import '../../core/theme/styles.dart';
import '../../database/daos/settings_dao.dart';

class AboutSystemScreen extends StatefulWidget {
  final SettingsDao settingsDao;

  const AboutSystemScreen({
    super.key,
    required this.settingsDao,
  });

  @override
  State<AboutSystemScreen> createState() => _AboutSystemScreenState();
}

class _AboutSystemScreenState extends State<AboutSystemScreen> {
  String? _installationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemInformation();
  }

  Future<void> _loadSystemInformation() async {
    try {
      final installationId =
          await InstallationIdentity.getInstallationId(
        widget.settingsDao,
      );

      if (!mounted) return;

      setState(() {
        _installationId = installationId;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
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
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    bool selectable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: AppTextStyles.bodySecondary,
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(
                    value,
                    style: AppTextStyles.body,
                  )
                : Text(
                    value,
                    style: AppTextStyles.body,
                  ),
          ),
        ],
      ),
    );
  }

  String get _platformName {
    switch (Platform.operatingSystem) {
      case 'macos':
        return 'macOS';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      default:
        return Platform.operatingSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About / System Information'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsive.contentMaxWidth,
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalPadding,
                      vertical: responsive.verticalPadding,
                    ),
                    children: [
                      const Text(
                        'Creator Yard',
                        style: AppTextStyles.dashboardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Application and system information',
                        style: AppTextStyles.dashboardSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _section(
                        title: 'Application',
                        icon: Icons.apps_outlined,
                        children: [
                          _infoRow(
                            label: 'Application',
                            value: 'Creator Yard',
                          ),
                          _infoRow(
                            label: 'Version',
                            value: '1.0.1',
                          ),
                          _infoRow(
                            label: 'Build',
                            value: '2',
                          ),
                          _infoRow(
                            label: 'Platform',
                            value: _platformName,
                          ),
                        ],
                      ),
                      _section(
                        title: 'Database',
                        icon: Icons.storage_outlined,
                        children: [
                          _infoRow(
                            label: 'Database',
                            value: 'SQLite',
                          ),
                          _infoRow(
                            label: 'Schema version',
                            value: '25',
                          ),
                          _infoRow(
                            label: 'Storage',
                            value: 'Local device',
                          ),
                          _infoRow(
                            label: 'Operation',
                            value: 'Offline-first',
                          ),
                        ],
                      ),
                      _section(
                        title: 'Installation',
                        icon: Icons.fingerprint,
                        children: [
                          _infoRow(
                            label: 'Installation ID',
                            value: _installationId ?? 'Unavailable',
                            selectable: _installationId != null,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'This unique ID identifies this Creator Yard '
                            'installation and is stored locally on this device.',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          'Creator Yard',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: Text(
                          'Local inventory and POS management',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
