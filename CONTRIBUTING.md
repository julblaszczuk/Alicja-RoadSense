# Contributing to Alicja RoadSense

Thank you for your interest in contributing! This is a safety-critical application, so we prioritize quality and reliability.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/Alicja-RoadSense.git`
3. Install dependencies: `flutter pub get`
4. Create a branch: `git checkout -b feature/your-feature`

## Development Setup

### Prerequisites

- Flutter SDK >= 3.5.0
- Android Studio or Xcode
- Physical device recommended (camera + GPS required)

### Running the App

```bash
flutter pub get
flutter run
```

### Running Tests

```bash
flutter test
flutter analyze
```

## How to Contribute

### Bug Reports

- Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.yml)
- Include steps to reproduce
- Add screenshots if applicable
- Mention device and OS version

### Feature Requests

- Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.yml)
- Explain the problem it solves
- Consider alternatives

### Code Changes

1. **Small fixes**: Fork, branch, commit, PR
2. **Large features**: Open issue first to discuss
3. **Safety-critical**: Extra review required

## Code Standards

### Language

- All code, comments, commits, and docs in **English**

### Style

- Follow [Dart Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `final` for immutable fields
- Use `const` constructors
- Prefer explicit types
- Single responsibility per class/file

### Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(vision): add pedestrian detection model
fix(alerts): resolve haptic feedback on iOS
refactor(tracker): optimize SORT for mobile
docs(readme): update setup instructions
test(vision): add TTC calculation tests
chore(deps): update tflite_flutter
```

### Pull Requests

1. Create feature branch from `main`
2. Make small, focused commits
3. Write/update tests
4. Run `flutter analyze` and `flutter test`
5. Update documentation
6. Fill out PR template
7. Request review

## Architecture

See [AGENTS.md](AGENTS.md) and [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture.

### Key Directories

```
lib/
├── core/        # Event bus, config
├── sensors/     # Camera, GPS, IMU
├── ai/          # Vision, tracking, prediction
├── alerts/      # Alert system
├── navigation/  # Maps, routing
├── data/        # Local storage
└── ui/          # Screens, widgets
```

## Safety Guidelines

This is a **safety-critical** application:

1. Never block the UI thread
2. Always handle errors
3. Fail safely (warn, don't crash)
4. Never upload media without consent
5. Optimize for battery
6. Test on real devices

## Performance Targets

- Frame processing: <50ms
- Detection → alert: <100ms
- End-to-end: <150ms
- Memory: <500MB
- Battery: <15%/hour

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Coverage

```bash
flutter test --coverage
```

## Questions?

- [GitHub Discussions](https://github.com/julblaszczuk/Alicja-RoadSense/discussions)
- [Open an Issue](https://github.com/julblaszczuk/Alicja-RoadSense/issues)

---

Thank you for contributing! 🚗💨
