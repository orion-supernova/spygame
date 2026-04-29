/// Base error type used across the app. Datasource exceptions are wrapped
/// into one of these so the presentation layer can show a friendly message.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Connection lost. Please retry.']);
}

class RoomNotFoundException extends AppException {
  const RoomNotFoundException()
      : super('No room with that code. Check it and try again.');
}

class RoomFullException extends AppException {
  const RoomFullException() : super('That room is no longer accepting players.');
}

class NotAuthorizedException extends AppException {
  const NotAuthorizedException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}
