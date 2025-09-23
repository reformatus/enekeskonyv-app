# Error Handling Documentation

## Overview

The Énekeskönyv app now includes a comprehensive error handling system that provides better user experience with Hungarian error messages, confirmation dialogs, and proper error reporting.

## Components

### 1. ErrorDialog (`lib/error_dialog.dart`)

A modern, user-friendly error dialog that replaces the old SnackBar approach.

**Features:**
- Clear Hungarian error messages
- Show/hide technical details option
- Confirmation dialog before sending error reports
- Professional UI with proper styling

**Usage:**
```dart
await ErrorDialog.show(
  context: context,
  title: 'Hiba címe',
  message: 'Részletes hibaüzenet',
  settings: settingsProvider,
  error: exceptionObject,
  stackTrace: stackTrace,
);
```

### 2. GlobalErrorHandler (`lib/error_handler.dart`)

Catches uncaught Flutter framework errors and async exceptions globally.

**Features:**
- Flutter framework error handling
- Async error catching
- Specific error types (network, storage, data format)
- Automatic error logging

**Initialization:**
The handler is automatically initialized in `main.dart` when the settings provider is ready.

**Manual Error Handling:**
```dart
// General error
await GlobalErrorHandler.handleError(
  context: context,
  title: 'Hiba címe',
  message: 'Hibaüzenet',
  error: e,
  stackTrace: s,
);

// Network specific
await GlobalErrorHandler.handleNetworkError(
  context: context,
  error: e,
  stackTrace: s,
);

// Storage specific
await GlobalErrorHandler.handleStorageError(
  context: context,
  error: e,
  stackTrace: s,
);

// Data format specific
await GlobalErrorHandler.handleDataError(
  context: context,
  error: e,
  stackTrace: s,
);
```

### 3. Enhanced SettingsProvider

The `showError()` method now uses the new error dialog system with fallback to SnackBar.

**Improvements:**
- Better error messages in Hungarian
- Context-aware error descriptions
- Professional error dialog UI

### 4. URL Launch Error Handling

All URL launches (email, external links) now include proper error handling with network-specific error messages.

## Error Types and Messages

### Standard Error Categories

1. **Alkalmazáshiba** - General application errors
2. **Kapcsolati hiba** - Network/connectivity issues
3. **Tárolási hiba** - Storage/file system errors
4. **Adatformátum hiba** - Data parsing/format errors
5. **Háttérhiba** - Background/async operation errors

### Message Guidelines

- All messages are in Hungarian
- Include context about what the user was doing
- Suggest next steps or workarounds when possible
- Maintain helpful but not overly technical language

## Best Practices

### 1. Always Handle Async Operations

```dart
try {
  await someAsyncOperation();
} catch (e, s) {
  if (mounted) {
    await GlobalErrorHandler.handleError(
      context: context,
      title: 'Megfelelő cím',
      message: 'Leíró hibaüzenet',
      error: e,
      stackTrace: s,
    );
  }
}
```

### 2. Use Specific Error Types

Use the appropriate error handler for the operation type:
- Network operations: `handleNetworkError()`
- File operations: `handleStorageError()`
- JSON/data parsing: `handleDataError()`

### 3. Check Context Validity

Always check if context is still mounted before showing error dialogs:

```dart
if (context.mounted) {
  await GlobalErrorHandler.handleError(...);
}
```

### 4. Graceful Degradation

When possible, allow the app to continue functioning despite errors:

```dart
try {
  final data = await loadOptionalData();
  return data;
} catch (e, s) {
  // Log error but continue with default/fallback data
  await GlobalErrorHandler.handleError(...);
  return defaultData;
}
```

## Testing

### Debug Mode Test Widget

In debug mode, a test widget is available on the home page to manually trigger different error scenarios:

- Settings errors
- Network errors
- Data format errors
- Flutter framework errors
- Async errors

This allows developers to verify that the error handling works correctly.

### Error Logging

All errors are logged using `developer.log()` for debugging purposes while maintaining user-friendly error messages.

## Migration from Old System

The old SnackBar-based error handling has been replaced but maintained as a fallback. Key changes:

1. `showError()` now shows error dialog instead of SnackBar
2. Email reports require user confirmation
3. Technical details are hideable/showable
4. Better error categorization and messaging

## Future Improvements

1. Error analytics/reporting integration
2. Offline error queuing for later reporting
3. Error recovery suggestions
4. Internationalization support beyond Hungarian