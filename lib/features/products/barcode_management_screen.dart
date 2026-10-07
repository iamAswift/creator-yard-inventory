import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/theme/styles.dart';
import '../../database/app_database.dart';
import '../../database/daos/product_dao.dart';
import '../../features/products/barcode_printing_service.dart';

class BarcodeManagementScreen extends StatefulWidget {
  const BarcodeManagementScreen({super.key});

  @override
  State<BarcodeManagementScreen> createState() =>
      _BarcodeManagementScreenState();
}

class _BarcodeManagementScreenState
    extends State<BarcodeManagementScreen> {
  late final ProductDao _productDao;

  final TextEditingController _searchController =
      TextEditingController();

  List<Product> _allProducts = [];
  final Set<int> _selectedProductIds = <int>{};

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _productDao = getProductDao();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productDao.getAllProducts();

      if (!mounted) return;

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load products: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _allProducts;
    }

    return _allProducts.where((product) {
      final name = product.name.toLowerCase();
      final brand = (product.brand ?? '').toLowerCase();
      final barcode = (product.barcode ?? '').toLowerCase();

      return name.contains(query) ||
          brand.contains(query) ||
          barcode.contains(query);
    }).toList();
  }

  void _toggleProduct(Product product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
      } else {
        _selectedProductIds.add(product.id);
      }
    });
  }

  void _toggleAllVisibleProducts() {
    final visibleProducts = _filteredProducts;

    if (visibleProducts.isEmpty) {
      return;
    }

    final allSelected = visibleProducts.every(
      (product) => _selectedProductIds.contains(product.id),
    );

    setState(() {
      if (allSelected) {
        for (final product in visibleProducts) {
          _selectedProductIds.remove(product.id);
        }
      } else {
        for (final product in visibleProducts) {
          _selectedProductIds.add(product.id);
        }
      }
    });
  }


  Future<void> _generateMissingBarcodes() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one product first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedProducts = _allProducts
        .where((product) => _selectedProductIds.contains(product.id))
        .toList();

    var generatedCount = 0;
    var skippedCount = 0;

    try {
      for (final product in selectedProducts) {
        final existingBarcode = product.barcode?.trim() ?? '';

        if (existingBarcode.isNotEmpty) {
          skippedCount++;
          continue;
        }

        String barcode;

        do {
          barcode =
              '20${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

          if (await _productDao.findByBarcode(barcode) != null) {
            await Future<void>.delayed(
              const Duration(milliseconds: 1),
            );
          }
        } while (await _productDao.findByBarcode(barcode) != null);

        final updatedProduct = product.copyWith(
          barcode: drift.Value(barcode),
        );

        final updated = await _productDao.updateProduct(updatedProduct);

        if (!updated) {
          throw Exception(
            'Unable to save barcode for ${product.name}.',
          );
        }

        generatedCount++;
      }

      await _loadProducts();

      if (!mounted) return;

      final message = skippedCount == 0
          ? '$generatedCount barcode${generatedCount == 1 ? '' : 's'} generated.'
          : '$generatedCount generated, $skippedCount already had barcodes.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to generate barcodes: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _printSelectedBarcodes() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one product first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedProducts = _allProducts
        .where(
          (product) => _selectedProductIds.contains(product.id),
        )
        .toList();

    final items = <({String productName, String barcode})>[];
    var skippedCount = 0;

    for (final product in selectedProducts) {
      final barcode = product.barcode?.trim() ?? '';

      if (barcode.isEmpty) {
        skippedCount++;
        continue;
      }

      items.add(
        (
          productName: product.name,
          barcode: barcode,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'None of the selected products has a barcode.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await BarcodePrintingService.printMultipleA4(
        items: items,
      );

      if (!mounted) return;

      final message = skippedCount == 0
          ? '${items.length} barcode${items.length == 1 ? '' : 's'} sent to print.'
          : '${items.length} sent to print, '
              '$skippedCount without barcodes skipped.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to print barcodes: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportSelectedBarcodes() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one product first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedProducts = _allProducts
        .where(
          (product) => _selectedProductIds.contains(product.id),
        )
        .toList();

    final items = <({String productName, String barcode})>[];
    var skippedCount = 0;

    for (final product in selectedProducts) {
      final barcode = product.barcode?.trim() ?? '';

      if (barcode.isEmpty) {
        skippedCount++;
        continue;
      }

      items.add(
        (
          productName: product.name,
          barcode: barcode,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'None of the selected products has a barcode.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final file = await BarcodePrintingService.exportMultipleA4(
        items: items,
      );

      if (!mounted) return;

      final message = skippedCount == 0
          ? '${items.length} barcode${items.length == 1 ? '' : 's'} exported.'
          : '${items.length} exported, '
              '$skippedCount without barcodes skipped.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message Saved to ${file.path}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export barcodes: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Barcode Management',
          style: AppTextStyles.heading,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 52,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search product, brand, or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '${products.length} product${products.length == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySecondary,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: products.isEmpty
                      ? null
                      : _toggleAllVisibleProducts,
                  icon: const Icon(Icons.select_all, size: 18),
                  label: Text(
                    products.isNotEmpty &&
                            products.every(
                              (product) =>
                                  _selectedProductIds.contains(product.id),
                            )
                        ? 'Clear Visible'
                        : 'Select Visible',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : products.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          24,
                        ),
                        itemCount: products.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final selected =
                              _selectedProductIds.contains(product.id);
                          final barcode =
                              product.barcode?.trim() ?? '';

                          return Card(
                            margin: EdgeInsets.zero,
                            child: CheckboxListTile(
                              value: selected,
                              onChanged: (_) =>
                                  _toggleProduct(product),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: Text(
                                product.name,
                                style: AppTextStyles.title,
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (product.brand != null &&
                                      product.brand!.trim().isNotEmpty)
                                    Text(
                                      product.brand!.trim(),
                                      style:
                                          AppTextStyles.bodySecondary,
                                    ),
                                  const SizedBox(height: 3),
                                  Text(
                                    barcode.isEmpty
                                        ? 'No barcode'
                                        : barcode,
                                    style: TextStyle(
                                      color: barcode.isEmpty
                                          ? AppColors.danger
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              secondary: Icon(
                                barcode.isEmpty
                                    ? Icons.qr_code_2_outlined
                                    : Icons.qr_code_2,
                                color: barcode.isEmpty
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, -2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Selected: ${_selectedProductIds.length}',
                    style: AppTextStyles.title,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _selectedProductIds.isEmpty
                        ? null
                        : _generateMissingBarcodes,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Generate Missing'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedProductIds.isEmpty
                        ? null
                        : _printSelectedBarcodes,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print Selected'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedProductIds.isEmpty
                        ? null
                        : _exportSelectedBarcodes,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export Selected'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
