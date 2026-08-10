import 'package:flutter/material.dart';

import '../../data/api/api_exception.dart';

void showApiError(BuildContext context, Object error, {String? fallback}) {
  final message = error is ApiException
      ? error.message
      : (fallback ?? 'Something went wrong. Please try again.');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
