import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/category_filters.dart';
import 'package:web_end/models/category_model.dart';
import 'package:web_end/screen/product/dialogs/category_form_dialog.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_delete_dialog.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/catalog/name_filter_bar.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  int _pageSize = kDefaultPageSize;

  final _service = CatalogService();
  final _searchController = TextEditingController();

  List<CategoryModel> _items = [];
  int _page = 1;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _loading = true;

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

  CategoryFilters _currentFilters() {
    return CategoryFilters(
      name: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _load({int? page}) async {
    if (page != null && page != _page) {
      setState(() => _page = page);
    }

    setState(() => _loading = true);

    final result = await _service.getCategoriesPaginated(
      filters: _currentFilters(),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _items = [];
        _totalItems = 0;
        _totalPages = 0;
      });
      return;
    }

    final data = result.data;
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
    setState(() => _page = 1);
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
    if (_totalPages <= 1) return '$_totalItems categories';
    return '$_totalItems categories · page $_page of $_totalPages';
  }

  Future<void> _openForm([CategoryModel? item]) async {
    final ok = await CategoryFormDialog.show(context, category: item);
    if (ok == true) _load();
  }

  Future<void> _delete(CategoryModel item) async {
    final ok = await CatalogDeleteDialog.show(
      context,
      itemLabel: item.name,
      onDelete: () => _service.deleteCategory(item.id),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CollapsibleFilterPanel(
          child: NameFilterBar(
            nameController: _searchController,
            isLoading: _loading,
            hint: 'Filter category name',
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
              onPressed: _loading ? null : () => _openForm(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _loading ? null : _load,
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
                              'No categories',
                              style: AppTheme.body(context),
                            ),
                          )
                        : CatalogTableCard(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Created')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _items
                                .map(
                                  (c) => DataRow(cells: [
                                    DataCell(Text(c.name)),
                                    DataCell(
                                      Text(formatCatalogDate(c.createdAt)),
                                    ),
                                    DataCell(catalogActionButtons(
                                      onEdit: () => _openForm(c),
                                      onDelete: () => _delete(c),
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
                itemLabel: 'categories',
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
