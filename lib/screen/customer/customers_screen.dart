import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/customer_filters.dart';
import 'package:web_end/models/customer_model.dart';
import 'package:web_end/screen/customer/create_customer_dialog.dart';
import 'package:web_end/screen/customer/customer_detail_dialog.dart';
import 'package:web_end/services/customer/customer_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/common/responsive_page_padding.dart';
import 'package:web_end/widgets/customer/customer_filter_bar.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _service = CustomerService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = false;
  String? _error;

  List<CustomerModel> _items = [];
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
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _page;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.getCustomers(
      filters: CustomerFilters(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text,
        page: targetPage,
        pageSize: _pageSize,
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
    _nameController.clear();
    _emailController.clear();
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

  String _subtitleText() {
    if (_loading) return 'Loading...';
    if (_totalItems == 0) return 'No customers';
    if (_totalPages <= 1) {
      return '$_totalItems customer${_totalItems == 1 ? '' : 's'}';
    }
    return '$_totalItems customers · page $_page of $_totalPages';
  }

  Future<void> _openAdd() async {
    final ok = await CreateCustomerDialog.show(context);
    if (ok == true) _load();
  }

  Widget _paginationBar() {
    return PaginationBar(
      page: _page,
      totalPages: _totalPages,
      totalItems: _totalItems,
      pageSize: _pageSize,
      itemLabel: 'customers',
      loading: _loading,
      onPrevious: _goToPreviousPage,
      onNext: _goToNextPage,
      onPageSizeChanged: null,
    );
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
            child: Text('No customers found', style: AppTheme.body(context)),
          )
        : CatalogTableCard(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Walk-in')),
              DataColumn(label: Text('Created')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _items
                .map(
                  (c) => DataRow(
                    cells: [
                      DataCell(Text(c.name)),
                      DataCell(Text(c.phone ?? '—')),
                      DataCell(Text(c.email ?? '—')),
                      DataCell(Text(c.isWalkIn ? 'Yes' : 'No')),
                      DataCell(Text(formatCatalogDate(c.createdAt))),
                      DataCell(
                        IconButton(
                          tooltip: 'View',
                          onPressed: () =>
                              CustomerDetailDialog.show(context, c),
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
            constraints.maxHeight >= 640;

        final content = <Widget>[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customers', style: AppTheme.title(context)),
                    const SizedBox(height: 4),
                    Text(_subtitleText(), style: AppTheme.subtitle(context)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _openAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mid,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: const Text('Add customer'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, color: AppColors.mid),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleFilterPanel(
            child: CustomerFilterBar(
              nameController: _nameController,
              emailController: _emailController,
              pageSize: _pageSize,
              onPageSizeChanged: _onPageSizeChanged,
              isLoading: _loading,
              onApply: _applyFilters,
              onClear: _clearFilters,
            ),
          ),
          const SizedBox(height: 12),
        ];

        if (hasRoomForPinnedTable) {
          content.add(
            Expanded(
              child: Column(
                children: [
                  Expanded(child: body),
                  _paginationBar(),
                ],
              ),
            ),
          );
        } else {
          content.add(body);
          content.add(_paginationBar());
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
