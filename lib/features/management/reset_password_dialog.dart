import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'managed_entity_form_support.dart';
import 'managed_entity_form_widgets.dart';

Future<bool> showResetPasswordDialog(
  BuildContext context, {
  required int userId,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ResetPasswordDialog(userId: userId),
      ) ??
      false;
}

class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key, required this.userId});

  final int userId;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final password = generateManagedPassword();
    setState(() {
      _passwordController.text = password;
      _confirmController.text = password;
      _obscurePassword = false;
      _passwordError = null;
      _confirmError = null;
      _formError = null;
    });
  }

  Future<void> _copyPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).passwordCopied)),
    );
  }

  bool _validate(AppLocalizations l) {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    setState(() {
      _passwordError = password.isEmpty
          ? l.requiredField
          : password.length < 8
          ? l.passwordTooShort
          : password.length > 128
          ? l.passwordTooLong
          : null;
      _confirmError = confirm.isEmpty
          ? l.requiredField
          : confirm != password
          ? l.passwordsDoNotMatch
          : null;
      _formError = null;
    });
    return _passwordError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_validate(l)) return;

    setState(() => _submitting = true);
    try {
      await context.read<AdminProvider>().resetUserPassword(
        userId: widget.userId,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _passwordError = error.fieldErrors['password'];
        _formError = error.fieldErrors.isEmpty
            ? error.message
            : l.serverRejectedFields;
      });
    } catch (_) {
      if (mounted) setState(() => _formError = l.connectionError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.password_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.resetPassword,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.resetPasswordDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const Key('reset-password-new'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (_) => setState(() {
                  _passwordError = null;
                  _formError = null;
                }),
                decoration: managedInputDecoration(
                  context,
                  label: l.newPassword,
                  helperText: l.passwordHelp,
                  errorText: _passwordError,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? l.showPassword : l.hidePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reset-password-confirm'),
                controller: _confirmController,
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (_) => setState(() => _confirmError = null),
                decoration: managedInputDecoration(
                  context,
                  label: l.confirmPassword,
                  errorText: _confirmError,
                  prefixIcon: Icons.lock_reset_rounded,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('reset-generate-password'),
                    onPressed: _submitting ? null : _generatePassword,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(l.generatePassword),
                  ),
                  if (_passwordController.text.isNotEmpty)
                    TextButton.icon(
                      key: const Key('reset-copy-password'),
                      onPressed: _copyPassword,
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      label: Text(l.copyPassword),
                    ),
                ],
              ),
              if (_formError case final error?) ...[
                const SizedBox(height: 12),
                ManagedFormError(message: error),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton.icon(
          key: const Key('reset-password-submit'),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock_reset_rounded, size: 19),
          label: Text(l.resetPassword),
        ),
      ],
    );
  }
}
