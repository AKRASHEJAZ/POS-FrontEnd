class ProductFilters {
  final String? name;
  final int? categoryId;
  final int? unitId;
  final bool? isActive;
  final int page;
  final int pageSize;

  const ProductFilters({
    this.name,
    this.categoryId,
    this.unitId,
    this.isActive,
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
    if (categoryId != null) {
      map['categoryId'] = [categoryId];
    }
    if (unitId != null) {
      map['unitId'] = [unitId];
    }
    if (isActive != null) {
      map['isActive'] = isActive;
    }

    return map;
  }

  factory ProductFilters.fromForm({
    required String name,
    String? category,
    String? unit,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) {
    bool? isActive;
    if (status == 'Active') isActive = true;
    if (status == 'Inactive') isActive = false;

    int? categoryId;
    if (category != null && category != 'All') {
      categoryId = int.tryParse(category);
    }

    int? unitId;
    if (unit != null && unit != 'All') {
      unitId = int.tryParse(unit);
    }

    return ProductFilters(
      name: name,
      categoryId: categoryId,
      unitId: unitId,
      isActive: isActive,
      page: page,
      pageSize: pageSize,
    );
  }
}
