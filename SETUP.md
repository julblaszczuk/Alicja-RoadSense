# Alicja RoadSense - Setup Guide

## Quick Start

### 1. Install Flutter SDK

Download and install Flutter SDK >= 3.5.0:
https://flutter.dev/docs/get-started/install

### 2. Setup Development Environment

**Android:**
- Install Android Studio
- Install Android SDK (API level 33+)
- Enable USB debugging on device

**iOS:**
- Install Xcode (macOS only)
- Install CocoaPods: `sudo gem install cocoapods`

### 3. Install Dependencies

```bash
cd roadsense
flutter pub get
```

### 4. Prepare AI Models

Download MobileNet SSD TFLite model:
```bash
# Download from TensorFlow Hub or train custom model
# Place in: models/mobilenet_ssd.tflite
```

**Recommended models:**
- MobileNet SSD v1 (COCO) - fast, good accuracy
- EfficientDet-Lite - balanced performance/accuracy
- YOLO-Nano - alternative option

### 5. Run on Device

```bash
# Check connected devices
flutter devices

# Run on selected device
flutter run

# Or specify device
flutter run -d <device_id>
```

### 6. Build Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
roadsense/
├── lib/
│   ├── main.dart              # App entry point
│   ├── core/
│   │   ├── event_bus.dart     # Event system
│   │   └── config.dart        # App configuration
│   ├── sensors/               # Camera, GPS, IMU (TODO)
│   ├── ai/
│   │   ├── vision_engine.dart # TFLite inference
│   │   └── models.dart        # Detection models
│   ├── alerts/                # Alert system (TODO)
│   ├── navigation/            # Maps (TODO)
│   ├── data/                  # Database (TODO)
│   └── ui/
│       ├── screens/
│       │   ├── splash_screen.dart
│       │   └── dashboard_screen.dart
│       └── widgets/
│           ├── hud_overlay.dart
│           ├── risk_indicator.dart
│           └── speed_display.dart
├── models/                    # TFLite models
├── assets/                    # Images, sounds
├── test/                      # Unit tests
├── pubspec.yaml               # Dependencies
└── ARCHITECTURE.md            # System architecture
```

## Current Status

**Implemented:**
- ✅ Flutter project setup
- ✅ Camera integration (basic)
- ✅ TFLite inference pipeline
- ✅ Object detection (MobileNet SSD)
- ✅ HUD overlay with bounding boxes
- ✅ Risk indicator widget
- ✅ Speed display (GPS)
- ✅ Event bus system
- ✅ Configuration management

**TODO:**
- ⏳ Multi-object tracking (SORT)
- ⏳ TTC calculation
- ⏳ IMU integration
- ⏳ Sensor fusion (Kalman filter)
- ⏳ Alert system (audio/haptic)
- ⏳ Mapbox navigation
- ⏳ Trip recording
- ⏳ Database (SQLite)
- ⏳ Settings panel
- ⏳ Performance optimization

## Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage
```

## Troubleshooting

**Camera not working:**
- Check permissions in AndroidManifest.xml / Info.plist
- Ensure physical device (emulator camera may not work)

**TFLite model not loading:**
- Verify model path in `vision_engine.dart`
- Check model format (must be .tflite)

**GPS not updating:**
- Enable location services on device
- Grant location permission
- Test outdoors for better signal

## Next Steps

1. **Add MobileNet SSD model** to `models/` folder
2. **Test camera + detection** on real device
3. **Implement multi-object tracking** (SORT algorithm)
4. **Add TTC calculation** based on object size/velocity
5. **Integrate IMU** for sudden braking detection
6. **Build alert system** (audio + haptic feedback)

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Camera Plugin](https://pub.dev/packages/camera)
- [MobileNet SSD](https://github.com/tensorflow/models/tree/master/research/object_detection)

---

**Built with Flutter and TensorFlow Lite**
