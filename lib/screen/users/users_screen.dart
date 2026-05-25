import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/user_filters.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/services/user/user_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/screen/users/create_user_dialog.dart';
import 'package:web_end/screen/users/delete_user_dialog.dart';
import 'package:web_end/screen/users/update_user_dialog.dart';
import 'package:web_end/widgets/common/collapsible_filter_panel.dart';
import 'package:web_end/widgets/common/pagination_bar.dart';
import 'package:web_end/widgets/users/users_filter_bar.dart';

enum _UserSortColumn { name, email, role, status, createdAt }

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  int _pageSize = kDefaultPageSize;

  final _userService = UserService();
  final _nameController = TextEditingController();

  List<UserModel> _users = [];
  int _page = 1;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _loading = true;
  String? _error;

  String? _statusFilter = 'All';
  String? _roleFilter = 'All';

  _UserSortColumn _sortColumn = _UserSortColumn.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  UserFilters _currentFilters() {
    return UserFilters.fromForm(
      name: _nameController.text,
      status: _statusFilter,
      role: _roleFilter,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _loadUsers({int? page}) async {
    if (page != null && page != _page) {
      setState(() => _page = page);
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _userService.getAllUsers(filters: _currentFilters());

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.message;
        _users = [];
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
        await _loadUsers(page: targetPage);
        return;
      }
    }

    setState(() {
      _loading = false;
      _users = data.items;
      _page = targetPage;
      _totalItems = data.totalItems;
      _totalPages = data.totalPages;
      _sortUsers();
    });
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _loadUsers();
  }

  void _goToPreviousPage() {
    if (_page <= 1 || _loading) return;
    _loadUsers(page: _page - 1);
  }

  void _goToNextPage() {
    if (_page >= _totalPages || _loading) return;
    _loadUsers(page: _page + 1);
  }

  void _onPageSizeChanged(int size) {
    if (size == _pageSize) return;
    setState(() {
      _pageSize = size;
      _page = 1;
    });
    _loadUsers();
  }

  String _subtitleText() {
    if (_loading) return 'Loading...';
    if (_totalItems == 0) return 'No users';
    if (_totalPages <= 1) {
      return '$_totalItems user${_totalItems == 1 ? '' : 's'}';
    }
    return '$_totalItems users · page $_page of $_totalPages';
  }

  Future<void> _openCreateUser() async {
    final created = await CreateUserDialog.show(context);
    if (created == true) _loadUsers();
  }

  Future<void> _openUpdateUser(UserModel user) async {
    final updated = await UpdateUserDialog.show(context, user);
    if (updated == true) _loadUsers();
  }

  Future<void> _openDeleteUser(UserModel user) async {
    final deleted = await DeleteUserDialog.show(context, user);
    if (deleted == true) _loadUsers();
  }

  void _clearFilters() {
    _nameController.clear();
    setState(() {
      _statusFilter = 'All';
      _roleFilter = 'All';
      _page = 1;
    });
    _loadUsers();
  }

  void _onSort(_UserSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _sortUsers();
    });
  }

  void _sortUsers() {
    final sorted = List<UserModel>.from(_users);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case _UserSortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _UserSortColumn.email:
          cmp = a.email.toLowerCase().compareTo(b.email.toLowerCase());
        case _UserSortColumn.role:
          cmp = (a.role ?? '').toLowerCase().compareTo((b.role ?? '').toLowerCase());
        case _UserSortColumn.status:
          cmp = a.isActive == b.isActive ? 0 : (a.isActive ? -1 : 1);
        case _UserSortColumn.createdAt:
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aDate.compareTo(bDate);
      }
      return _sortAscending ? cmp : -cmp;
    });
    _users = sorted;
  }

  int? _columnIndex(_UserSortColumn column) {
    return _sortColumn == column ? column.index : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Users', style: AppTheme.title(context)),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleText(),
                      style: AppTheme.subtitle(context),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _openCreateUser,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mid,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined, size: 20),
                label: const Text('Create'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _loadUsers,
                icon: const Icon(Icons.refresh, color: AppColors.mid),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleFilterPanel(
            child: UsersFilterBar(
              nameController: _nameController,
              statusValue: _statusFilter,
              roleValue: _roleFilter,
              isLoading: _loading,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onRoleChanged: (value) => setState(() => _roleFilter = value),
              pageSize: _pageSize,
              onPageSizeChanged: _onPageSizeChanged,
              onApply: _applyFilters,
              onClear: _clearFilters,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildBody(context)),
                PaginationBar(
                  page: _page,
                  totalPages: _totalPages,
                  totalItems: _totalItems,
                  pageSize: _pageSize,
                  itemLabel: 'users',
                  loading: _loading,
                  onPrevious: _goToPreviousPage,
                  onNext: _goToNextPage,
                  onPageSizeChanged: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mid),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: AppTheme.body(context)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.soft),
            const SizedBox(height: 12),
            Text('No users match your filters', style: AppTheme.body(context)),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.soft.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.soft.withValues(alpha: 0.15),
                    ),
                    sortColumnIndex: _columnIndex(_sortColumn),
                    sortAscending: _sortAscending,
                    headingTextStyle: AppTheme.label(context)?.copyWith(
                      fontSize: 13,
                    ),
                    dataTextStyle: AppTheme.body(context)?.copyWith(fontSize: 14),
                    columns: [
                      _column('Name', _UserSortColumn.name),
                      _column('Email', _UserSortColumn.email),
                      _column('Role', _UserSortColumn.role),
                      _column('Status', _UserSortColumn.status),
                      _column('Created', _UserSortColumn.createdAt),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: _users.map((u) => _buildRow(context, u)).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DataColumn _column(String label, _UserSortColumn column) {
    return DataColumn(
      label: Text(label),
      onSort: (columnIndex, ascending) => _onSort(column),
    );
  }

  DataRow _buildRow(BuildContext context, UserModel user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.mid,
                child: Text(
                  user.initials,
                  style: AppTheme.apply(
                    const TextStyle(
                      color: AppColors.light,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(user.name)),
            ],
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(
          user.role != null
              ? Chip(
                  label: Text(user.role!),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.soft.withValues(alpha: 0.25),
                  labelStyle: AppTheme.apply(
                    const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deep,
                    ),
                  ),
                )
              : const Text('—'),
        ),
        DataCell(_statusChip(user.isActive)),
        DataCell(Text(_formatDate(user.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit user',
                onPressed: () => _openUpdateUser(user),
                icon: const Icon(Icons.edit_outlined, color: AppColors.mid),
              ),
              IconButton(
                tooltip: 'Delete user',
                onPressed: () => _openDeleteUser(user),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.soft.withValues(alpha: 0.3)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: AppTheme.apply(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.deep : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
