import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_detail_screen.dart';
import '../services/product_service.dart';
import '../widgets/error_state_view.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _service = ProductService();

  List<Product> _products = <Product>[];
  bool _isLoading = true;
  bool _simulateError = false;
  String? _selectedCategory;
  String? _errorMessage;

  static const List<Color> _categoryColors = <Color>[
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF22C55E),
  ];

  List<String> get _categories {
    final Set<String> distinct = _products
        .map((Product item) => item.category)
        .where((String value) => value.trim().isNotEmpty)
        .toSet();

    final List<String> result = distinct.toList()..sort();
    return result;
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == null) {
      return <Product>[];
    }

    return _products
        .where((Product item) => item.category == _selectedCategory!)
        .toList();
  }

  String _formatCategoryLabel(String value) {
    if (value == 'smartphones') return 'Điện thoại';
    if (value == 'laptops') return 'Laptop';
    if (value == 'tablets') return 'Máy tính bảng';
    if (value == 'mobile-accessories') return 'Phụ kiện di động';

    return value;
  }

  String? _previewImageForCategory(String category) {
    try {
      return _products
          .firstWhere((Product item) => item.category == category)
          .image;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Product> data =
          await _service.fetchProducts(forceError: _simulateError);
      if (!mounted) {
        return;
      }
      setState(() {
        _products = data;
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _toggleSimulatedError() {
    setState(() {
      _simulateError = !_simulateError;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: Text(
          _selectedCategory == null
              ? 'TH3 - Phan Văn Tâm - 2351160549'
              : 'Danh sách sản phẩm',
        ),
        leading: _selectedCategory != null
            ? IconButton(
                tooltip: 'Quay lại danh mục',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
              )
            : null,
        actions: [
          if (_selectedCategory != null)
            IconButton(
              tooltip: 'Bỏ chọn danh mục',
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              icon: const Icon(Icons.filter_alt_off),
            ),
          IconButton(
            tooltip: _simulateError ? 'Tắt giả lập lỗi' : 'Giả lập lỗi mạng',
            onPressed: _toggleSimulatedError,
            icon: Icon(
              _simulateError ? Icons.wifi_off : Icons.wifi,
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _selectedCategory == null
            ? _buildCategoryHome()
            : _buildProductListByCategory(),
      ),
    );
  }

  Widget _buildCategoryHome() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _simulateError = false;
          });
          _loadProducts();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        key: const ValueKey<String>('category-home'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFCCFBF1), Color(0xFFE0F2FE)],
              ),
            ),
            child: Text(
              'Chọn danh mục sản phẩm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (BuildContext context, int index) {
              final String category = _categories[index];
              final Color swatch =
                  _categoryColors[index % _categoryColors.length];
              final String? previewImage = _previewImageForCategory(category);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: swatch.withValues(alpha: 0.12),
                    border: Border.all(
                      color: swatch.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: previewImage == null
                                ? const Icon(Icons.image_not_supported)
                                : Image.network(
                                    previewImage,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCategoryLabel(category),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if (_categories.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.devices, size: 38, color: Color(0xFF64748B)),
                  SizedBox(height: 8),
                  Text(
                    'API đồ điện tử hiện chưa có dữ liệu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Nhấn vào một ô danh mục để chuyển sang danh sách sản phẩm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF334155)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductListByCategory() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _simulateError = false;
          });
          _loadProducts();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        key: const ValueKey<String>('product-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFE0F2FE),
            ),
            child: Text(
              'Danh mục: ${_formatCategoryLabel(_selectedCategory!)} (${_filteredProducts.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          if (_filteredProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text('Không có sản phẩm trong danh mục này.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredProducts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final Product product = _filteredProducts[index];

                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
