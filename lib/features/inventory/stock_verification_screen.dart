// lib/features/inventory/stock_verification_screen.dart

import 'package:flutter/material.dart';

import '../../core/session.dart';
import '../../core/theme/styles.dart';
import '../../database/app_database.dart';
import '../../database/daos/stock_verification_dao.dart';

class StockVerificationScreen extends StatefulWidget {
  const StockVerificationScreen({super.key});

  @override
  State<StockVerificationScreen> createState() =>
      _StockVerificationScreenState();
}

class _StockVerificationScreenState extends State<StockVerificationScreen> {
  final AppDatabase _db = getDatabase();

  late final StockVerificationDao _verificationDao;

  StockVerification? _verification;

  List<StockVerificationItem> _items = [];

  Map<int, Product> _productsById = {};

  final Map<int, TextEditingController> _controllers = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _canCountStock = false;

  String? _errorMessage;

  DateTime get _businessDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isReviewer => Session.isOwnerOrManager;

  bool get _isCounter => _canCountStock;

  bool get _isDraft => _verification?.status == 'draft';

  bool get _isSubmitted => _verification?.status == 'submitted';

  bool get _isApproved => _verification?.status == 'approved';

  bool get _isRejected => _verification?.status == 'rejected';

  @override
  void initState() {
    super.initState();

    _verificationDao = StockVerificationDao(_db);

    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = Session.currentUserId;

      if (currentUserId == null || currentUserId <= 0) {
        throw Exception('A logged-in user is required.');
      }

      final profile = await _db.userProfileDao.getProfileByUserId(
        currentUserId,
      );

      _canCountStock = profile?.canCountStock ?? false;

      final verification = await _verificationDao.getVerificationForDate(
        _businessDate,
      );

      List<StockVerificationItem> items = [];

      if (verification != null) {
        items = await _verificationDao.getVerificationItems(verification.id);
      }

      final products = await _db.productDao.getAllProducts();

      final productsById = <int, Product>{
        for (final product in products) product.id: product,
      };

      if (!mounted) return;

      setState(() {
        _verification = verification;
        _items = items;
        _productsById = productsById;
        _isLoading = false;
      });

      _syncControllers();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  void _syncControllers() {
    for (final item in _items) {
      final existing = _controllers[item.id];

      if (existing == null) {
        _controllers[item.id] = TextEditingController(
          text: item.physicalCount.toString(),
        );
      } else if (existing.text != item.physicalCount.toString()) {
        existing.text = item.physicalCount.toString();
      }
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  Future<void> _startVerification() async {
    if (!_isCounter) {
      _showMessage('You do not have permission to perform stock counts.');
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final verificationId = await _verificationDao.startVerification(
        businessDate: _businessDate,
        countedByUserId: Session.currentUserId,
      );

      final verification = await _verificationDao.getVerificationById(
        verificationId,
      );

      final items = await _verificationDao.getVerificationItems(verificationId);

      if (!mounted) return;

      setState(() {
        _verification = verification;
        _items = items;
      });

      _syncControllers();

      _showMessage('Stock verification started.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveCount(StockVerificationItem item) async {
    if (!_isDraft || !_isCounter) return;

    final controller = _controllers[item.id];

    if (controller == null) return;

    final value = int.tryParse(controller.text.trim());

    if (value == null || value < 0) {
      controller.text = item.physicalCount.toString();

      _showMessage('Enter a valid physical stock count.');

      return;
    }

    try {
      await _verificationDao.updatePhysicalCount(
        verificationItemId: item.id,
        physicalCount: value,
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    }
  }

  Future<void> _submitVerification() async {
    if (_verification == null) return;

    if (!_isDraft || !_isCounter) return;

    final confirmed = await _showConfirmation(
      title: 'Submit Stock Verification?',
      message:
          'Once submitted, physical counts can no longer be changed. '
          'An owner or manager will review any variance.',
      confirmLabel: 'Submit',
    );

    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _verificationDao.submitVerification(_verification!.id);

      await _load();

      if (!mounted) return;

      _showMessage('Stock verification submitted for review.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _approveVerification() async {
    final verification = _verification;

    if (verification == null || !_isReviewer) return;

    if (!_isSubmitted) return;

    final hasVariance = _items.any((item) => item.variance != 0);

    final confirmed = await _showConfirmation(
      title: 'Approve Stock Verification?',
      message: hasVariance
          ? 'This will apply all non-zero variances as stock '
                'adjustment movements. Continue?'
          : 'No stock variance was found. Approve this '
                'verification as a clean close?',
      confirmLabel: 'Approve',
    );

    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _verificationDao.approveVerification(
        verificationId: verification.id,
        reviewedByUserId: Session.currentUserId,
      );

      await _load();

      if (!mounted) return;

      _showMessage(
        hasVariance
            ? 'Verification approved and stock adjustments applied.'
            : 'Verification approved with no stock adjustment required.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _rejectVerification() async {
    final verification = _verification;

    if (verification == null || !_isReviewer) return;

    if (!_isSubmitted) return;

    final notesController = TextEditingController();

    try {
      final notes = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reject Stock Verification'),
            content: TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter a reason for rejection',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final notes = notesController.text.trim();

                  if (notes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a rejection reason.'),
                      ),
                    );

                    return;
                  }

                  Navigator.of(context).pop(notes);
                },
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );

      if (notes == null) return;

      setState(() {
        _isSaving = true;
      });

      await _verificationDao.rejectVerification(
        verificationId: verification.id,
        reviewedByUserId: Session.currentUserId,
        notes: notes,
      );

      await _load();

      if (!mounted) return;

      _showMessage('Stock verification rejected.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    } finally {
      notesController.dispose();

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _showConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTextStyles.body),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _statusLabel() {
    final status = _verification?.status;

    switch (status) {
      case 'draft':
        return 'DRAFT';
      case 'submitted':
        return 'SUBMITTED';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'NOT STARTED';
    }
  }

  int get _varianceCount {
    return _items.where((item) => item.variance != 0).length;
  }

  int get _positiveVariance {
    return _items
        .where((item) => item.variance > 0)
        .fold<int>(0, (sum, item) => sum + item.variance);
  }

  int get _negativeVariance {
    return _items
        .where((item) => item.variance < 0)
        .fold<int>(0, (sum, item) => sum + item.variance.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Stock Verification', style: AppTextStyles.title),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Physical count and stock closing',
              style: AppTextStyles.small,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isSaving ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSummaryCards(),
              const SizedBox(height: AppSpacing.lg),
              _buildPermissionNotice(),
              const SizedBox(height: AppSpacing.lg),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final dateLabel =
        '${_businessDate.day.toString().padLeft(2, '0')}/'
        '${_businessDate.month.toString().padLeft(2, '0')}/'
        '${_businessDate.year}';

    return _card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.fact_check_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Stock Verification',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Business date: $dateLabel',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          _statusBadge(_statusLabel()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width >= 1000
            ? (width - AppSpacing.lg * 3) / 4
            : width >= 700
            ? (width - AppSpacing.lg) / 2
            : width;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                value: '${_items.length}',
                subtitle: 'Products in verification',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                icon: Icons.warning_amber_outlined,
                title: 'Variances',
                value: '$_varianceCount',
                subtitle: 'Products with variance',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                icon: Icons.add_circle_outline,
                title: 'Overages',
                value: '$_positiveVariance',
                subtitle: 'Units above expected',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                icon: Icons.remove_circle_outline,
                title: 'Shortages',
                value: '$_negativeVariance',
                subtitle: 'Units below expected',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return _card(
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSpacing.xl,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.small),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: AppTextStyles.price),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionNotice() {
    if (_isReviewer && !_isCounter) {
      return _notice(
        icon: Icons.verified_user_outlined,
        title: 'Review mode',
        message:
            'You are signed in as an owner or manager. '
            'Submitted stock verifications can be reviewed and approved here.',
      );
    }

    if (!_isCounter) {
      return _notice(
        icon: Icons.lock_outline,
        title: 'Stock counting permission required',
        message:
            'Your employee profile does not currently allow physical stock counting. '
            'Ask an owner or manager to enable the stock counting permission.',
      );
    }

    if (_isSubmitted) {
      return _notice(
        icon: Icons.hourglass_top_outlined,
        title: 'Verification submitted',
        message:
            'The physical count has been submitted. '
            'It can no longer be changed until it is reviewed.',
      );
    }

    if (_isApproved) {
      return _notice(
        icon: Icons.check_circle_outline,
        title: 'Verification approved',
        message: 'This verification has been reviewed and approved.',
      );
    }

    if (_isRejected) {
      return _notice(
        icon: Icons.cancel_outlined,
        title: 'Verification rejected',
        message:
            'This verification was rejected. A new verification can be started for the next closing cycle.',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildContent() {
    if (_verification == null) {
      if (_isCounter) {
        return _buildStartCard();
      }

      return _notice(
        icon: Icons.pending_actions_outlined,
        title: 'No verification for today',
        message: 'There is no stock verification available for today.',
      );
    }

    if (_items.isEmpty) {
      return _notice(
        icon: Icons.inventory_outlined,
        title: 'No products in verification',
        message: 'This verification does not contain any product items.',
      );
    }

    return _buildVerificationTable();
  }

  Widget _buildStartCard() {
    return _card(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.play_circle_outline, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Start Today\'s Stock Verification',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The system will capture the current Products.stock value '
            'as the expected stock for every product. You will then '
            'enter the physical quantities found in the store.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _isSaving ? null : _startVerification,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTable() {
    final editable = _isDraft && _isCounter;

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isReviewer && _isSubmitted
                            ? 'Verification Review'
                            : 'Physical Stock Count',
                        style: AppTextStyles.heading,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        editable
                            ? 'Enter the physical quantity found for each product.'
                            : 'Expected system stock compared with the physical count.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),
                if (editable)
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submitVerification,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Submit Verification'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 36,
              headingRowHeight: 52,
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(numeric: true, label: Text('Expected')),
                DataColumn(numeric: true, label: Text('Physical')),
                DataColumn(numeric: true, label: Text('Variance')),
                DataColumn(label: Text('Status')),
              ],
              rows: [
                for (final item in _items)
                  _buildItemRow(item, editable: editable),
              ],
            ),
          ),
          if (_isReviewer && _isSubmitted) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _rejectVerification,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _approveVerification,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  DataRow _buildItemRow(StockVerificationItem item, {required bool editable}) {
    final product = _productsById[item.productId];

    final variance = item.variance;

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              product?.name ?? 'Product #${item.productId}',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ),
        ),
        DataCell(Text('${item.expectedStock}', style: AppTextStyles.body)),
        DataCell(
          editable
              ? SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _controllers[item.id],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) {
                      _saveCount(item);
                    },
                  ),
                )
              : Text('${item.physicalCount}', style: AppTextStyles.body),
        ),
        DataCell(
          Text(
            variance > 0 ? '+$variance' : '$variance',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(_varianceBadge(variance)),
      ],
    );
  }

  Widget _varianceBadge(int variance) {
    if (variance == 0) {
      return _statusBadge('MATCH', icon: Icons.check);
    }

    if (variance > 0) {
      return _statusBadge('OVER', icon: Icons.arrow_upward);
    }

    return _statusBadge('SHORT', icon: Icons.arrow_downward);
  }

  Widget _statusBadge(String label, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;

    Color background;
    Color foreground;

    switch (label) {
      case 'APPROVED':
      case 'MATCH':
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        break;

      case 'SUBMITTED':
      case 'DRAFT':
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        break;

      case 'REJECTED':
      case 'SHORT':
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        break;

      default:
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
