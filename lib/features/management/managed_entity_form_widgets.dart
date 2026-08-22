import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ManagedFormScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String cancelLabel;
  final String submitLabel;
  final bool isSubmitting;
  final String? formError;
  final VoidCallback onSubmit;
  final Widget child;

  const ManagedFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cancelLabel,
    required this.submitLabel,
    required this.isSubmitting,
    required this.onSubmit,
    required this.child,
    this.formError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: isSubmitting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.14),
                                AppColors.primary.withValues(alpha: 0.035),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLarge,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.35,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.62,
                                            ),
                                            height: 1.35,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (formError != null) ...[
                          const SizedBox(height: 14),
                          ManagedFormError(message: formError!),
                        ],
                        const SizedBox(height: 16),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.16),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting ? null : () => context.pop(),
                        child: Text(cancelLabel),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        key: const Key('managed-form-submit'),
                        onPressed: isSubmitting ? null : onSubmit,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 19),
                        label: Text(submitLabel),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagedFormSection extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Widget child;

  const ManagedFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.56),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class ManagedFieldGrid extends StatelessWidget {
  final List<Widget> children;

  const ManagedFieldGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        const gap = 12.0;
        final width = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

InputDecoration managedInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  String? errorText,
  IconData? prefixIcon,
  String? helperText,
  Widget? suffixIcon,
  Widget? prefix,
}) {
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(AppSpacing.radiusMedium);
  final border = BorderSide(color: scheme.outline.withValues(alpha: 0.3));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    helperText: helperText,
    helperMaxLines: 2,
    filled: true,
    fillColor: scheme.surface,
    prefixIcon:
        prefix ??
        (prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.56),
              )),
    prefixIconConstraints: prefix == null ? null : const BoxConstraints(),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: radius, borderSide: border),
    enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: border),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error, width: 1.5),
    ),
  );
}

class ManagedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final Widget? suffixIcon;
  final bool enabled;

  const ManagedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      enabled: enabled,
      decoration: managedInputDecoration(
        context,
        label: label,
        hint: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class ManagedDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? errorText;
  final IconData? icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const ManagedDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: managedInputDecoration(
        context,
        label: label,
        errorText: errorText,
        prefixIcon: icon,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class ManagedToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ManagedToggleTile({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withValues(alpha: 0.055)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : scheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13),
        secondary: Icon(
          icon,
          color: value
              ? AppColors.primary
              : scheme.onSurface.withValues(alpha: 0.52),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
      ),
    );
  }
}

class ManagedFormError extends StatelessWidget {
  final String message;

  const ManagedFormError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
