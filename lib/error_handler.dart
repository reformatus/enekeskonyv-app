import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'error_dialog.dart';
import 'settings_provider.dart';

/// Global error handler for uncaught exceptions and Flutter framework errors
class GlobalErrorHandler {
  static late GlobalKey<NavigatorState> _navigatorKey;
  static late SettingsProvider _settingsProvider;
  
  /// Initialize the global error handler
  static void initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required SettingsProvider settingsProvider,
  }) {
    _navigatorKey = navigatorKey;
    _settingsProvider = settingsProvider;
    
    // Handle Flutter framework errors (widget errors, render errors, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error for debugging
      developer.log(
        'Flutter framework error caught',
        error: details.exception,
        stackTrace: details.stack,
        name: 'ErrorHandler',
      );
      
      // In debug mode, use the default Flutter error handler
      if (kDebugMode) {
        FlutterError.presentError(details);
        return;
      }
      
      // In release mode, show user-friendly error dialog
      _showErrorDialog(
        title: 'Alkalmazáshiba',
        message: 'Váratlan hiba történt az alkalmazásban. Ha a probléma folytatódik, kérjük küldjön hibajelentést.',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    
    // Handle async errors that are not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      developer.log(
        'Uncaught async error',
        error: error,
        stackTrace: stackTrace,
        name: 'ErrorHandler',
      );
      
      // In debug mode, also print to console
      if (kDebugMode) {
        debugPrint('Uncaught async error: $error');
        debugPrint('Stack trace: $stackTrace');
      }
      
      // Show user-friendly error dialog
      _showErrorDialog(
        title: 'Háttérhiba',
        message: 'Hiba történt egy háttérműveletnél. Az alkalmazás továbbra is használható.',
        error: error,
        stackTrace: stackTrace,
      );
      
      return true; // Indicates that we handled the error
    };
  }
  
  /// Shows error dialog if navigator context is available
  static void _showErrorDialog({
    required String title,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Use a timer to ensure we don't block the error handling
    Timer(const Duration(milliseconds: 100), () {
      final context = _navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ErrorDialog.show(
          context: context,
          title: title,
          message: message,
          settings: _settingsProvider,
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }
  
  /// Manually handle an error with custom context
  static Future<void> handleError({
    required BuildContext context,
    required String title,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    // Log the error for debugging
    developer.log(
      'Manual error handling: $title',
      error: error,
      stackTrace: stackTrace,
      name: 'ErrorHandler',
    );
    
    await ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      settings: _settingsProvider,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Handle network/connectivity errors with specific messaging
  static Future<void> handleNetworkError({
    required BuildContext context,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await handleError(
      context: context,
      title: 'Kapcsolati hiba',
      message: 'Nem sikerült kapcsolódni az internethez. Ellenőrizze a hálózati kapcsolatot és próbálja újra.',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Handle file/storage errors with specific messaging
  static Future<void> handleStorageError({
    required BuildContext context,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await handleError(
      context: context,
      title: 'Tárolási hiba',
      message: 'Hiba történt az adatok mentése vagy betöltése közben. Ellenőrizze, hogy van-e elegendő tárhely.',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Handle parsing/data format errors
  static Future<void> handleDataError({
    required BuildContext context,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await handleError(
      context: context,
      title: 'Adatformátum hiba',
      message: 'Az alkalmazás adatai sérültek vagy hibás formátumúak. Próbálja meg újraindítani az alkalmazást.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}