import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_exception.dart';

extension AppExceptionL10n on AppException {
  /// Resolve a user-facing message at display time. Typed exceptions whose
  /// constructor arguments use the static English fallback resolve to the
  /// localized key; exceptions carrying a server-supplied message
  /// (NotAuthorizedException, ValidationException, and UnknownException
  /// with non-default text) pass through. The server is the authoritative
  /// source for those — localizing them would require threading locale
  /// into every mutation, which is out of scope today.
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = this;
    if (e is RoomNotFoundException) return l10n.errorRoomNotFound;
    if (e is RoomFullException) return l10n.errorRoomFull;
    if (e is NetworkException) {
      return e.message == 'Connection lost. Please retry.'
          ? l10n.errorNetwork
          : e.message;
    }
    if (e is NotAuthorizedException) {
      return e.message == 'Only the host can do that.'
          ? l10n.errorOnlyHost
          : e.message;
    }
    if (e is UnknownException) {
      return e.message == 'Something went wrong.'
          ? l10n.errorUnknown
          : e.message;
    }
    return e.message;
  }
}
