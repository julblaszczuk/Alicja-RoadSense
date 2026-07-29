# Alicja RoadSense

AI-powered driving assistant with real-time collision detection, vehicle proximity monitoring, and predictive safety alerts.

## Features

- **Collision Detection** - Real-time detection of potential collisions with vehicles, pedestrians, and obstacles
- **Vehicle Proximity Monitoring** - Track approaching vehicles, distance, and relative speed
- **Dangerous Event Detection** - Recognize sudden braking, lane departure, and hazardous situations
- **AI Prediction** - Predict dangerous events before they happen using LSTM/Transformer models
- **Route Analysis** - Analyze route risk and road conditions
- **Navigation** - Turn-by-turn navigation with real-time warnings

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system architecture.

### Core Components

- **Sensor Layer** - Camera, GPS, IMU, Microphone
- **AI/ML Pipeline** - MobileNet/EfficientDet + Prediction Engine
- **Alert System** - Visual, audio, and haptic warnings
- **Navigation Engine** - Mapbox integration with offline maps
- **Data Layer** - SQLite for local storage

## Tech Stack

- **Framework**: Flutter (Dart)
- **AI Models**: TensorFlow Lite (MobileNet SSD, EfficientDet-Lite)
- **Maps**: Mapbox
- **Database**: SQLite
- **State Management**: Riverpod

## Setup

### Prerequisites

- Flutter SDK >= 3.5.0
- Android Studio / Xcode
- Physical device (camera + GPS required)

### Installation

```bash
# Clone repository
cd roadsense

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Permissions

The app requires:
- Camera (required)
- Location (required)
- Microphone (optional, for audio detection)
- Storage (for saving clips)
- Notifications (for alerts)

## Project Structure

```
roadsense/
├── lib/
│   ├── core/              # Event bus, state management, config
│   ├── sensors/           # Camera, GPS, IMU managers
│   ├── ai/                # Vision engine, prediction, risk scoring
│   ├── alerts/            # Alert system (visual/audio/haptic)
│   ├── navigation/        # Maps, routing, turn-by-turn
│   ├── data/              # SQLite, event store, models
│   └── ui/                # Screens, widgets, HUD
├── models/                # TFLite models (MobileNet, EfficientDet)
├── assets/                # Images, sounds, fonts
└── test/                  # Unit and widget tests
```

## Development Roadmap

### Phase 1: Foundation (Weeks 1-4)
- [ ] Setup Flutter project
- [ ] Integrate camera API
- [ ] Setup TFLite inference
- [ ] Train/convert MobileNet SSD model
- [ ] Basic object detection (vehicles)
- [ ] Simple UI (camera feed + detections)

### Phase 2: Core Features (Weeks 5-8)
- [ ] Multi-object tracking (SORT)
- [ ] TTC calculation
- [ ] GPS/IMU integration
- [ ] Sensor fusion (Kalman filter)
- [ ] Alert system (visual/audio)
- [ ] Risk scoring algorithm

### Phase 3: Advanced AI (Weeks 9-12)
- [ ] Pedestrian detection
- [ ] Lane detection
- [ ] Prediction model (LSTM)
- [ ] Collision prediction
- [ ] Vehicle approach detection
- [ ] Sudden braking detection

### Phase 4: Navigation & UX (Weeks 13-16)
- [ ] Mapbox integration
- [ ] Turn-by-turn navigation
- [ ] HUD overlay
- [ ] Trip recording
- [ ] Incident history
- [ ] Settings panel

### Phase 5: Polish & Testing (Weeks 17-20)
- [ ] Performance optimization
- [ ] Battery optimization
- [ ] Edge case handling
- [ ] Real-world testing
- [ ] User testing
- [ ] Bug fixes

### Phase 6: Release (Weeks 21-24)
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
