// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_provider.dart';

/// Comprehensive error dialog widget for better error handling UX
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final SettingsProvider settings;
  final bool showDetails;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    required this.settings,
    this.error,
    this.stackTrace,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 48,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            if (showDetails && (error != null || stackTrace != null)) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Technikai részletek:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  _getErrorDetails(),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (showDetails)
          TextButton(
            onPressed: () => Navigator.of(context).pop('hide_details'),
            child: const Text('Részletek elrejtése'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop('show_details'),
            child: const Text('Részletek mutatása'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('dismiss'),
          child: const Text('Bezárás'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop('report'),
          icon: const Icon(Icons.bug_report),
          label: const Text('Hibajelentés'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  String _getErrorDetails() {
    final buffer = StringBuffer();
    if (error != null) {
      buffer.writeln('Hiba: $error');
    }
    if (stackTrace != null) {
      buffer.writeln('\nStackTrace:');
      buffer.writeln(stackTrace.toString());
    }
    return buffer.toString();
  }

  /// Shows the error dialog and handles user actions
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required SettingsProvider settings,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    bool showDetails = false;
    
    while (true) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ErrorDialog(
          title: title,
          message: message,
          settings: settings,
          error: error,
          stackTrace: stackTrace,
          showDetails: showDetails,
        ),
      );

      switch (result) {
        case 'show_details':
          showDetails = true;
          continue;
        case 'hide_details':
          showDetails = false;
          continue;
        case 'report':
          await _sendErrorReport(
            context: context,
            title: title,
            message: message,
            settings: settings,
            error: error,
            stackTrace: stackTrace,
          );
          return;
        case 'dismiss':
        default:
          return;
      }
    }
  }

  /// Shows confirmation dialog before sending error report
  static Future<void> _sendErrorReport({
    required BuildContext context,
    required String title,
    required String message,
    required SettingsProvider settings,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hibajelentés küldése'),
        content: const Text(
          'A hibajelentés az alapértelmezett e-mail alkalmazásban nyílik meg. '
          'Kérjük, írja le részletesen, mit csinált amikor a hiba fellépett.\n\n'
          'Folytatja a hibajelentés küldését?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Igen, küldöm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await launchUrl(
          Uri.parse(
            Mailto(
              to: ['app@reflabs.hu'],
              subject: 'Hibajelentés ${settings.packageInfo.version}+${settings.packageInfo.buildNumber}: $title',
              body: '''


Kérjük, írja le fölé, mit csinált amikor a hiba fellépett:



----

Hiba címe: $title
Hiba üzenete: $message

${error != null ? 'Hiba objektum: $error\n' : ''}
${stackTrace != null ? 'Stack Trace:\n$stackTrace' : ''}''',
            ).toString(),
          ),
        );
      } catch (e) {
        // Fallback if email launch fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nem sikerült megnyitni az e-mail alkalmazást'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}