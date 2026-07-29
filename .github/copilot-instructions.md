# GitHub Copilot Instructions

## Project: Alicja RoadSense

Flutter mobile app - AI driving assistant with real-time collision detection.

## Key Rules

1. **Language**: English only (code, comments, commits)
2. **Framework**: Flutter 3.5+ with Dart
3. **State**: Riverpod (not Provider, not Bloc)
4. **AI**: TensorFlow Lite on-device inference
5. **Style**: Follow Dart effective dart guidelines
6. **Safety**: This is safety-critical - handle all errors, never block UI thread
7. **Performance**: Target <150ms end-to-end latency
8. **Testing**: Write tests for all business logic

## Code Patterns

```dart
// Use Riverpod providers
final configProvider = StateProvider<AppConfig>((ref) => const AppConfig());

// Use const constructors
const MyWidget({super.key});

// Handle errors in async code
try {
  final result = await riskyOperation();
} catch (e) {
  logger.e('Operation failed', error: e);
  // Show user-friendly error
}
```

## File Organization

- `lib/core/` - Infrastructure (event bus, config)
- `lib/sensors/` - Hardware (camera, GPS, IMU)
- `lib/ai/` - ML (vision, tracking, prediction)
- `lib/alerts/` - Alert system
- `lib/navigation/` - Maps and routing
- `lib/data/` - Local storage
- `lib/ui/` - Screens and widgets

## Commit Format

```
feat(vision): add pedestrian detection
fix(alerts): resolve haptic not triggering
test(tracker): add unit tests for SORT
```

## Do NOT

- Use `print()` - use `logger` package
- Use `dynamic` - use explicit types
- Block UI thread with heavy computation
- Skip error handling
- Add large files to git (models go in .gitignore)
