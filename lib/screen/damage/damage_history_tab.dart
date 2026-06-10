import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/damage_filters.dart';
import 'package:web_end/models/damage_view_model.dart';
import 'package:web_end/screen/damage/damage_detail_dialog.dart';
import 'package:web_end/services/damage/damage_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/damage/damage_filter_bar.dart';

class DamageHistoryTab extends StatefulWidget {
  const DamageHistoryTab({super.key});

  @override
  State<DamageHistoryTab> createState() => _DamageHistoryTabState();
}

class _DamageHistoryTabState extends State<DamageHistoryTab> {
  final _service = DamageService();
  final _damageIdController = TextEditingController();
  final _batchIdController = TextEditingController();
  final _productIdController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<DamageModel> _items = [];
  int _page = 1;
  int _pageSize = kDefaultPageSize;
  int _totalItems = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _damageIdController.dispose();
    _batchIdController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  String _date(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _countLabel() {
    if (_loading) return 'Loading...';
    if (_totalItems == 0) return 'No damage records';
    if (_totalPages <= 1) {
      return '$_totalItems damage record${_totalItems == 1 ? '' : 's'}';
    }
    return '$_totalItems damage records · page $_page of $_totalPages';
  }

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.getDamages(
      filters: DamageFilters(
        id: _parseInt(_damageIdController),
        inventoryBatchId: _parseInt(_batchIdController),
        productId: _parseInt(_productIdController),
        page: targetPage,
        pageSize: _pageSize,
        includeActions: true,
        includeInventoryBatch: true,
      ),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.message;
        _items = [];
        _totalItems = 0;
        _totalPages = 0;
      });
      return;
    }

    final data = result.data;
    var resolvedPage = data.page;
    if (data.totalPages > 0 && resolvedPage > data.totalPages) {
      resolvedPage = data.totalPages;
      if (resolvedPage != _page) {
        await _load(page: resolvedPage);
        return;
      }
    }

    setState(() {
      _loading = false;
      _items = data.items;
      _page = resolvedPage;
      _totalItems = data.totalItems;
      _totalPages = data.totalPages;
    });
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _load();
  }

  void _clearFilters() {
    _damageIdController.clear();
    _batchIdController.clear();
    _productIdController.clear();
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

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.mid))
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Text(_error!, style: AppTheme.body(context)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        : _items.isEmpty
        ? Center(
            child: Text(
              'No damage records found',
              style: AppTheme.body(context),
            ),
          )
        : CatalogTableCard(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Total qty')),
              DataColumn(label: Text('Created by')),
              DataColumn(label: Text('')),
            ],
            rows: _items
                .map(
                  (damage) => DataRow(
                    cells: [
                      DataCell(Text('${damage.id}')),
                      DataCell(Text(_date(damage.damageDate))),
                      DataCell(
                        Text(_formatQuantity(damage.totalDamagedQuantity)),
                      ),
                      DataCell(Text(damage.createdBy?.name ?? '—')),
                      DataCell(
                        IconButton(
                          tooltip: 'View details',
                          onPressed: () =>
                              DamageDetailDialog.show(context, damage),
                          icon: const Icon(
                            Icons.info_outline,
                            color: AppColors.mid,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRoomForPinnedTable =
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight >= 580;
        final content = <Widget>[
          CollapsibleFilterPanel(
            child: DamageFilterBar(
              damageIdController: _damageIdController,
              batchIdController: _batchIdController,
              productIdController: _productIdController,
              pageSize: _pageSize,
              onPageSizeChanged: _onPageSizeChanged,
              isLoading: _loading,
              onApply: _applyFilters,
              onClear: _clearFilters,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_countLabel(), style: AppTheme.subtitle(context)),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, color: AppColors.mid),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ];

        final pagination = PaginationBar(
          page: _page,
          totalPages: _totalPages,
          totalItems: _totalItems,
          pageSize: _pageSize,
          itemLabel: 'damage records',
          loading: _loading,
          onPrevious: _goToPreviousPage,
          onNext: _goToNextPage,
          onPageSizeChanged: null,
        );

        if (hasRoomForPinnedTable) {
          content.add(
            Expanded(
              child: Column(
                children: [
                  Expanded(child: body),
                  pagination,
                ],
              ),
            ),
          );
        } else {
          content.add(body);
          content.add(pagination);
        }

        final page = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );

        return hasRoomForPinnedTable
            ? page
            : SingleChildScrollView(child: page);
      },
    );
  }
}
