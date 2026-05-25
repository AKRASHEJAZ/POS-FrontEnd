class ApiResult {
  final int statusCode;
  final dynamic body;

  const ApiResult({required this.statusCode, required this.body});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
