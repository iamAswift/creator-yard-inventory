// lib/features/licensing/license_access_screen.dart

import 'package:flutter/material.dart';

import '../../core/licensing/license_state.dart';
import '../../core/constants/creator_yard_support.dart';
import '../../core/theme/styles.dart';

class LicenseAccessScreen extends StatefulWidget {
  const LicenseAccessScreen({
    super.key,
    required this.licenseState,
    required this.onRetry,
  });

  final LicenseState licenseState;
  final Future<void> Function() onRetry;

  @override
  State<LicenseAccessScreen> createState() => _LicenseAccessScreenState();
}

class _LicenseAccessScreenState extends State<LicenseAccessScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final licenseState = widget.licenseState;
    final isClockTampered = licenseState.status == LicenseStatus.clockTampered;
    final isUnlicensed = licenseState.status == LicenseStatus.unlicensed;
    final isVerificationUnavailable =
        licenseState.status == LicenseStatus.verificationUnavailable;

    final title = isClockTampered
        ? 'License Access Temporarily Blocked'
        : isUnlicensed
        ? 'License Required'
        : isVerificationUnavailable
        ? 'Unable to Verify License'
        : 'Demo Period Expired';

    final message = isClockTampered
        ? 'The system clock appears to have been moved backwards. '
              'Please restore the correct date and time, then restart Creator Yard.'
        : isUnlicensed
        ? 'This Creator Yard installation is not currently licensed. '
              'Please contact Creator Yard support to activate this installation.'
        : isVerificationUnavailable
        ? 'Creator Yard could not verify this installation’s license. '
              'Check your internet connection and try again. '
              'If the problem continues, contact support.'
        : 'Your 14-day Creator Yard demo period has ended. '
              'Please activate a license to continue using the application.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxFormWidth,
              ),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isClockTampered
                            ? Icons.schedule
                            : isVerificationUnavailable
                            ? Icons.cloud_off_outlined
                            : Icons.lock_outline,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      if (isVerificationUnavailable) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isRetrying ? null : _retry,
                            icon: _isRetrying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(
                              _isRetrying
                                  ? 'Checking license...'
                                  : 'Retry License Verification',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Installation ID',
                              style: AppTextStyles.small,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SelectableText(
                              licenseState.installationId,
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Contact Creator Yard support to activate this installation.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Creator Yard Support',
                              style: AppTextStyles.body,
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Phone: ${CreatorYardSupport.phone}',
                              style: AppTextStyles.bodySecondary,
                            ),
                            Text(
                              'WhatsApp: ${CreatorYardSupport.whatsapp}',
                              style: AppTextStyles.bodySecondary,
                            ),
                            Text(
                              'Email: ${CreatorYardSupport.email}',
                              style: AppTextStyles.bodySecondary,
                            ),
                            Text(
                              'Website: ${CreatorYardSupport.website}',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
