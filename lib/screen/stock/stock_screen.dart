import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/models/stock_filters.dart';
import 'package:web_end/screen/stock/dialogs/add_stock_dialog.dart';
import 'package:web_end/screen/stock/dialogs/stock_batch_detail_dialog.dart';
import 'package:web_end/services/stock/stock_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/stock/stock_filter_bar.dart';

class StockScreen extends StatefulWidget {
  final bool canAddStock;

  const StockScreen({super.key, this.canAddStock = true});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _pageSize = kDefaultPageSize;

  final _stockService = StockService();
  final _batchCodeController = TextEditingController();

  List<InventoryBatchModel> _items = [];
  int _page = 1;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _loading = true;
  String? _error;
  ProductModel? _filterProduct;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _batchCodeController.dispose();
    super.dispose();
  }

  StockFilters _currentFilters() {
    return StockFilters.fromForm(
      batchCode: _batchCodeController.text,
      product: _filterProduct,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _load({int? page}) async {
    if (page != null && page != _page) {
      setState(() => _page = page);
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _stockService.getBatches(filters: _currentFilters());

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load stock.';
        _items = [];
        _totalItems = 0;
        _totalPages = 0;
      });
    }
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _load();
  }

  void _clearFilters() {
    _batchCodeController.clear();
    setState(() {
      _filterProduct = null;
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

  Future<void> _openAdd() async {
    final ok = await AddStockDialog.show(context);
    if (ok == true) _load();
  }

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _subtitleText() {
    if (_loading) return 'Loading...';
    if (_totalItems == 0) return 'No batches';
    if (_totalPages <= 1) {
      return '$_totalItems batch${_totalItems == 1 ? '' : 'es'}';
    }
    return '$_totalItems batch${_totalItems == 1 ? '' : 'es'} · page $_page of $_totalPages';
  }

  Widget _paginationBar() {
    return PaginationBar(
      page: _page,
      totalPages: _totalPages,
      totalItems: _totalItems,
      pageSize: _pageSize,
      itemLabel: 'batches',
      loading: _loading,
      onPrevious: _goToPreviousPage,
      onNext: _goToNextPage,
      onPageSizeChanged: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final listSection = _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mid),
              )
            : _items.isEmpty
            ? Center(
                child: Text('No stock batches', style: AppTheme.body(context)),
              )
            : CatalogTableCard(
                columns: const [
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Purchased amount')),
                  DataColumn(label: Text('Available')),
                  DataColumn(label: Text('Sold')),
                  DataColumn(label: Text('Purchase date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _items
                    .map(
                      (b) => DataRow(
                        cells: [
                          DataCell(Text(b.productName ?? '—')),
                          DataCell(Text(_formatQuantity(b.purchaseAmount))),
                          DataCell(Text(_formatQuantity(b.availableStock))),
                          DataCell(Text(_formatQuantity(b.stocks?.sold ?? 0))),
                          DataCell(Text(formatCatalogDate(b.createdAt))),
                          DataCell(
                            IconButton(
                              tooltip: 'View details',
                              onPressed: () =>
                                  StockBatchDetailDialog.show(context, b),
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

        final content = <Widget>[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock', style: AppTheme.title(context)),
                    const SizedBox(height: 4),
                    Text(_subtitleText(), style: AppTheme.subtitle(context)),
                  ],
                ),
              ),
              if (widget.canAddStock)
                FilledButton.icon(
                  onPressed: _loading ? null : _openAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mid,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add stock'),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : () => _load(),
                icon: const Icon(Icons.refresh, color: AppColors.mid),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleFilterPanel(
            child: StockFilterBar(
              batchCodeController: _batchCodeController,
              selectedProduct: _filterProduct,
              onProductSelected: (product) =>
                  setState(() => _filterProduct = product),
              pageSize: _pageSize,
              onPageSizeChanged: _onPageSizeChanged,
              isLoading: _loading,
              onApply: _applyFilters,
              onClear: _clearFilters,
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
        ];

        if (hasBoundedHeight) {
          content.add(
            Expanded(
              child: Column(
                children: [
                  Expanded(child: listSection),
                  _paginationBar(),
                ],
              ),
            ),
          );
        } else {
          content.add(const SizedBox(height: 16));
          content.add(listSection);
          content.add(_paginationBar());
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        );
      },
    );
  }
}
