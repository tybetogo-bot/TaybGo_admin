import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_setting.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  List<AppSetting>? _settings;
  String? _error;

  ApiService get _api => context.read<AdminProvider>().apiService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final settings = await _api.getAppSettings();
      if (mounted) setState(() => _settings = settings);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<String?> _save(AppSetting setting, dynamic value) async {
    try {
      final updated = await _api.updateAppSetting(setting.key, value);
      if (mounted) {
        setState(() {
          final index = _settings!.indexWhere(
            (item) => item.key == setting.key,
          );
          if (index >= 0) _settings![index] = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${setting.key} updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return null;
    } on ApiException catch (error) {
      return error.fieldErrors.values.isNotEmpty
          ? error.fieldErrors.values.join('\n')
          : error.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Application settings'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              itemCount: _settings!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final setting = _settings![index];
                return _SettingEditor(
                  key: ValueKey('${setting.key}:${setting.value}'),
                  setting: setting,
                  onSave: (value) => _save(setting, value),
                );
              },
            ),
    );
  }
}

class _SettingEditor extends StatefulWidget {
  const _SettingEditor({
    super.key,
    required this.setting,
    required this.onSave,
  });

  final AppSetting setting;
  final Future<String?> Function(dynamic value) onSave;

  @override
  State<_SettingEditor> createState() => _SettingEditorState();
}

class _SettingEditorState extends State<_SettingEditor> {
  static const _roles = ['customer', 'seller', 'driver', 'admin'];
  late dynamic _value = widget.setting.value;
  late final TextEditingController _controller = TextEditingController(
    text: _value?.toString() ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(dynamic value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      if (error == null) _value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final setting = widget.setting;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    setting.key,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (setting.isPublic)
                  const Chip(
                    label: Text('Public'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (setting.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                setting.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_value is bool)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text((_value as bool) ? 'Enabled' : 'Disabled'),
                value: _value as bool,
                onChanged: _saving ? null : _save,
              )
            else if (_value is List && setting.key.contains('roles'))
              Wrap(
                spacing: 8,
                children: _roles.map((role) {
                  final selected = (_value as List).contains(role);
                  return FilterChip(
                    label: Text(role),
                    selected: selected,
                    onSelected: _saving
                        ? null
                        : (enabled) {
                            final roles = List<String>.from(_value as List);
                            enabled ? roles.add(role) : roles.remove(role);
                            _save(roles);
                          },
                  );
                }).toList(),
              )
            else
              TextField(
                controller: _controller,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: setting.key == 'app.update_url'
                      ? 'Empty means no update URL'
                      : null,
                  suffixIcon: IconButton(
                    tooltip: 'Save',
                    onPressed: _saving
                        ? null
                        : () => _save(
                            setting.key == 'app.update_url' &&
                                    _controller.text.trim().isEmpty
                                ? null
                                : _controller.text.trim(),
                          ),
                    icon: _saving
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                  ),
                ),
                onSubmitted: _saving ? null : _save,
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
}
