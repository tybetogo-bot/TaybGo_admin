import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ManagedCloudinaryFileField extends StatelessWidget {
  const ManagedCloudinaryFileField({
    super.key,
    required this.label,
    required this.icon,
    required this.isRequired,
    required this.isUploading,
    required this.onPick,
    required this.uploadLabel,
    required this.replaceLabel,
    required this.uploadingLabel,
    required this.fileTypesLabel,
    this.fileName,
    this.url,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final bool isRequired;
  final bool isUploading;
  final VoidCallback onPick;
  final String uploadLabel;
  final String replaceLabel;
  final String uploadingLabel;
  final String fileTypesLabel;
  final String? fileName;
  final String? url;
  final String? errorText;

  bool get _isUploaded => url?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = errorText != null;
    final borderColor = hasError
        ? scheme.error
        : _isUploaded
        ? AppColors.success.withValues(alpha: 0.48)
        : scheme.outline.withValues(alpha: 0.25);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isUploaded
            ? AppColors.success.withValues(alpha: 0.045)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (_isUploaded ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _isUploaded ? Icons.check_circle_rounded : icon,
                  color: _isUploaded ? AppColors.success : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label${isRequired ? ' *' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUploading
                          ? uploadingLabel
                          : _isUploaded
                          ? (fileName ?? url!)
                          : fileTypesLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.56),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isUploading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                OutlinedButton.icon(
                  onPressed: onPick,
                  icon: Icon(
                    _isUploaded
                        ? Icons.refresh_rounded
                        : Icons.cloud_upload_outlined,
                    size: 18,
                  ),
                  label: Text(_isUploaded ? replaceLabel : uploadLabel),
                ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
