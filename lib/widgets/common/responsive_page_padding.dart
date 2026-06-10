import 'package:flutter/material.dart';

EdgeInsets responsivePagePadding(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final compact = size.width < 700 || size.height < 640;
  return EdgeInsets.all(compact ? 16 : 24);
}
