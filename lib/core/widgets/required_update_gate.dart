import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env_config.dart';
import '../providers/public_config_provider.dart';

class RequiredUpdateGate extends StatelessWidget {
  const RequiredUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicConfigProvider>();
    final config = provider.config;
    if (config == null || !config.forceUpdate) return child;

    final rawUrl = config.updateUrl;
    final parsed = rawUrl == null ? null : Uri.tryParse(rawUrl);
    final updateUri = parsed == null
        ? null
        : parsed.hasScheme
        ? parsed
        : Uri.parse(EnvConfig.baseUrl).resolveUri(parsed);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.system_update_alt_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update required',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A newer version of TaybGo Admin is required to continue. Latest version: ${config.latestVersion}.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: updateUri == null
                          ? null
                          : () => launchUrl(
                              updateUri,
                              mode: LaunchMode.externalApplication,
                            ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Update now'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: provider.isLoading ? null : provider.load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Check again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
