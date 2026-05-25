class UserFilters {
  final String? name;
  final List<String>? roles;
  final bool? isActive;
  final int page;
  final int pageSize;

  const UserFilters({
    this.name,
    this.roles,
    this.isActive,
    this.page = 1,
    this.pageSize = 10,
  });

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) &&
      (roles == null || roles!.isEmpty) &&
      isActive == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (name != null && name!.trim().isNotEmpty) {
      map['name'] = name!.trim();
    }
    if (roles != null && roles!.isNotEmpty) {
      map['roles'] = roles;
    }
    if (isActive != null) {
      map['isActive'] = isActive;
    }

    return map;
  }

  factory UserFilters.fromForm({
    required String name,
    String? status,
    String? role,
    int page = 1,
    int pageSize = 10,
  }) {
    bool? isActive;
    if (status == 'Active') isActive = true;
    if (status == 'Inactive') isActive = false;

    List<String>? roles;
    if (role != null && role != 'All') {
      roles = [role];
    }

    return UserFilters(
      name: name,
      roles: roles,
      isActive: isActive,
      page: page,
      pageSize: pageSize,
    );
  }
}
