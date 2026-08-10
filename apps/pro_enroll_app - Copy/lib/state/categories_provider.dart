import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/app_config.dart';
import 'app_state.dart';

/// Fetches work categories from `GET /v1/categories`.
final categoriesProvider = FutureProvider<List<CategoryRef>>((ref) async {
  if (!AppConfig.hasApi) return supportedCategories;
  try {
    final list = await ref.read(repositoryProvider).fetchCategories();
    return list.isNotEmpty ? list : supportedCategories;
  } catch (_) {
    return supportedCategories;
  }
});

/// Sync list for widgets — uses API data when ready, else local fallback.
final categoriesListProvider = Provider<List<CategoryRef>>((ref) {
  final async = ref.watch(categoriesProvider);
  final data = async.valueOrNull;
  if (data != null && data.isNotEmpty) return data;
  return supportedCategories;
});

CategoryRef lookupCategory(List<CategoryRef> categories, String code) {
  return categories.tryByCode(code) ??
      supportedCategories.tryByCode(code) ??
      supportedCategories.first;
}

/// Highest suggested visit fee (₹) from API category data for selected skills.
int suggestedVisitFeeRupees(
  List<CategoryRef> categories,
  Iterable<String> categoryCodes, {
  int fallback = 150,
}) {
  var suggested = fallback;
  for (final code in categoryCodes) {
    final cat = categories.tryByCode(code);
    if (cat != null && cat.defaultVisitFee > suggested) {
      suggested = cat.defaultVisitFee;
    }
  }
  return suggested;
}
