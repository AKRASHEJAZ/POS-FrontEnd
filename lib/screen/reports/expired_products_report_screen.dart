import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/services/report/report_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/common/responsive_page_padding.dart';

class ExpiredProductsReportScreen extends StatefulWidget {
  const ExpiredProductsReportScreen({super.key});

  @override
  State<ExpiredProductsReportScreen> createState() =>
      _ExpiredProductsReportScreenState();
}

class _ExpiredProductsReportScreenState
    extends State<ExpiredProductsReportScreen> {
  final _service = ReportService();

  // Filters
  DateTime _beforeDate = DateTime.now();
  int _pageSize = kDefaultPageSize;

  // Data
  List<InventoryBatchModel> _items = [];
  int _page = 1;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
      _page = targetPage;
    });

    final result = await _service.getExpiredProducts(
      beforeDate: _beforeDate,
      page: targetPage,
      pageSize: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _items = result.items;
      _totalItems = result.totalItems;
      _totalPages = result.totalPages;
      _page = result.page;
    });
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _load();
  }

  void _clearFilters() {
    setState(() {
      _beforeDate = DateTime.now();
      _page = 1;
    });
    _load();
  }

  void _onPageSizeChanged(int size) {
    if (size == _pageSize) return;
    setState(() {
      _pageSize = size;
      _page = 1;
    });
    _load();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _beforeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Show batches expired by',
    );
    if (picked != null) {
      setState(() => _beforeDate = picked);
    }
  }

  String _fmtQty(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Color _stockColor(double v) {
    if (v <= 0) return Colors.grey;
    if (v < 10) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String _countLabel() {
    if (_loading) return 'Loading...';
    if (_totalItems == 0) return 'No expired batches';
    if (_totalPages <= 1) {
      return '$_totalItems batch${_totalItems == 1 ? '' : 'es'}';
    }
    return '$_totalItems batches · page $_page of $_totalPages';
  }

  // ── Filter panel (matches SalesFilterBar / DamageFilterBar pattern) ────────

  Widget _filterContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final fieldWidth = isWide ? 220.0 : constraints.maxWidth;

        final filters = [
          SizedBox(
            width: isWide ? 220 : fieldWidth,
            child: GestureDetector(
              onTap: _loading ? null : _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expired by date',
                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _formatDate(_beforeDate),
                  style: AppTheme.body(context)?.copyWith(fontSize: 14),
                ),
              ),
            ),
          ),
        ];

        final actions = [
          _pageSizeSelector(),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _applyFilters,
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

  // ── Table ──────────────────────────────────────────────────────────────────

  Widget _table() {
    if (_items.isEmpty) {
      return Center(child: Text('No expired batches found', style: AppTheme.body(context)));
    }

    return CatalogTableCard(
      columns: const [
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Batch ID')),
        DataColumn(label: Text('Expiry Date')),
        DataColumn(label: Text('Available'), numeric: true),
        DataColumn(label: Text('Purchased'), numeric: true),
        DataColumn(label: Text('Sold'), numeric: true),
      ],
      rows: _items.map((b) {
        final avail = b.availableStock;
        final color = _stockColor(avail);
        return DataRow(
          cells: [
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  b.productName ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            DataCell(Text(b.batchCode ?? b.id.toString())),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Colors.red.shade500),
                  const SizedBox(width: 4),
                  Text(
                    b.expiryDate ?? '—',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _fmtQty(avail),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            DataCell(Text(_fmtQty(b.purchaseAmount))),
            DataCell(Text(_fmtQty(b.stocks?.sold ?? 0))),
          ],
        );
      }).toList(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.mid))
        : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade400),
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
                        'No expired batches found',
                        style: AppTheme.body(context)))
                : _table();

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRoomForPinnedTable =
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight >= 580;

        final content = <Widget>[
          // Header row matching stock tabs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expired Products', style: AppTheme.title(context)),
                    const SizedBox(height: 4),
                    Text(_countLabel(), style: AppTheme.subtitle(context)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : () => _load(),
                icon: const Icon(Icons.refresh, color: AppColors.mid),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters
          CollapsibleFilterPanel(child: _filterContent()),
          const SizedBox(height: 16),
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
                    itemLabel: 'batches',
                    loading: _loading,
                    onPrevious:
                        _page > 1 ? () => _load(page: _page - 1) : null,
                    onNext: _page < _totalPages
                        ? () => _load(page: _page + 1)
                        : null,
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
              itemLabel: 'batches',
              loading: _loading,
              onPrevious:
                  _page > 1 ? () => _load(page: _page - 1) : null,
              onNext: _page < _totalPages
                  ? () => _load(page: _page + 1)
                  : null,
              onPageSizeChanged: null,
            ),
          );
        }

        final page = Padding(
          padding: responsivePagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        );

        return hasRoomForPinnedTable
            ? page
            : SingleChildScrollView(child: page);
      },
    );
  }
}
