import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';

/// Segmented 4-character room-code input backed by a per-slot model, so
/// each box can be edited independently (deleting box 3 leaves box 4 in
/// place — no shifting). A hidden [TextField] is used purely as an IME
/// key source: its text is pinned to a 1-char sentinel and each change is
/// diffed into "typed a char" or "backspace".
///
/// Interactions:
/// - Typing fills the leftmost empty box; the keyboard auto-dismisses
///   once all 4 are filled.
/// - Tapping a filled box selects it; the next keypress overwrites just
///   that box, backspace clears just that box (others stay put).
/// - Tapping an empty box moves the caret there.
/// - Long-press pastes a code from the clipboard.
///
/// The parent-owned [controller] is an output: it always holds the
/// filled characters in order (positionally correct once complete).
class RoomCodeInput extends StatefulWidget {
  const RoomCodeInput({super.key, required this.controller, this.onChanged});

  /// Owned by the parent; not disposed here. Seeds the initial value and
  /// receives the compacted code as the user types.
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  static const length = 4;

  @override
  State<RoomCodeInput> createState() => _RoomCodeInputState();
}

class _RoomCodeInputState extends State<RoomCodeInput>
    with SingleTickerProviderStateMixin {
  static const _sentinel = ' ';
  static final _allowed = RegExp(r'[A-Z0-9]');

  final _focusNode = FocusNode();
  final _inputCtrl = TextEditingController(text: _sentinel);
  late final AnimationController _blink;

  /// One entry per box; null = empty.
  final List<String?> _slots = List.filled(RoomCodeInput.length, null);

  /// Explicit target box from a tap (replace/insert there). When null,
  /// input goes to the leftmost empty slot.
  int? _target;

  int? get _firstEmpty {
    final i = _slots.indexWhere((s) => s == null);
    return i == -1 ? null : i;
  }

  @override
  void initState() {
    super.initState();
    final seed = widget.controller.text.toUpperCase();
    for (var i = 0; i < seed.length && i < RoomCodeInput.length; i++) {
      if (_allowed.hasMatch(seed[i])) _slots[i] = seed[i];
    }
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _inputCtrl.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) _target = null;
    if (mounted) setState(() {});
  }

  /// Diffs the hidden field against the sentinel: longer = typed chars,
  /// empty = backspace. Then pins it back to the sentinel.
  void _handleInput(String value) {
    if (value.length > _sentinel.length) {
      for (final ch in value.substring(_sentinel.length).split('')) {
        _typeChar(ch);
      }
    } else if (value.isEmpty) {
      _backspace();
    }
    _inputCtrl.value = const TextEditingValue(
      text: _sentinel,
      selection: TextSelection.collapsed(offset: _sentinel.length),
    );
  }

  void _typeChar(String raw) {
    final ch = raw.toUpperCase();
    if (!_allowed.hasMatch(ch)) return;
    final i = _target ?? _firstEmpty;
    if (i == null) return;
    _slots[i] = ch;
    _target = null;
    Haptics.selection();
    _syncAndNotify();
  }

  void _backspace() {
    final t = _target;
    if (t != null && _slots[t] != null) {
      // A tapped box: clear just it; caret stays there for the retype.
      _slots[t] = null;
    } else {
      // Clear the nearest filled box left of the insertion point.
      final pos = t ?? _firstEmpty ?? RoomCodeInput.length;
      var j = pos - 1;
      while (j >= 0 && _slots[j] == null) {
        j--;
      }
      if (j < 0) return;
      _slots[j] = null;
      _target = null;
    }
    Haptics.selection();
    _syncAndNotify();
  }

  void _syncAndNotify() {
    final compact = _slots.whereType<String>().join();
    widget.controller.text = compact;
    widget.onChanged?.call(compact);
    if (_firstEmpty == null) {
      // Code complete — nothing left to type, get out of the way.
      _focusNode.unfocus();
    }
    if (mounted) setState(() {});
  }

  void _handleTap() {
    _target = null;
    _focusNode.requestFocus();
    if (mounted) setState(() {});
  }

  void _handleBoxTap(int index) {
    Haptics.selection();
    _target = index;
    _focusNode.requestFocus();
    if (mounted) setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null) return;
    final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.isEmpty) return;
    await Haptics.light();
    for (var i = 0; i < RoomCodeInput.length; i++) {
      _slots[i] = i < cleaned.length ? cleaned[i] : null;
    }
    _target = null;
    if (_firstEmpty != null) _focusNode.requestFocus();
    _syncAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    var caretIndex = -1;
    var replaceIndex = -1;
    if (focused) {
      final t = _target;
      if (t != null) {
        if (_slots[t] != null) {
          replaceIndex = t;
        } else {
          caretIndex = t;
        }
      } else {
        caretIndex = _firstEmpty ?? -1;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onLongPress: _pasteFromClipboard,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden field that provides the keyboard connection. Not
          // hit-testable — gestures are handled by the GestureDetectors.
          IgnorePointer(
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  // Letters + digits inline, no autocorrect/suggestions bar.
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: _handleInput,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Row(
              children: [
                for (var i = 0; i < RoomCodeInput.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleBoxTap(i),
                      child: _CharBox(
                        char: _slots[i],
                        active: i == caretIndex,
                        selected: i == replaceIndex,
                        blink: _blink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharBox extends StatelessWidget {
  const _CharBox({
    required this.char,
    required this.active,
    required this.selected,
    required this.blink,
  });

  final String? char;

  /// Empty slot the next character goes into — shows the blinking caret.
  final bool active;

  /// Filled slot selected for in-place replacement.
  final bool selected;

  final Animation<double> blink;

  @override
  Widget build(BuildContext context) {
    final highlighted = active || selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 72,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.lime.withValues(alpha: 0.10)
            : AppColors.inkRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.lime : AppColors.inkOutline,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: char != null
            ? Text(
                char!,
                style: AppTypography.mono(
                  size: 32,
                  weight: FontWeight.w700,
                  color: AppColors.paper,
                ),
              )
            : active
            ? FadeTransition(
                opacity: blink,
                child: Container(
                  width: 2,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
