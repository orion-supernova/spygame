import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/identity_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../identity/presentation/widgets/language_button.dart';
import '../data/room_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _nameCtrl = TextEditingController(
    text: IdentityStorage.instance.lastDisplayName ?? '',
  );
  final _codeCtrl = TextEditingController();
  _BusyAction? _busyAction;
  String? _error;

  bool get _busy => _busyAction != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _nameValid {
    final t = _nameCtrl.text.trim();
    return t.isNotEmpty && t.length <= 24;
  }

  bool get _codeValid => _codeCtrl.text.trim().length == 4;

  Future<void> _create() async {
    if (!_nameValid) {
      setState(() => _error = AppLocalizations.of(context).homeErrorNeedName);
      return;
    }
    setState(() {
      _busyAction = _BusyAction.create;
      _error = null;
    });
    final name = _nameCtrl.text.trim();
    await IdentityStorage.instance.setLastDisplayName(name);
    try {
      final repo = ref.read(roomRepositoryProvider);
      final code = await repo.createRoom(displayName: name);
      await Haptics.success();
      if (!mounted) return;
      context.go(AppRoute.lobbyFor(code));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.localizedMessage(context));
      await Haptics.warning();
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _join() async {
    if (!_nameValid) {
      setState(() => _error = AppLocalizations.of(context).homeErrorNeedName);
      return;
    }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 4) {
      setState(() => _error = AppLocalizations.of(context).homeErrorNeedCode);
      return;
    }
    setState(() {
      _busyAction = _BusyAction.join;
      _error = null;
    });
    final name = _nameCtrl.text.trim();
    await IdentityStorage.instance.setLastDisplayName(name);
    try {
      final repo = ref.read(roomRepositoryProvider);
      final joined = await repo.joinRoom(code: code, displayName: name);
      await Haptics.success();
      if (!mounted) return;
      context.go(AppRoute.lobbyFor(joined));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.localizedMessage(context));
      await Haptics.warning();
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.go(AppRoute.welcome),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.paper,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.homeAppName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.paperMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Spacer(),
                                const LanguageButton(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.homeCodenameTitle,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.paper,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.homeCodenameSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.paperFaint,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _nameCtrl,
                              maxLength: 24,
                              textInputAction: TextInputAction.next,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.paper,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.homeCodenameHint,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _busy || !_nameValid ? null : _create,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    _busyAction == _BusyAction.create
                                        ? l10n.homeCtaBusy
                                        : l10n.homeCtaCreate,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    l10n.homeDividerOrJoin,
                                    style: AppTypography.mono(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      letterSpacing: 2,
                                      color: AppColors.paperFaint,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: _codeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                _UpperCaseFormatter(),
                              ],
                              textAlign: TextAlign.center,
                              style: AppTypography.mono(
                                size: 38,
                                weight: FontWeight.w700,
                                letterSpacing: 14,
                                color: AppColors.paper,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.homeJoinCodeHint,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            if (!_nameValid)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  l10n.homeHintNeedCodename,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.paperFaint,
                                  ),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: _busy || !_nameValid || !_codeValid
                                  ? null
                                  : _join,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    _busyAction == _BusyAction.join
                                        ? l10n.homeCtaBusy
                                        : l10n.homeCtaJoin,
                                  ),
                                ],
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 18),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.signalRed,
                                ),
                              ),
                            ],
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BusyAction { create, join }

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
