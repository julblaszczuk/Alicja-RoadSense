# Alicja RoadSense

AI-powered driving assistant with real-time collision detection, vehicle proximity monitoring, and predictive safety alerts.

## Features

- **Collision Detection** - Real-time detection of potential collisions with vehicles, pedestrians, and obstacles
- **Vehicle Proximity Monitoring** - Track approaching vehicles, distance, and relative speed
- **Dangerous Event Detection** - Recognize sudden braking, lane departure, and hazardous situations
- **AI Prediction** - Predict dangerous events before they happen using LSTM/Transformer models
- **Route Analysis** - Analyze route risk and road conditions
- **Navigation** - Turn-by-turn navigation with real-time warnings
- **Settings** - Customizable detection sensitivity and alert preferences
- **Trip History** - View past trips and incident statistics

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system architecture.

### Core Components

- **Sensor Layer** - Camera, GPS, IMU
- **AI/ML Pipeline** - YOLOv8n BDD100K (TFLite INT8)
- **Alert System** - Visual, audio, and haptic warnings
- **Navigation Engine** - Mapbox integration with offline maps (planned)
- **Data Layer** - SQLite for local storage

## Tech Stack

- **Framework**: Flutter 3.44+ (Dart)
- **AI Models**: TensorFlow Lite (YOLOv8n BDD100K)
- **State Management**: Riverpod
- **Maps**: Mapbox (planned), OpenStreetMap data
- **Database**: SQLite

## Setup

### Prerequisites

- Flutter SDK >= 3.5.0
- Android Studio / Xcode
- Physical device (camera + GPS required)

### Installation

```bash
# Clone repository
git clone https://github.com/julblaszczuk/Alicja-RoadSense.git
cd Alicja-RoadSense

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Permissions

The app requires:
- Camera (required)
- Location (required)
- Storage (for saving clips)
- Notifications (for alerts)

## Project Structure

```
Alicja-RoadSense/
├── lib/
│   ├── core/              # Settings provider, alert manager, theme
│   ├── ai/                # Vision engine (YOLOv8), models, road systems
│   ├── ui/
│   │   ├── screens/       # Dashboard, Navigation, Settings, History, etc.
│   │   └── widgets/       # Detection overlay, risk indicator, mini-map, etc.
│   └── main.dart          # App entry point
├── models/                # TFLite models (YOLOv8n BDD100K)
├── assets/                # Logo, sounds, maps
├── android/               # Android-specific configuration
└── test/                  # Unit and widget tests
```

## Screens

- **Splash Screen** - Branded loading screen with logo
- **Dashboard** - Main camera view with detection overlay, risk indicator, speed display, mini-map
- **Navigation** - Mapbox navigation with saved places
- **Settings** - Detection confidence, alert volume, toggle preferences
- **Trip History** - Past trips with statistics
- **Incident Details** - Detailed view of detected incidents

## Development Roadmap

### Phase 1: Foundation ✅
- [x] Setup Flutter project
- [x] Integrate camera API
- [x] Setup TFLite inference
- [x] Train YOLOv8n on BDD100K dataset
- [x] Basic object detection (10 classes)
- [x] UI (Dashboard, Settings, Navigation, History)

### Phase 2: Core Features
- [ ] Multi-object tracking (SORT)
- [ ] TTC calculation
- [ ] GPS/IMU integration
- [ ] Sensor fusion (Kalman filter)
- [ ] Alert system (visual/audio/haptic)
- [ ] Risk scoring algorithm

### Phase 3: Advanced AI
- [ ] Pedestrian detection
- [ ] Lane detection
- [ ] Prediction model (LSTM)
- [ ] Collision prediction
- [ ] Vehicle approach detection
- [ ] Sudden braking detection

### Phase 4: Navigation & UX
- [ ] Mapbox integration
- [ ] Turn-by-turn navigation
- [ ] HUD overlay
- [ ] Trip recording
- [ ] Incident history
- [ ] Settings panel

### Phase 5: Polish & Testing
- [ ] Performance optimization
- [ ] Battery optimization
- [ ] Edge case handling
- [ ] Real-world testing
- [ ] User testing
- [ ] Bug fixes

### Phase 6: Release
- [ ] Beta testing
- [ ] App store submission
- [ ] Marketing materials
- [ ] Documentation
- [ ] Support system

## Performance Targets

- **Frame capture to detection**: <50ms
- **Detection to alert**: <100ms
- **End-to-end latency**: <150ms
- **Vehicle detection accuracy**: >95% recall, >90% precision
- **False positive rate**: <1 per 10 minutes
- **Battery consumption**: <15% per hour

## Privacy & Security

- **Local-first**: All processing on-device
- **No cloud upload**: Video/images never leave device
- **Anonymization**: Faces/license plates blurred in stored clips
- **Encryption**: Local database encrypted at rest
- **Retention**: Auto-delete old data (configurable)

## Safety Disclaimer

**IMPORTANT**: Alicja RoadSense is an **assistive tool only**. It does NOT replace driver attention and responsibility.

- Always keep your eyes on the road
- Do NOT rely solely on alerts
- System may miss hazards or produce false positives
- Driver is always responsible for safe operation

## License

Proprietary - All rights reserved

## Contact

For questions, feedback, or support:
- Email: support@alicja-roadsense.com
- Website: https://alicja-roadsense.com

---

**Built with Flutter and TensorFlow Lite**
