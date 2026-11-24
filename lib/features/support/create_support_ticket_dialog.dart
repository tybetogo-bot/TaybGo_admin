import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/admin_order.dart';
import '../../core/models/support_ticket.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/uuid.dart';
import '../management/managed_file_picker.dart';

enum SupportTicketComposerContext { general, driver, restaurant, order }

class SupportTicketRecipientOption {
  const SupportTicketRecipientOption({
    required this.label,
    required this.name,
    required this.userId,
    required this.target,
    this.relatedOrderId,
    required this.icon,
  });

  final String label;
  final String name;
  final int userId;
  final Map<String, dynamic> target;
  final int? relatedOrderId;
  final IconData icon;

  String get displayName => name.trim().isEmpty ? '#$userId' : name.trim();
}

class SupportTicketComposerPreset {
  const SupportTicketComposerPreset._({
    required this.context,
    this.recipients = const [],
    this.orderId,
    this.orderRestaurantId,
    this.orderRestaurantName,
  });

  final SupportTicketComposerContext context;
  final List<SupportTicketRecipientOption> recipients;
  final int? orderId;
  final int? orderRestaurantId;
  final String? orderRestaurantName;

  factory SupportTicketComposerPreset.general() {
    return const SupportTicketComposerPreset._(
      context: SupportTicketComposerContext.general,
    );
  }

  factory SupportTicketComposerPreset.driver({
    required int driverId,
    String? driverName,
    int? relatedOrderId,
  }) {
    return SupportTicketComposerPreset._(
      context: SupportTicketComposerContext.driver,
      recipients: driverId > 0
          ? [
              SupportTicketRecipientOption(
                label: 'Driver',
                name: driverName ?? '',
                userId: driverId,
                target: {'type': 'DRIVER', 'id': driverId},
                relatedOrderId: relatedOrderId,
                icon: Icons.local_shipping_outlined,
              ),
            ]
          : const [],
    );
  }

  factory SupportTicketComposerPreset.restaurant({
    required int restaurantId,
    required int recipientUserId,
    String? restaurantName,
    int? relatedOrderId,
  }) {
    return SupportTicketComposerPreset._(
      context: SupportTicketComposerContext.restaurant,
      recipients: restaurantId > 0 && recipientUserId > 0
          ? [
              SupportTicketRecipientOption(
                label: 'Restaurant',
                name: restaurantName ?? '',
                userId: recipientUserId,
                target: {'type': 'RESTAURANT', 'id': restaurantId},
                relatedOrderId: relatedOrderId,
                icon: Icons.storefront_outlined,
              ),
            ]
          : const [],
    );
  }

  factory SupportTicketComposerPreset.order(AdminOrder order) {
    final recipients = <SupportTicketRecipientOption>[];
    final customer = order.customer;
    if (customer != null && customer.id > 0) {
      recipients.add(
        SupportTicketRecipientOption(
          label: 'Customer',
          name: customer.displayName,
          userId: customer.id,
          target: {'type': 'ORDER', 'id': order.id},
          icon: Icons.person_outline_rounded,
        ),
      );
    }

    final driver = order.driver;
    if (driver != null && driver.id > 0) {
      recipients.add(
        SupportTicketRecipientOption(
          label: 'Driver',
          name: driver.displayName,
          userId: driver.id,
          target: {'type': 'DRIVER', 'id': driver.id},
          relatedOrderId: order.id,
          icon: Icons.local_shipping_outlined,
        ),
      );
    }

    return SupportTicketComposerPreset._(
      context: SupportTicketComposerContext.order,
      recipients: recipients,
      orderId: order.id,
      orderRestaurantId: order.restaurant?.id,
      orderRestaurantName: order.restaurant?.name,
    );
  }
}

Future<SupportTicket?> showCreateSupportTicketDialog(
  BuildContext context, {
  required SupportTicketComposerPreset preset,
  CloudinaryService? cloudinaryService,
  ManagedFilePicker filePicker = pickManagedFile,
}) {
  return showDialog<SupportTicket>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CreateSupportTicketDialog(
      preset: preset,
      cloudinaryService: cloudinaryService,
      filePicker: filePicker,
    ),
  );
}

/// Opens the composer and, after a successful create, refreshes the first
/// support-list page before showing the returned ticket detail.
Future<void> createSupportTicketFromContext(
  BuildContext context, {
  required SupportTicketComposerPreset preset,
  CloudinaryService? cloudinaryService,
  ManagedFilePicker filePicker = pickManagedFile,
}) async {
  final ticket = await showCreateSupportTicketDialog(
    context,
    preset: preset,
    cloudinaryService: cloudinaryService,
    filePicker: filePicker,
  );
  if (ticket == null || !context.mounted) return;

  await context.read<AdminProvider>().fetchTickets(page: 1);
  if (context.mounted) context.go('/support/${ticket.id}');
}

class CreateSupportTicketDialog extends StatefulWidget {
  const CreateSupportTicketDialog({
    super.key,
    required this.preset,
    this.cloudinaryService,
    this.filePicker = pickManagedFile,
  });

  final SupportTicketComposerPreset preset;
  final CloudinaryService? cloudinaryService;
  final ManagedFilePicker filePicker;

  @override
  State<CreateSupportTicketDialog> createState() =>
      _CreateSupportTicketDialogState();
}

class _CreateSupportTicketDialogState extends State<CreateSupportTicketDialog> {
  static const _categories = [
    'ORDER',
    'PAYMENT',
    'DELIVERY',
    'ACCOUNT',
    'OTHER',
  ];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _recipientController = TextEditingController();
  final _relatedOrderController = TextEditingController();

  late final CloudinaryService _cloudinaryService;
  bool _ownsCloudinaryService = false;
  late final List<SupportTicketRecipientOption> _recipients;

  String _category = 'OTHER';
  String _priority = 'MEDIUM';
  int? _selectedRecipientIndex;
  bool _submitting = false;
  bool _uploadingAttachment = false;
  bool _loadingOrderRestaurant = false;
  String? _formError;
  Map<String, String> _fieldErrors = {};
  final List<_PendingSupportAttachment> _attachments = [];

  String? _submittedFingerprint;
  String? _idempotencyKey;

  bool get _isOrderContext =>
      widget.preset.context == SupportTicketComposerContext.order;

  bool get _isGeneralContext =>
      widget.preset.context == SupportTicketComposerContext.general;

  SupportTicketRecipientOption? get _selectedRecipient {
    final index = _selectedRecipientIndex;
    if (index == null || index < 0 || index >= _recipients.length) return null;
    return _recipients[index];
  }

  @override
  void initState() {
    super.initState();
    _recipients = List<SupportTicketRecipientOption>.from(
      widget.preset.recipients,
    );
    if (_recipients.isNotEmpty) {
      _selectedRecipientIndex = 0;
      _recipientController.text = '${_recipients.first.userId}';
      final relatedOrderId = _recipients.first.relatedOrderId;
      if (relatedOrderId != null && !_isOrderContext) {
        _relatedOrderController.text = '$relatedOrderId';
      }
    }

    if (widget.cloudinaryService != null) {
      _cloudinaryService = widget.cloudinaryService!;
    } else {
      _cloudinaryService = CloudinaryService();
      _ownsCloudinaryService = true;
    }

    if (_isOrderContext && widget.preset.orderRestaurantId != null) {
      Future.microtask(_loadOrderRestaurantRecipient);
    }
  }

  @override
  void dispose() {
    if (_ownsCloudinaryService) _cloudinaryService.close();
    _subjectController.dispose();
    _bodyController.dispose();
    _recipientController.dispose();
    _relatedOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderRestaurantRecipient() async {
    final restaurantId = widget.preset.orderRestaurantId;
    if (restaurantId == null || restaurantId <= 0) return;

    setState(() => _loadingOrderRestaurant = true);
    try {
      final restaurant = await context
          .read<AdminProvider>()
          .apiService
          .getAdminRestaurant(restaurantId);
      if (!mounted || restaurant.ownerUser <= 0) return;
      if (_recipients.any((item) => item.target['type'] == 'RESTAURANT')) {
        return;
      }
      setState(() {
        _recipients.add(
          SupportTicketRecipientOption(
            label: 'Restaurant',
            name: restaurant.name.isNotEmpty
                ? restaurant.name
                : (widget.preset.orderRestaurantName ?? ''),
            userId: restaurant.ownerUser,
            target: {'type': 'RESTAURANT', 'id': restaurant.id},
            relatedOrderId: _orderId,
            icon: Icons.storefront_outlined,
          ),
        );
        if (_selectedRecipientIndex == null) {
          _selectedRecipientIndex = 0;
          _recipientController.text = '${_recipients.first.userId}';
        }
      });
    } on ApiException catch (error) {
      debugPrint(
        '[CreateSupportTicketDialog] Restaurant recipient unavailable: '
        '${error.message}',
      );
    } catch (error) {
      debugPrint(
        '[CreateSupportTicketDialog] Restaurant recipient lookup failed: '
        '$error',
      );
    } finally {
      if (mounted) setState(() => _loadingOrderRestaurant = false);
    }
  }

  int? get _orderId {
    return widget.preset.orderId;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: media.height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.createSupportTicketTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(l),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l.cancel,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _subjectController,
                        enabled: !_submitting,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l.subject,
                          errorText: _errorFor('subject'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 430;
                          final fields = [
                            _buildCategoryField(l),
                            _buildPriorityField(l),
                          ];
                          if (compact) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 14),
                                fields[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 14),
                              Expanded(child: fields[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildRecipientField(l),
                      if (!_isOrderContext) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _relatedOrderController,
                          enabled: !_submitting,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: l.relatedOrderOptional,
                            errorText: _errorFor('related_order_id'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bodyController,
                        enabled: !_submitting,
                        minLines: 5,
                        maxLines: 9,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: l.message,
                          alignLabelWithHint: true,
                          errorText: _errorFor('body'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAttachmentSection(l),
                      if (_formError != null) ...[
                        const SizedBox(height: 14),
                        _FormError(text: _formError!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submitting || _uploadingAttachment
                        ? null
                        : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(l.createSupportTicket),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l) {
    switch (widget.preset.context) {
      case SupportTicketComposerContext.driver:
        return l.contactDriverSubtitle;
      case SupportTicketComposerContext.restaurant:
        return l.contactRestaurantSubtitle;
      case SupportTicketComposerContext.order:
        return l.contactOrderSubtitle;
      case SupportTicketComposerContext.general:
        return l.createSupportTicketSubtitle;
    }
  }

  Widget _buildCategoryField(AppLocalizations l) {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: l.category,
        border: const OutlineInputBorder(),
      ),
      items: _categories
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(_categoryLabel(l, value)),
            ),
          )
          .toList(growable: false),
      onChanged: _submitting
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _category = value;
                _fieldErrors.remove('category');
              });
            },
    );
  }

  Widget _buildPriorityField(AppLocalizations l) {
    return DropdownButtonFormField<String>(
      initialValue: _priority,
      decoration: InputDecoration(
        labelText: l.priority,
        border: const OutlineInputBorder(),
      ),
      items: _priorities
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(_priorityLabel(l, value)),
            ),
          )
          .toList(growable: false),
      onChanged: _submitting
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _priority = value;
                _fieldErrors.remove('priority');
              });
            },
    );
  }

  Widget _buildRecipientField(AppLocalizations l) {
    if (_isGeneralContext) {
      return TextField(
        controller: _recipientController,
        enabled: !_submitting,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l.recipientUserId,
          helperText: l.generalSupportRecipientHint,
          errorText: _errorFor('recipient_user_id'),
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (_recipients.isEmpty) {
      return _RecipientUnavailable(
        text: _loadingOrderRestaurant
            ? l.loadingRecipient
            : l.noEligibleRecipients,
      );
    }

    if (_isOrderContext) {
      return DropdownButtonFormField<int>(
        initialValue: _selectedRecipientIndex,
        decoration: InputDecoration(
          labelText: l.recipient,
          errorText: _errorFor('recipient_user_id'),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (var index = 0; index < _recipients.length; index++)
            DropdownMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  Icon(_recipients[index].icon, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_recipientLabel(l, _recipients[index])}: '
                      '${_recipients[index].displayName} (#${_recipients[index].userId})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: _submitting
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _selectedRecipientIndex = value;
                  _recipientController.text = '${_recipients[value].userId}';
                  _fieldErrors.remove('recipient_user_id');
                });
              },
      );
    }

    final recipient = _recipients.first;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l.recipient,
        errorText: _errorFor('recipient_user_id'),
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Icon(recipient.icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_recipientLabel(l, recipient)}: '
              '${recipient.displayName} (#${recipient.userId})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _recipientLabel(
    AppLocalizations l,
    SupportTicketRecipientOption recipient,
  ) {
    return switch (recipient.target['type']) {
      'DRIVER' => l.driver,
      'RESTAURANT' => l.restaurant,
      'ORDER' => l.customer,
      _ => recipient.label,
    };
  }

  Widget _buildAttachmentSection(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.attachmentsOptional,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _submitting || _uploadingAttachment
                  ? null
                  : _pickAndUploadAttachment,
              icon: _uploadingAttachment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(
                _uploadingAttachment ? l.uploadingAttachment : l.addAttachment,
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _attachments.length; index++)
                InputChip(
                  avatar: Icon(
                    _attachments[index].mimeType == 'application/pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    size: 18,
                  ),
                  label: Text(_attachments[index].fileName),
                  onDeleted: _submitting
                      ? null
                      : () => setState(() => _attachments.removeAt(index)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUploadAttachment() async {
    final l = AppLocalizations.of(context);
    final picked = await widget.filePicker(imagesOnly: false);
    if (picked == null || !mounted) return;
    if (picked.bytes.length > 10 * 1024 * 1024) {
      setState(() => _formError = l.fileTooLarge);
      return;
    }

    setState(() {
      _uploadingAttachment = true;
      _formError = null;
    });
    try {
      final url = await _cloudinaryService.uploadFile(
        picked.bytes,
        fileName: picked.fileName,
        folder: 'support_attachments',
        resourceType: 'auto',
      );
      if (!mounted) return;
      setState(() {
        _attachments.add(
          _PendingSupportAttachment(
            fileName: picked.fileName,
            fileUrl: url,
            mimeType: _mimeTypeFor(picked.fileName),
          ),
        );
        _submittedFingerprint = null;
        _idempotencyKey = null;
      });
    } catch (_) {
      if (mounted) setState(() => _formError = l.uploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final validation = _validate(l);
    if (!validation.isValid) {
      setState(() {
        _fieldErrors = validation.errors;
        _formError = null;
      });
      return;
    }

    final recipient = _selectedRecipient;
    final recipientUserId = _isGeneralContext
        ? int.parse(_recipientController.text.trim())
        : recipient!.userId;
    final target = _isGeneralContext ? null : recipient!.target;
    final relatedOrderId = _isOrderContext
        ? recipient!.relatedOrderId
        : _optionalPositiveInt(_relatedOrderController.text);
    final attachments = _attachments
        .map(
          (item) => <String, String>{
            'file_url': item.fileUrl,
            'mime_type': item.mimeType,
          },
        )
        .toList(growable: false);
    final request = <String, dynamic>{
      'subject': _subjectController.text.trim(),
      'category': _category,
      'priority': _priority,
      'target': target,
      'recipient_user_id': recipientUserId,
      'body': _bodyController.text.trim(),
      'attachments': attachments,
    };
    if (relatedOrderId != null) request['related_order_id'] = relatedOrderId;

    final fingerprint = jsonEncode(request);
    final key = _submittedFingerprint == fingerprint && _idempotencyKey != null
        ? _idempotencyKey!
        : generateUuidV4();
    _submittedFingerprint = fingerprint;
    _idempotencyKey = key;

    setState(() {
      _submitting = true;
      _fieldErrors = {};
      _formError = null;
    });

    try {
      final ticket = await context
          .read<AdminProvider>()
          .apiService
          .createAdminSupportTicket(
            subject: request['subject'] as String,
            category: request['category'] as String,
            priority: request['priority'] as String,
            target: target,
            relatedOrderId: relatedOrderId,
            recipientUserId: recipientUserId,
            body: request['body'] as String,
            attachments: attachments,
            idempotencyKey: key,
          );
      if (mounted) Navigator.of(context).pop(ticket);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _fieldErrors = error.fieldErrors;
        _formError = _formatApiError(error, l);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = l.resolveError(error.toString());
      });
    }
  }

  _ValidationResult _validate(AppLocalizations l) {
    final errors = <String, String>{};
    if (_subjectController.text.trim().isEmpty) {
      errors['subject'] = l.requiredField;
    }
    if (_bodyController.text.trim().isEmpty) {
      errors['body'] = l.requiredField;
    }

    if (_isGeneralContext) {
      final recipientId = int.tryParse(_recipientController.text.trim());
      if (recipientId == null || recipientId <= 0) {
        errors['recipient_user_id'] = l.invalidRecipient;
      }
    } else if (_selectedRecipient == null || _selectedRecipient!.userId <= 0) {
      errors['recipient_user_id'] = l.recipientRequired;
    }

    if (!_isOrderContext &&
        _relatedOrderController.text.trim().isNotEmpty &&
        _optionalPositiveInt(_relatedOrderController.text) == null) {
      errors['related_order_id'] = l.invalidRelatedOrder;
    }

    return _ValidationResult(errors);
  }

  String? _errorFor(String key) {
    return _fieldErrors[key] ??
        _fieldErrors['$key.id'] ??
        _fieldErrors[key.replaceAll('_', '.')];
  }

  String _formatApiError(ApiException error, AppLocalizations l) {
    final message = l.resolveError(error.message);
    final code = error.code?.trim();
    if (code == null || code.isEmpty) return message;
    return '$message ($code)';
  }

  String _categoryLabel(AppLocalizations l, String value) {
    switch (value) {
      case 'ORDER':
        return l.relatedOrder;
      case 'PAYMENT':
        return l.payment;
      case 'DELIVERY':
        return l.delivery;
      case 'ACCOUNT':
        return l.accountInfo;
      default:
        return l.other;
    }
  }

  String _priorityLabel(AppLocalizations l, String value) {
    switch (value) {
      case 'LOW':
        return l.low;
      case 'HIGH':
        return l.high;
      case 'URGENT':
        return l.urgent;
      default:
        return l.medium;
    }
  }

  int? _optionalPositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed <= 0 ? null : parsed;
  }

  String _mimeTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

class _PendingSupportAttachment {
  const _PendingSupportAttachment({
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
  });

  final String fileName;
  final String fileUrl;
  final String mimeType;
}

class _ValidationResult {
  const _ValidationResult(this.errors);

  final Map<String, String> errors;

  bool get isValid => errors.isEmpty;
}

class _FormError extends StatelessWidget {
  const _FormError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
      ),
    );
  }
}

class _RecipientUnavailable extends StatelessWidget {
  const _RecipientUnavailable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
