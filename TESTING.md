# Testing Guide for Énekeskönyv App

This document describes the testing infrastructure and practices for the Énekeskönyv app.

## Test Structure

The app uses a comprehensive testing strategy with multiple types of tests:

### Unit Tests (`test/unit/`)
- Test individual functions and classes in isolation
- Focus on business logic and utility functions
- Mock external dependencies
- Fast execution time

### Widget Tests (`test/widget/`)
- Test individual widgets and their behavior
- Test UI interactions and state changes
- Mock dependencies and services
- Verify widget rendering and user interactions

### Integration Tests (`integration_test/`)
- Test complete user flows and app behavior
- Test real app scenarios end-to-end
- Use actual device/simulator environment
- Slower execution but high confidence

### Test Helpers (`test/helpers/`)
- Common utilities and helper functions for tests
- Mock data creation
- Test widget wrappers
- Shared test setup and teardown

## Running Tests

### Quick Test Run
```bash
flutter test
```

### Run Specific Test Types
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests only
flutter test integration_test/
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run All Tests (Recommended)
```bash
./scripts/run_tests.sh
```

## Test Coverage

The app aims for high test coverage across all critical functionality:

- **Utils functions**: 100% coverage
- **Settings Provider**: 95%+ coverage
- **Widget components**: 90%+ coverage
- **Core user flows**: 85%+ coverage

### Viewing Coverage Reports
After running tests with coverage:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Testing Best Practices

### Unit Tests
- Test one function/method per test case
- Use descriptive test names that explain the expected behavior
- Follow Arrange-Act-Assert pattern
- Mock external dependencies
- Test both happy path and error cases

### Widget Tests
- Use `testWidgets()` for widget testing
- Pump widgets with necessary providers
- Test user interactions with `tester.tap()`, `tester.enterText()`, etc.
- Verify widget presence with `expect(find.byType(...), findsOneWidget)`
- Use `pumpAndSettle()` to wait for animations

### Integration Tests
- Test complete user journeys
- Use realistic data and scenarios
- Wait for async operations to complete
- Break large tests into smaller, focused test functions
- Use helper functions to reduce code duplication

## Test Data Management

### Mock Data
Use `TestHelper.createMockSongBooks()` to create consistent test data:
```dart
setUp(() {
  TestHelper.setupMockSongBooks();
});

tearDown(() {
  TestHelper.cleanup();
});
```

### Settings Provider Testing
Use `TestHelper.createMockSettingsProvider()` for consistent provider setup:
```dart
final settingsProvider = TestHelper.createMockSettingsProvider(
  book: Book.blue,
  fontSize: 16.0,
);
```

## Continuous Integration

The GitHub Actions workflow automatically runs:
1. Static analysis (`flutter analyze`)
2. Unit tests
3. Widget tests
4. Integration tests

All tests must pass before code can be merged.

## Common Test Patterns

### Testing State Changes
```dart
testWidgets('should update state when button pressed', (tester) async {
  bool stateChanged = false;
  
  await tester.pumpWidget(TestHelper.createTestWidget(
    child: StatefulWidget(
      onStateChange: () => stateChanged = true,
    ),
  ));
  
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  expect(stateChanged, isTrue);
});
```

### Testing Navigation
```dart
testWidgets('should navigate to new page', (tester) async {
  await tester.pumpWidget(TestHelper.createTestWidget(
    child: HomePage(),
  ));
  
  await tester.tap(find.text('Go to Song'));
  await tester.pumpAndSettle();
  
  expect(find.byType(SongPage), findsOneWidget);
});
```

### Testing Error Handling
```dart
test('should throw error for invalid input', () {
  expect(
    () => parseVerseId('invalid'),
    throwsA(contains('Helytelen link')),
  );
});
```

## Writing New Tests

When adding new features:

1. **Start with unit tests** for business logic
2. **Add widget tests** for new UI components
3. **Update integration tests** for new user flows
4. **Run tests frequently** during development
5. **Ensure good coverage** of critical paths

### Test File Naming
- Unit tests: `feature_name_test.dart`
- Widget tests: `widget_name_test.dart`
- Integration tests: `flow_name_test.dart`

### Test Organization
```dart
void main() {
  group('Feature Name Tests', () {
    setUp(() {
      // Common setup
    });
    
    tearDown(() {
      // Common cleanup
    });
    
    group('Sub-feature Tests', () {
      test('should handle specific case', () {
        // Test implementation
      });
    });
  });
}
```

## Debugging Tests

### Running Single Test
```bash
flutter test test/unit/utils_test.dart -n "specific test name"
```

### Debugging Widget Tests
Use `debugDumpApp()` to see widget tree:
```dart
testWidgets('debug widget tree', (tester) async {
  await tester.pumpWidget(MyWidget());
  debugDumpApp();
});
```

### Integration Test Debugging
Add screenshots for debugging:
```dart
await tester.binding.takeScreenshot('debug_screenshot');
```

## Performance Testing

For performance-critical features:
- Use `flutter test --plain-name="performance"` for performance tests
- Measure frame times and memory usage
- Test with large datasets
- Profile widget builds and redraws

This testing infrastructure ensures the Énekeskönyv app maintains high quality and reliability across all features and platforms.