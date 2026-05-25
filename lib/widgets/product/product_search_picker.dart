import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_end/models/product_filters.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

/// Search products by name via API — for filters and forms with large catalogs.
class ProductSearchPicker extends StatefulWidget {
  final String label;
  final ProductModel? selected;
  final ValueChanged<ProductModel?> onSelected;
  final bool enabled;
  final bool allowClear;

  const ProductSearchPicker({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.allowClear = true,
  });

  @override
  State<ProductSearchPicker> createState() => _ProductSearchPickerState();
}

class _ProductSearchPickerState extends State<ProductSearchPicker> {
  final _catalog = CatalogService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ProductModel> _results = [];
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _searchError = query.isEmpty ? null : 'Type at least 2 characters';
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });

    final result = await _catalog.getProductsPaginated(
      filters: ProductFilters(name: query, page: 1, pageSize: 20),
    );

    if (!mounted) return;
    final results = result.isSuccess ? result.data.items : <ProductModel>[];
    setState(() {
      _searching = false;
      _results = results;
      if (results.isEmpty) {
        _searchError = 'No products found for "$query"';
      }
    });
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runSearch);
  }

  void _select(ProductModel product) {
    widget.onSelected(product);
    setState(() {
      _results = [];
      _searchError = null;
    });
    _searchController.clear();
  }

  void _clearSelection() {
    if (!widget.allowClear) return;
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selected != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.soft.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.soft.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 20, color: AppColors.mid),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selected!.name,
                        style: AppTheme.body(context)
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.selected!.internalCode != null &&
                          widget.selected!.internalCode!.isNotEmpty)
                        Text(
                          widget.selected!.internalCode!,
                          style: AppTheme.subtitle(context)?.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (widget.allowClear && enabled)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: _clearSelection,
                    icon: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _searchController,
                label: widget.label,
                hint: 'Search by product name',
                prefixIcon: Icons.search,
                onSubmitted: enabled ? (_) => _runSearch() : null,
                onChanged: enabled ? _onQueryChanged : null,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: FilledButton(
                onPressed: enabled && !_searching ? _runSearch : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mid,
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: _searching
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.light,
                        ),
                      )
                    : const Icon(Icons.search, size: 22),
              ),
            ),
          ],
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 0,
            color: AppColors.light,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.soft.withValues(alpha: 0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.soft.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      p.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(context),
                    ),
                    subtitle: Text(
                      [
                        if (p.internalCode != null && p.internalCode!.isNotEmpty)
                          p.internalCode,
                        if (p.categoryName != null) p.categoryName,
                      ].whereType<String>().join(' · '),
                      style: AppTheme.subtitle(context)?.copyWith(fontSize: 12),
                    ),
                    onTap: enabled ? () => _select(p) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
