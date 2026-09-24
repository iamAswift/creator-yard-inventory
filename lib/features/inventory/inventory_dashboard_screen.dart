// lib/features/inventory/inventory_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/styles.dart';
import '../../database/app_database.dart';
import '../../database/daos/product_dao.dart';

class InventoryDashboardScreen extends StatelessWidget {
  final ProductDao productDao;

  const InventoryDashboardScreen({super.key, required this.productDao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ============================================================
          // STOCK OPERATIONS
          // ============================================================
          Text(
            'Stock Operations',
            style: AppTextStyles.heading.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Manage stock movements and verify physical inventory.',
            style: AppTextStyles.bodySecondary,
          ),

          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              final cards = [
                _operationCard(
                  context: context,
                  title: 'Stock Adjustment',
                  subtitle: 'Correct stock quantities when required.',
                  icon: Icons.tune_outlined,
                  color: AppColors.warning,
                  onTap: () {
                    context.push('/stock-adjustment');
                  },
                ),
                _operationCard(
                  context: context,
                  title: 'System Stock Verification',
                  subtitle: 'Count physical stock and close the day.',
                  icon: Icons.fact_check_outlined,
                  color: AppColors.inventory,
                  onTap: () {
                    context.push('/stock-verification');
                  },
                ),
              ];

              if (!isWide) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[1]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // ============================================================
          // CURRENT INVENTORY
          // ============================================================
          Text(
            'Current Inventory',
            style: AppTextStyles.heading.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          const Text(
            'Current stock levels across all products.',
            style: AppTextStyles.bodySecondary,
          ),

          const SizedBox(height: AppSpacing.md),

          FutureBuilder<List<Product>>(
            future: productDao.getAllProducts(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Error loading products:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      'No products found.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }

              final products = snapshot.data!;

              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.5),
                    );
                  },
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isLowStock = product.stock < 10;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      title: Text(
                        product.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Stock: ${product.stock} | '
                        'Cost: ₦${product.costPrice} | '
                        'Price: ₦${product.sellingPrice}',
                      ),
                      trailing: isLowStock
                          ? const Icon(Icons.warning, color: AppColors.danger)
                          : const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STOCK OPERATION CARD
  // ============================================================

  Widget _operationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
