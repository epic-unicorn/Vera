import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings_nl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/local_vault_service.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

enum _AuthStep { checking, newVault, unlock }

// ── Page ──────────────────────────────────────────────────────────────────────

/// Biometric / PIN authentication gate for the mobile vault.
///
/// Flow:
/// 1. Check if vault is initialised → if not, show [_NewVaultView].
/// 2. If initialised, show [_UnlockView] (biometric + PIN fallback).
/// 3. On success → navigate to blueprint.
/// 4. On 5th failure → auto-wipe and show destruction message.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  _AuthStep _step = _AuthStep.checking;
  int _attemptsLeft = AppConstants.maxFailedAuthAttempts;
  String? _errorMessage;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initCheck();
  }

  Future<void> _initCheck() async {
    final vaultService = ref.read(localVaultServiceProvider);
    final initialised = await vaultService.isVaultInitialised();
    if (mounted) {
      setState(() => _step = initialised ? _AuthStep.unlock : _AuthStep.newVault);
    }
    if (initialised) {
      // Auto-attempt biometric unlock on arrival
      await _unlockBiometric();
    }
  }

  Future<void> _createVault() async {
    setState(() => _isBusy = true);
    final vaultService = ref.read(localVaultServiceProvider);
    await vaultService.createVault();
    if (mounted) {
      setState(() {
        _isBusy = false;
        _step = _AuthStep.unlock;
      });
      await _unlockBiometric();
    }
  }

  Future<void> _unlockBiometric() async {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    final vaultService = ref.read(localVaultServiceProvider);
    final result = await vaultService.unlockWithBiometrics();

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (result.success) {
      context.go(AppRoute.blueprint);
      return;
    }

    // Handle typed failures
    final failure = result.failure;
    switch (failure) {
      case VaultSelfDestructFailure():
        _showSelfDestructDialog();
      case AuthMaxAttemptsFailure():
        setState(() {
          _attemptsLeft = 0;
          _errorMessage = StringsNl.authSelfDestructWarning;
        });
      case AuthBiometricFailure(:final message):
        setState(() {
          _attemptsLeft--;
          _errorMessage =
              '${StringsNl.authFailedMessage}$_attemptsLeft. $message';
        });
      default:
        setState(() =>
            _errorMessage = failure?.message ?? StringsNl.authFailedMessage);
    }
  }

  void _showSelfDestructDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kluis gewist'),
        content: Text(
          StringsNl.authSelfDestructDone,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _step = _AuthStep.newVault);
            },
            child: const Text(StringsNl.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: switch (_step) {
            _AuthStep.checking => const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            _AuthStep.newVault => _NewVaultView(
                isBusy: _isBusy,
                onCreateVault: _createVault,
              ),
            _AuthStep.unlock => _UnlockView(
                isBusy: _isBusy,
                attemptsLeft: _attemptsLeft,
                errorMessage: _errorMessage,
                onBiometricUnlock: _unlockBiometric,
              ),
          },
        ),
      ),
    );
  }
}

// ── New vault view ─────────────────────────────────────────────────────────────

class _NewVaultView extends StatelessWidget {
  const _NewVaultView({required this.isBusy, required this.onCreateVault});

  final bool isBusy;
  final VoidCallback onCreateVault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline,
                size: 80, color: theme.colorScheme.primary)
            .animate()
            .scaleXY(begin: 0.6, end: 1, duration: 600.ms, curve: Curves.easeOut),
        const SizedBox(height: 32),
        Text(StringsNl.authCreateVaultTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(StringsNl.authCreateVaultBody,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: isBusy ? null : onCreateVault,
          icon: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.shield_outlined),
          label: const Text('Beveiligde kluis aanmaken'),
        ),
      ],
    );
  }
}

// ── Unlock view ───────────────────────────────────────────────────────────────

class _UnlockView extends StatelessWidget {
  const _UnlockView({
    required this.isBusy,
    required this.attemptsLeft,
    required this.errorMessage,
    required this.onBiometricUnlock,
  });

  final bool isBusy;
  final int attemptsLeft;
  final String? errorMessage;
  final VoidCallback onBiometricUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.fingerprint,
                size: 96,
                color: isBusy
                    ? theme.colorScheme.primary.withOpacity(0.6)
                    : theme.colorScheme.primary)
            .animate(target: isBusy ? 1 : 0)
            .scaleXY(end: 1.1, duration: 700.ms, curve: Curves.easeInOut),
        const SizedBox(height: 32),
        Text(StringsNl.authTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(StringsNl.authBiometricPrompt,
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7)),
            textAlign: TextAlign.center),

        if (errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: attemptsLeft <= 1
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: attemptsLeft <= 1
                    ? const Color(0xFFC62828)
                    : const Color(0xFFE07B00),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  attemptsLeft <= 1
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: attemptsLeft <= 1
                      ? const Color(0xFFC62828)
                      : const Color(0xFFE07B00),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: attemptsLeft <= 1
                              ? const Color(0xFFC62828)
                              : const Color(0xFFE07B00))),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 40),

        ElevatedButton.icon(
          onPressed: isBusy || attemptsLeft <= 0 ? null : onBiometricUnlock,
          icon: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white))
              : const Icon(Icons.fingerprint),
          label: Text(isBusy ? StringsNl.loading : StringsNl.authUnlockButton),
        ),

        if (attemptsLeft > 0 && attemptsLeft < AppConstants.maxFailedAuthAttempts)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${StringsNl.authFailedMessage}$attemptsLeft',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
