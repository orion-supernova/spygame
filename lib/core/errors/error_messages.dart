import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_exception.dart';

extension AppExceptionL10n on AppException {
  /// Resolve a user-facing message at display time. Always returns a
  /// localized, generic string — raw server/exception text is never shown
  /// to users so implementation details (transport names, library
  /// internals, etc.) can't leak into the UI.
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = this;
    if (e is RoomNotFoundException) return l10n.errorRoomNotFound;
    if (e is RoomFullException) return l10n.errorRoomFull;
    if (e is NetworkException) return l10n.errorNetwork;
    if (e is NotAuthorizedException) return l10n.errorOnlyHost;
    return l10n.errorUnknown;
  }
}
