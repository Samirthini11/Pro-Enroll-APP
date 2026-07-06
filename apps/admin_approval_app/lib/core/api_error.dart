import '../data/api/api_exception.dart';

String apiErrorMessage(Object error, {String fallback = 'Something went wrong'}) {
  if (error is ApiException) {
    return error.message;
  }
  return fallback;
}
