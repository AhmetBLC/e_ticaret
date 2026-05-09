import 'api_exception.dart';

/// Converts any thrown value into a short message suitable for SnackBars / inline UI.
String userFacingErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return error.toString();
}
