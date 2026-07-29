# Alicja RoadSense - OpenCode Instructions

## Project Type

Flutter mobile application (Dart) - AI-powered driving assistant.

## Agent Workflow

### Before Starting Any Task

1. Read `AGENTS.md` for project overview and rules
2. Read `ARCHITECTURE.md` for system design
3. Check existing code patterns in the target directory
4. Understand the safety-critical nature of this project

### Task Execution

1. **Plan first** - Think about the approach before coding
2. **Small changes** - Make focused, incremental changes
3. **Test** - Write tests for new logic
4. **Verify** - Run `flutter analyze` and `flutter test`
5. **Document** - Update docs if architecture changes

### File Locations

| Purpose | Location |
|---------|----------|
| Entry point | `lib/main.dart` |
| Core infra | `lib/core/` |
| Hardware sensors | `lib/sensors/` |
| AI/ML pipeline | `lib/ai/` |
| Alert system | `lib/alerts/` |
| Navigation | `lib/navigation/` |
| Local storage | `lib/data/` |
| UI screens | `lib/ui/screens/` |
| UI widgets | `lib/ui/widgets/` |
| Tests | `test/` |
| AI models | `models/` |
| Assets | `assets/` |

### Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Analyze code
flutter analyze

# Format code
dart format .

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Code Patterns

#### State Management (Riverpod)

```dart
// Provider definition
final configProvider = StateProvider<AppConfig>((ref) => const AppConfig());

// Reading in widget
final config = ref.watch(configProvider);

// Updating
ref.read(configProvider.notifier).state = config.copyWith(...);
```

#### Async Operations

```dart
// Always handle errors
try {
  final result = await someAsyncOperation();
  return result;
} catch (e, stack) {
  logger.e('Operation failed', error: e, stackTrace: stack);
  rethrow; // or return fallback
}
```

#### Event Bus

```dart
// Emit event
EventBus().emitType(EventType.detectionMade, detections);

// Listen
EventBus().on(EventType.collisionRisk).listen((event) {
  // Handle collision risk
});
```

### Safety Rules

1. **Never block UI thread** - Use async/await
2. **Always handle errors** - Show user-friendly messages
3. **Fail safely** - Warning > crash
4. **Privacy first** - No media upload without consent
5. **Battery aware** - Optimize for mobile

### Performance Targets

- Frame processing: <50ms
- Detection → alert: <100ms
- End-to-end: <150ms
- Memory: <500MB
- Battery: <15%/hour

### Git Workflow

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make small, focused commits
3. Use conventional commits: `feat(scope): description`
4. Run `flutter analyze` and `flutter test`
5. Create PR with description

### DO NOT

- Use `print()` → use `logger` package
- Use `dynamic` → use explicit types
- Block UI thread
- Skip error handling
- Commit large files (models, binaries)
- Modify without testing on real device
