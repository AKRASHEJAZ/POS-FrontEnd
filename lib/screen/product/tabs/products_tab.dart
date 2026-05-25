import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/category_model.dart';
import 'package:web_end/models/product_filters.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/models/unit_model.dart';
import 'package:web_end/screen/product/dialogs/product_form_dialog.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_delete_dialog.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/product/products_filter_bar.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  int _pageSize = kDefaultPageSize;

  final _service = CatalogService();
  final _searchController = TextEditingController();

  List<ProductModel> _items = [];
  List<CategoryModel> _categories = [];
  List<UnitModel> _units = [];
  int _page = 1;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _loading = true;

  String? _categoryFilter = 'All';
  String? _unitFilter = 'All';
  String? _statusFilter = 'All';

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

  ProductFilters _currentFilters() {
    return ProductFilters.fromForm(
      name: _searchController.text,
      category: _categoryFilter,
      unit: _unitFilter,
      status: _statusFilter,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _loadPickerOptions() async {
    final categories = await _service.getCategoriesForPicker();
    final units = await _service.getUnitsForPicker();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _units = units;
    });
  }

  Future<void> _load({int? page}) async {
    if (page != null && page != _page) {
      setState(() => _page = page);
    }

    setState(() => _loading = true);

    final productsResult = await _service.getProductsPaginated(
      filters: _currentFilters(),
    );

    if (!mounted) return;

    if (_categories.isEmpty || _units.isEmpty) {
      await _loadPickerOptions();
      if (!mounted) return;
    }

    if (!productsResult.isSuccess) {
      setState(() {
        _loading = false;
        _items = [];
        _totalItems = 0;
        _totalPages = 0;
      });
      return;
    }

    final data = productsResult.data;
    var targetPage = data.page;

    if (data.totalPages > 0 && targetPage > data.totalPages) {
      targetPage = data.totalPages;
      if (targetPage != _page) {
        await _load(page: targetPage);
        return;
      }
    }

    setState(() {
      _items = data.items;
      _page = targetPage;
      _totalItems = data.totalItems;
      _totalPages = data.totalPages;
      _loading = false;
    });
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _load();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _categoryFilter = 'All';
      _unitFilter = 'All';
      _statusFilter = 'All';
      _page = 1;
    });
    _load();
  }

  void _goToPreviousPage() {
    if (_page <= 1 || _loading) return;
    _load(page: _page - 1);
  }

  void _goToNextPage() {
    if (_page >= _totalPages || _loading) return;
    _load(page: _page + 1);
  }

  void _onPageSizeChanged(int size) {
    if (size == _pageSize) return;
    setState(() {
      _pageSize = size;
      _page = 1;
    });
    _load();
  }

  String _countLabel() {
    if (_loading) return 'Loading...';
    if (_totalPages <= 1) return '$_totalItems products';
    return '$_totalItems products · page $_page of $_totalPages';
  }

  Future<void> _openForm([ProductModel? item]) async {
    if (_categories.isEmpty || _units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add categories and units before creating products.'),
        ),
      );
      return;
    }
    final ok = await ProductFormDialog.show(
      context,
      product: item,
      categories: _categories,
      units: _units,
    );
    if (ok == true) {
      await _loadPickerOptions();
      _load();
    }
  }

  Future<void> _delete(ProductModel item) async {
    final ok = await CatalogDeleteDialog.show(
      context,
      itemLabel: item.name,
      onDelete: () => _service.deleteProduct(item.id),
    );
    if (ok == true) _load();
  }

  Widget _statusChip(bool on, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: on ? AppColors.soft.withValues(alpha: 0.3) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: on ? AppColors.deep : Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _categories.isNotEmpty && _units.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canCreate && !_loading)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.soft.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Add categories and units in their tabs before creating products.',
              style: AppTheme.body(context),
            ),
          ),
        CollapsibleFilterPanel(
          child: ProductsFilterBar(
            nameController: _searchController,
            categoryValue: _categoryFilter,
            unitValue: _unitFilter,
            statusValue: _statusFilter,
            categories: _categories,
            units: _units,
            isLoading: _loading,
            onCategoryChanged: (v) => setState(() => _categoryFilter = v),
            onUnitChanged: (v) => setState(() => _unitFilter = v),
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            pageSize: _pageSize,
            onPageSizeChanged: _onPageSizeChanged,
            onApply: _applyFilters,
            onClear: _clearFilters,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(_countLabel(), style: AppTheme.subtitle(context)),
            const Spacer(),
            FilledButton.icon(
              onPressed: _loading || !canCreate ? null : () => _openForm(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _loading
                  ? null
                  : () async {
                      await _loadPickerOptions();
                      _load();
                    },
              icon: const Icon(Icons.refresh, color: AppColors.mid),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.mid),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              'No products',
                              style: AppTheme.body(context),
                            ),
                          )
                        : CatalogTableCard(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Code')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Unit')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _items
                                .map(
                                  (p) => DataRow(cells: [
                                    DataCell(Text(p.name)),
                                    DataCell(Text(p.internalCode ?? '—')),
                                    DataCell(Text(p.categoryName ?? '—')),
                                    DataCell(Text(p.unitName ?? '—')),
                                    DataCell(
                                      _statusChip(
                                        p.isActive,
                                        p.isActive ? 'Active' : 'Off',
                                      ),
                                    ),
                                    DataCell(catalogActionButtons(
                                      onEdit: () => _openForm(p),
                                      onDelete: () => _delete(p),
                                    )),
                                  ]),
                                )
                                .toList(),
                          ),
              ),
              PaginationBar(
                page: _page,
                totalPages: _totalPages,
                totalItems: _totalItems,
                pageSize: _pageSize,
                itemLabel: 'products',
                loading: _loading,
                onPrevious: _goToPreviousPage,
                onNext: _goToNextPage,
                onPageSizeChanged: null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
