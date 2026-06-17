import 'package:flutter/material.dart';

import 'app_skin.dart';

/// Ergonomic access to the active [AppSkin] from any widget.
///
/// Falls back to [AppSkin.noir] if no extension is present (e.g. a widget
/// rendered in a test harness outside the themed [MaterialApp]), so callers
/// never have to null-check. Never use `!` on the raw extension.
extension SkinContext on BuildContext {
  AppSkin get skin => Theme.of(this).extension<AppSkin>() ?? AppSkin.noir;
}
