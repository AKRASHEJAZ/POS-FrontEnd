import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/unit_filters.dart';
import 'package:web_end/models/unit_model.dart';
import 'package:web_end/screen/product/dialogs/unit_form_dialog.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_delete_dialog.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/catalog/name_filter_bar.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';

class UnitsTab extends StatefulWidget {
  const UnitsTab({super.key});

  @override
  State<UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<UnitsTab> {
  int _pageSize = kDefaultPageSize;

  final _service = CatalogService();
  final _searchController = TextEditingController();

  List<UnitModel> _items = [];
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

  UnitFilters _currentFilters() {
    return UnitFilters(
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

    final result = await _service.getUnitsPaginated(filters: _currentFilters());

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
    if (_totalPages <= 1) return '$_totalItems units';
    return '$_totalItems units · page $_page of $_totalPages';
  }

  Future<void> _openForm([UnitModel? item]) async {
    final ok = await UnitFormDialog.show(context, unit: item);
    if (ok == true) _load();
  }

  Future<void> _delete(UnitModel item) async {
    final ok = await CatalogDeleteDialog.show(
      context,
      itemLabel: item.name,
      onDelete: () => _service.deleteUnit(item.id),
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
            hint: 'Filter unit name',
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
                              'No units',
                              style: AppTheme.body(context),
                            ),
                          )
                        : CatalogTableCard(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Symbol')),
                              DataColumn(label: Text('Created')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _items
                                .map(
                                  (u) => DataRow(cells: [
                                    DataCell(Text(u.name)),
                                    DataCell(Text(u.symbol)),
                                    DataCell(
                                      Text(formatCatalogDate(u.createdAt)),
                                    ),
                                    DataCell(catalogActionButtons(
                                      onEdit: () => _openForm(u),
                                      onDelete: () => _delete(u),
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
                itemLabel: 'units',
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
