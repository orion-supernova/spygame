import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/identity_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
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
  bool _busy = false;
  String? _error;

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

  Future<void> _create() async {
    if (!_nameValid) {
      setState(() => _error = 'Type a name first.');
      return;
    }
    setState(() {
      _busy = true;
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
      setState(() => _error = e.message);
      await Haptics.warning();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (!_nameValid) {
      setState(() => _error = 'Type a name first.');
      return;
    }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 4) {
      setState(() => _error = 'Codes are 4 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _nameCtrl.text.trim();
    await IdentityStorage.instance.setLastDisplayName(name);
    try {
      final repo = ref.read(roomRepositoryProvider);
      final joined =
          await repo.joinRoom(code: code, displayName: name);
      await Haptics.success();
      if (!mounted) return;
      context.go(AppRoute.lobbyFor(joined));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      await Haptics.warning();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoute.welcome),
                        icon: const Icon(Icons.arrow_back, color: AppColors.paper),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Where am I?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.paperMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pick a name',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.paper,
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
                    decoration: const InputDecoration(
                      hintText: 'Codename',
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
                        Text(_busy ? 'PLEASE WAIT…' : 'CREATE A ROOM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR JOIN',
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
                    decoration: const InputDecoration(
                      hintText: '— — — —',
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _busy || !_nameValid ? null : _join,
                    child: const Text('JOIN ROOM'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.signalRed),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
