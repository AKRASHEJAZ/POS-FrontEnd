class CustomerFilters {
  final int? id;
  final String? name;
  final String? email;
  final int page;
  final int pageSize;

  const CustomerFilters({
    this.id,
    this.name,
    this.email,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (id != null) map['id'] = id;
    if (name != null && name!.trim().isNotEmpty) map['name'] = name!.trim();
    if (email != null && email!.trim().isNotEmpty) map['email'] = email!.trim();

    return map;
  }
}

