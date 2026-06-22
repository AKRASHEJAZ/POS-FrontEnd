import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/sale_filters.dart';
import 'package:web_end/models/sale_view_model.dart';
import 'package:web_end/screen/sale/sale_detail_dialog.dart';
import 'package:web_end/services/receipt/receipt_service.dart';
import 'package:web_end/services/sale/sale_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/sale/sales_filter_bar.dart';

class SalesHistoryTab extends StatefulWidget {
  const SalesHistoryTab({super.key});

  @override
  State<SalesHistoryTab> createState() => _SalesHistoryTabState();
}

class _SalesHistoryTabState extends State<SalesHistoryTab> {
  final _service = SaleService();
  final _saleIdController = TextEditingController();
  final _customerIdController = TextEditingController();

  bool _loading = false;
  String? _error;

  List<SaleModel> _items = [];
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
    _saleIdController.dispose();
    _customerIdController.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.getSales(
      filters: SaleFilters(
        id: _parseInt(_saleIdController),
        customerId: _parseInt(_customerIdController),
        page: targetPage,
        pageSize: _pageSize,
        includeActions: true,
        includeCustomer: true,
        includeUser: true,
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
    _saleIdController.clear();
    _customerIdController.clear();
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
    if (_totalItems == 0) return 'No sales';
    if (_totalPages <= 1) {
      return '$_totalItems sale${_totalItems == 1 ? '' : 's'}';
    }
    return '$_totalItems sales · page $_page of $_totalPages';
  }

  String _date(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double _computedTotal(SaleModel s) {
    if (s.actions.isEmpty) return s.totalAmount;
    return s.actions.fold<double>(0, (sum, a) => sum + a.lineTotal);
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
        ? Center(child: Text('No sales found', style: AppTheme.body(context)))
        : CatalogTableCard(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Created by')),
              DataColumn(label: Text('')),
            ],
            rows: _items
                .map(
                  (s) => DataRow(
                    cells: [
                      DataCell(Text('${s.id}')),
                      DataCell(Text(_date(s.saleDate))),
                      DataCell(Text(s.customer?.name ?? '—')),
                      DataCell(Text(_computedTotal(s).toStringAsFixed(2))),
                      DataCell(Text(s.createdBy?.name ?? '—')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Print receipt',
                              onPressed: () => ReceiptService.printReceipt(sale: s),
                              icon: const Icon(
                                Icons.print,
                                color: AppColors.mid,
                              ),
                            ),
                            IconButton(
                              tooltip: 'View details',
                              onPressed: () => SaleDetailDialog.show(context, s),
                              icon: const Icon(
                                Icons.info_outline,
                                color: AppColors.mid,
                              ),
                            ),
                          ],
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
            child: SalesFilterBar(
              saleIdController: _saleIdController,
              customerIdController: _customerIdController,
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

        if (hasRoomForPinnedTable) {
          content.add(
            Expanded(
              child: Column(
                children: [
                  Expanded(child: body),
                  PaginationBar(
                    page: _page,
                    totalPages: _totalPages,
                    totalItems: _totalItems,
                    pageSize: _pageSize,
                    itemLabel: 'sales',
                    loading: _loading,
                    onPrevious: _goToPreviousPage,
                    onNext: _goToNextPage,
                    onPageSizeChanged: null,
                  ),
                ],
              ),
            ),
          );
        } else {
          content.add(body);
          content.add(
            PaginationBar(
              page: _page,
              totalPages: _totalPages,
              totalItems: _totalItems,
              pageSize: _pageSize,
              itemLabel: 'sales',
              loading: _loading,
              onPrevious: _goToPreviousPage,
              onNext: _goToNextPage,
              onPageSizeChanged: null,
            ),
          );
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
