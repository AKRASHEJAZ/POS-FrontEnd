class UnitFilters {
  final String? name;
  final int page;
  final int pageSize;

  const UnitFilters({
    this.name,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (name != null && name!.trim().isNotEmpty) {
      map['name'] = [name!.trim()];
    }

    return map;
  }
}
