class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
  });

  int get totalPages {
    if (pageSize <= 0) return 0;
    if (totalItems == 0) return 0;
    return (totalItems / pageSize).ceil();
  }

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawItems = json['items'] ?? json['Items'];
    final items = <T>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is! Map) continue;
        try {
          items.add(fromJsonT(Map<String, dynamic>.from(entry)));
        } catch (_) {
          // Skip malformed rows.
        }
      }
    }

    return PaginatedResult<T>(
      items: items,
      page: readInt(json['page'] ?? json['Page'], fallback: 1),
      pageSize: readInt(json['pageSize'] ?? json['PageSize'], fallback: 10),
      totalItems: readInt(json['totalItems'] ?? json['TotalItems']),
    );
  }

  factory PaginatedResult.empty({int page = 1, int pageSize = 10}) {
    return PaginatedResult<T>(
      items: const [],
      page: page,
      pageSize: pageSize,
      totalItems: 0,
    );
  }

  static int readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
