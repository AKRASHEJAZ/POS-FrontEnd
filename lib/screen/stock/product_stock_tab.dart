import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/product_stock_model.dart';
import 'package:web_end/services/stock/stock_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/common/responsive_page_padding.dart';

class ProductStockTab extends StatefulWidget {
  const ProductStockTab({super.key});

  @override
  State<ProductStockTab> createState() => _ProductStockTabState();
}

class _ProductStockTabState extends State<ProductStockTab> {
  final _stockService = StockService();
  final _searchController = TextEditingController();

  List<ProductStockModel> _allItems = [];
  List<ProductStockModel> _filtered = [];
  List<String> _categories = [];
  // Filters
  String? _pendingCategory;
  String _pendingStockStatus = 'All';

  String? _selectedCategory;
  String _stockStatus = 'All'; // 'All' | 'In Stock' | 'Out of Stock'

  int _page = 1;
  int _pageSize = kDefaultPageSize;

  bool _loading = true;
  String? _error;

  static const _stockStatusOptions = ['All', 'In Stock', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _stockService.getProductStock();

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.message;
        _allItems = [];
        _filtered = [];
        _categories = [];
      });
      return;
    }

    final items = result.data;

    // Collect unique categories
    final cats = items.map((e) => e.category ?? '').where((c) => c.isNotEmpty).toSet().toList()
      ..sort();

    setState(() {
      _allItems = items;
      _categories = cats;
      _loading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    var filtered = _allItems.where((item) {
      // Search filter
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query)) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null) {
        if ((item.category ?? '') != _selectedCategory) return false;
      }

      // Stock status filter
      if (_stockStatus == 'In Stock' && item.availableStock <= 0) return false;
      if (_stockStatus == 'Out of Stock' && item.availableStock > 0) return false;

      return true;
    }).toList();

    setState(() {
      _filtered = filtered;
      _page = 1;
    });
  }

  void _applyFilterClick() {
    setState(() {
      _selectedCategory = _pendingCategory;
      _stockStatus = _pendingStockStatus;
    });
    _applyFilters();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _pendingCategory = null;
      _pendingStockStatus = 'All';
      _selectedCategory = null;
      _stockStatus = 'All';
      _page = 1;
    });
    _applyFilters();
  }

  // ─── Local pagination ───────────────────────────────────────────────────────
  int get _totalItems => _filtered.length;
  int get _totalPages => (_totalItems / _pageSize).ceil().clamp(1, 99999);

  List<ProductStockModel> get _pageItems {
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _totalItems);
    if (start >= _totalItems) return [];
    return _filtered.sublist(start, end);
  }

  void _previousPage() {
    if (_page > 1) setState(() => _page--);
  }

  void _nextPage() {
    if (_page < _totalPages) setState(() => _page++);
  }

  void _onPageSizeChanged(int size) {
    if (size == _pageSize) return;
    setState(() {
      _pageSize = size;
      _page = 1;
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  String _formatQty(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Color _availableColor(double v) {
    if (v <= 0) return Colors.red.shade600;
    if (v < 10) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  Widget _badge(double v) {
    final color = _availableColor(v);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _formatQty(v),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ─── Subtitle ─────────────────────────────────────────────────────────────
  String _subtitleText() {
    if (_loading) return 'Loading…';
    if (_totalItems == 0) return 'No products';
    if (_totalPages <= 1) return '$_totalItems product${_totalItems == 1 ? '' : 's'}';
    return '$_totalItems product${_totalItems == 1 ? '' : 's'} · page $_page of $_totalPages';
  }

  // ─── Filter panel ─────────────────────────────────────────────────────────
  Widget _filterContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final fieldWidth = isWide ? 220.0 : constraints.maxWidth;

        final filters = [
          // Search
          SizedBox(
            width: isWide ? 230 : fieldWidth,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'Search by product name',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => _applyFilterClick(),
            ),
          ),

          // Category dropdown
          SizedBox(
            width: isWide ? 200 : fieldWidth,
            child: DropdownButtonFormField<String>(
              initialValue: _pendingCategory,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('All categories')),
                ..._categories.map(
                  (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) {
                setState(() => _pendingCategory = v);
              },
            ),
          ),

          // Stock status dropdown
          SizedBox(
            width: isWide ? 180 : fieldWidth,
            child: DropdownButtonFormField<String>(
              initialValue: _pendingStockStatus,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Stock status',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _stockStatusOptions
                  .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _pendingStockStatus = v);
                }
              },
            ),
          ),
        ];

        final actions = [
          _pageSizeSelector(),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _applyFilterClick,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mid,
              minimumSize: const Size(100, 44),
            ),
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Apply'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _loading ? null : _clearFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deep,
              minimumSize: const Size(88, 44),
              side: BorderSide(color: AppColors.mid.withValues(alpha: 0.5)),
            ),
            child: const Text('Clear'),
          ),
        ];

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: filters),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...filters.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: f,
                )),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        );
      },
    );
  }

  Widget _pageSizeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Rows'),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: kPageSizeOptions.contains(_pageSize)
                ? _pageSize
                : kPageSizeOptions.first,
            isDense: true,
            borderRadius: BorderRadius.circular(10),
            items: kPageSizeOptions
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text('$size'),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (size) {
                    if (size != null) _onPageSizeChanged(size);
                  },
          ),
        ),
      ],
    );
  }

  // ─── Table ────────────────────────────────────────────────────────────────
  Widget _table() {
    final rows = _pageItems;
    if (rows.isEmpty) {
      return Center(child: Text('No products found', style: AppTheme.body(context)));
    }

    return CatalogTableCard(
      columns: const [
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Unit')),
        DataColumn(label: Text('Purchased'), numeric: true),
        DataColumn(label: Text('Sold'), numeric: true),
        DataColumn(label: Text('Damaged'), numeric: true),
        DataColumn(label: Text('Returned'), numeric: true),
        DataColumn(label: Text('Available'), numeric: true),
      ],
      rows: rows.map((item) {
        return DataRow(
          cells: [
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            DataCell(Text(item.category ?? '—')),
            DataCell(Text(item.unit ?? '—')),
            DataCell(Text(_formatQty(item.purchasedAmount))),
            DataCell(Text(_formatQty(item.soldAmount))),
            DataCell(Text(_formatQty(item.damagedAmount))),
            DataCell(Text(_formatQty(item.returnedAmount))),
            DataCell(_badge(item.availableStock)),
          ],
        );
      }).toList(),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight =
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight >= 640;

        final paginationBar = PaginationBar(
          page: _page,
          totalPages: _loading ? 1 : _totalPages,
          totalItems: _loading ? 0 : _totalItems,
          pageSize: _pageSize,
          itemLabel: 'products',
          loading: _loading,
          onPrevious: _previousPage,
          onNext: _nextPage,
          onPageSizeChanged: null,
        );

        final tableSection = _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.mid))
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  )
                : _table();

        final content = <Widget>[
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Stock', style: AppTheme.title(context)),
                    const SizedBox(height: 4),
                    Text(_subtitleText(), style: AppTheme.subtitle(context)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, color: AppColors.mid),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters
          CollapsibleFilterPanel(
            child: _filterContent(),
          ),
          const SizedBox(height: 12),
        ];

        if (hasBoundedHeight) {
          content.add(
            Expanded(
              child: Column(
                children: [
                  Expanded(child: tableSection),
                  paginationBar,
                ],
              ),
            ),
          );
        } else {
          content.add(const SizedBox(height: 16));
          content.add(tableSection);
          content.add(paginationBar);
        }

        final page = Padding(
          padding: responsivePagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        );

        return hasBoundedHeight ? page : SingleChildScrollView(child: page);
      },
    );
  }
}
