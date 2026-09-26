// lib/features/reports/low_stock_report_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/business/business_identity.dart';
import '../../core/email/email_service.dart';
import '../../core/system/installation_identity.dart';
import '../../core/theme/styles.dart';
import '../../database/app_database.dart';
import '../../database/daos/product_dao.dart';
import '../../database/daos/settings_dao.dart';
import '../../shared/pdf_report.dart';

class LowStockReportScreen extends StatefulWidget {
  const LowStockReportScreen({super.key});

  @override
  State<LowStockReportScreen> createState() => _LowStockReportScreenState();
}

class _LowStockReportScreenState extends State<LowStockReportScreen> {
  late final ProductDao productDao;
  late final SettingsDao settingsDao;

  List<Product> _products = [];

  bool _isLoading = true;
  bool _isEmailing = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final db = getDatabase();
    productDao = ProductDao(db);
    settingsDao = SettingsDao(db);

    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final products = await productDao.getLowStockProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: true,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Low Stock Report', style: AppTextStyles.title),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadReport,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const _LowStockLoadingState();
    }

    if (_error != null) {
      return _LowStockErrorState(error: _error!, onRetry: _loadReport);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReport,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(_products),

                    const SizedBox(height: 24),

                    _buildSummaryCard(_products),

                    const SizedBox(height: 28),

                    _buildProductsSection(_products),

                    if (_products.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _buildExportSection(context, _products),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inventory alert', style: AppTextStyles.heading),
        const SizedBox(height: 6),
        const Text(
          'Review products that have fallen below their '
          'recommended stock level.',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              '${products.length} '
              '${products.length == 1 ? 'product' : 'products'} '
              'require attention',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard(List<Product> products) {
    final isEmpty = products.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          final icon = Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isEmpty ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isEmpty
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: isEmpty ? AppColors.success : AppColors.warning,
              size: 27,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEmpty ? 'Inventory looks good' : 'Products requiring restock',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 4),
              Text(
                isEmpty
                    ? 'All products are currently above their '
                          'low-stock threshold.'
                    : '${products.length} '
                          '${products.length == 1 ? 'product is' : 'products are'} '
                          'currently running low.',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          );

          final countBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isEmpty ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${products.length}',
              style: AppTextStyles.title.copyWith(
                color: isEmpty ? AppColors.success : AppColors.warning,
              ),
            ),
          );

          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(child: content),
                const SizedBox(width: 10),
                countBadge,
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 16),
              Expanded(child: content),
              const SizedBox(width: 16),
              countBadge,
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // PRODUCTS SECTION
  // ============================================================

  Widget _buildProductsSection(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Products running low', style: AppTextStyles.title),
            if (products.isNotEmpty)
              Text('${products.length} items', style: AppTextStyles.small),
          ],
        ),
        const SizedBox(height: 14),
        if (products.isEmpty)
          _buildEmptyProductsCard()
        else
          _buildProductsList(products),
      ],
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return Column(
      children: [
        for (int index = 0; index < products.length; index++) ...[
          _buildProductCard(products[index]),
          if (index < products.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          final icon = Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.warning,
              size: 22,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: AppTextStyles.title.copyWith(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'Inventory level is below the '
                'recommended threshold',
                style: AppTextStyles.small,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final stockBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Current stock', style: AppTextStyles.small),
                const SizedBox(height: 2),
                Text(
                  '${product.stock}',
                  style: AppTextStyles.title.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(child: content),
                  ],
                ),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: stockBadge),
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: content),
              const SizedBox(width: 16),
              stockBadge,
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY PRODUCTS
  // ============================================================

  Widget _buildEmptyProductsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 46, color: AppColors.success),
          SizedBox(height: 14),
          Text(
            'All products are sufficiently stocked',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'There are currently no products below the '
            'low-stock threshold.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPORT SECTION
  // ============================================================

  Widget _buildExportSection(BuildContext context, List<Product> products) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportContent(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildExportButton(context, products),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _emailButton(),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildExportContent()),
              const SizedBox(width: 20),
              _buildExportButton(context, products),
              const SizedBox(width: 12),
              _emailButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExportContent() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 30),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export low stock report',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Generate a PDF containing all products '
                'currently requiring restock.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXPORT BUTTON
  // ============================================================

  Widget _emailButton() {
    return OutlinedButton.icon(
      onPressed: _isEmailing ? null : _emailLowStockReport,
      icon: _isEmailing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.email_outlined),
      label: Text(
        _isEmailing ? 'Emailing...' : 'Email PDF — 5 credits',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, List<Product> products) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.download_outlined, size: 19),
      label: const Text(
        'Export PDF',
        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      ),
      onPressed: () => _exportPdf(context, products),
    );
  }

  // ============================================================
  // PDF EXPORT
  // ============================================================

  Future<void> _emailLowStockReport() async {
    final recipientController = TextEditingController();

    try {
      final businessEmail =
          await BusinessIdentity.getBusinessEmail(settingsDao);

      recipientController.text = businessEmail.trim();

      if (!mounted) return;

      final recipient = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Email Low Stock Report'),
            content: TextField(
              controller: recipientController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                hintText: 'name@example.com',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    recipientController.text.trim(),
                  );
                },
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      if (!mounted || recipient == null || recipient.trim().isEmpty) {
        return;
      }

      setState(() {
        _isEmailing = true;
      });

      final pdfFile = await PdfReport.generateReport(
        title: 'Low Stock Report',
        sections: [
          {
            'title': 'Low Stock Products',
            'headers': ['Product', 'Stock'],
            'rows': _products
                .map((product) => [product.name, '${product.stock}'])
                .toList(),
          },
        ],
      );

      final pdfBytes = await pdfFile.readAsBytes();
      final pdfBase64 = base64Encode(pdfBytes);

      final installationId =
          await InstallationIdentity.getInstallationId(settingsDao);

      final businessName =
          await BusinessIdentity.getBusinessName(settingsDao);

      final normalizedBusinessName =
          businessName.trim().isNotEmpty
              ? businessName.trim()
              : 'Creator Yard';

      await EmailService.sendReportEmail(
        settingsDao: settingsDao,
        installationId: installationId,
        reportId: DateTime.now().millisecondsSinceEpoch,
        recipient: recipient.trim(),
        subject: '$normalizedBusinessName - Low Stock Report',
        body:
            'Attached is the Low Stock Report PDF for '
            '$normalizedBusinessName.',
        pdfBase64: pdfBase64,
        filename: 'low-stock-report.pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Low Stock Report emailed successfully.'),
        ),
      );
    } on EmailServiceException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: e.retryable
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: _emailLowStockReport,
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to email Low Stock Report: $e'),
        ),
      );
    } finally {
      recipientController.dispose();

      if (mounted) {
        setState(() {
          _isEmailing = false;
        });
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, List<Product> products) async {
    try {
      final file = await PdfReport.generateReport(
        title: 'Low Stock Report',
        sections: [
          {
            'title': 'Low Stock Products',
            'headers': ['Product', 'Stock'],
            'rows': products
                .map((product) => [product.name, '${product.stock}'])
                .toList(),
          },
        ],
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            'PDF saved at ${file.path}',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            'Unable to generate PDF: $e',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
        ),
      );
    }
  }
}

// ============================================================
// LOADING STATE
// ============================================================

class _LowStockLoadingState extends StatelessWidget {
  const _LowStockLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading inventory report...',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _LowStockErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _LowStockErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load low stock report',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  error,
                  style: AppTextStyles.small,
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
