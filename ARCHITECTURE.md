# Alicja RoadSense - Architecture

## Overview

**Alicja RoadSense** to mobilny asystent kierowcy z AI, który w czasie rzeczywistym wykrywa zagrożenia drogowe, monitoruje zbliżające się pojazdy, przewiduje kolizje i analizuje trasę.

### Core Capabilities

- **Collision Detection** - wykrywanie potencjalnych kolizji z pojazdami, pieszymi, przeszkodami
- **Vehicle Proximity Monitoring** - monitorowanie zbliżających się pojazdów, odległości, prędkości
- **Dangerous Event Detection** - rozpoznawanie niebezpiecznych zdarzeń (gwałtowne hamowanie, wtargnięcie na pas)
- **Route Analysis** - analiza trasy, warunków drogowych, ryzyka
- **AI Prediction** - przewidywanie zagrożeń na podstawie wzorców ruchu i kontekstu
- **Navigation** - nawigacja z ostrzeżeniami w czasie rzeczywistym

### Platform

- **Target**: Mobile (Android/iOS)
- **Framework**: React Native / Flutter (TBD)
- **AI Models**: MobileNet/EfficientDet (on-device inference)
- **Sensors**: Camera, GPS, Accelerometer, Gyroscope, Microphone

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Alicja RoadSense                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  UI Layer (React Native / Flutter)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Dashboard   │  │  HUD View    │  │  Settings    │      │
│  │  (Main)      │  │  (Overlay)   │  │  Panel       │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Application Core                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Event Bus   │  │  State Mgr   │  │  Config      │      │
│  │  (Async)     │  │  (Redux/     │  │  Manager     │      │
│  │              │  │   Zustand)   │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  AI/ML Pipeline                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Vision      │  │  Prediction  │  │  Risk        │      │
│  │  Engine      │  │  Engine      │  │  Scorer      │      │
│  │  (MobileNet/ │  │  (LSTM/      │  │  (Real-time  │      │
│  │   EfficientD)│  │   Transformer)│  │   scoring)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Sensor Layer                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Camera      │  │  GPS/        │  │  IMU         │      │
│  │  Manager     │  │  Location    │  │  (Accel/     │      │
│  │  (Frames)    │  │  (Position)  │  │   Gyro)      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Data Layer                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Local DB    │  │  Event Store │  │  Route Cache │      │
│  │  (SQLite/    │  │  (Incidents) │  │  (Maps)      │      │
│  │   Realm)     │  │              │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Services (Optional)                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Cloud Sync  │  │  Emergency   │  │  Traffic     │      │
│  │  (Backup)    │  │  Services    │  │  Data API    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Sensor Layer

#### Camera Manager
- **Purpose**: Capture video frames from device camera
- **Tech**: Platform-specific camera API (CameraX for Android, AVFoundation for iOS)
- **Output**: Stream of frames (30 FPS target)
- **Processing**: Preprocessing (resize, normalize) for AI model

#### GPS/Location Manager
- **Purpose**: Track position, speed, heading
- **Tech**: Platform location services
- **Output**: Lat/Lon, speed (km/h), bearing, altitude
- **Frequency**: 1-5 Hz

#### IMU (Inertial Measurement Unit)
- **Purpose**: Detect sudden movements, braking, acceleration
- **Tech**: Accelerometer + Gyroscope
- **Output**: G-force, rotation rates
- **Frequency**: 50-100 Hz

#### Microphone (Optional)
- **Purpose**: Detect sirens, horns, crashes
- **Tech**: Audio capture + FFT analysis
- **Output**: Audio events classification

---

### 2. AI/ML Pipeline

#### Vision Engine
**Models**:
- **Primary**: MobileNet SSD / EfficientDet-Lite (vehicle detection)
- **Secondary**: Pose estimation (pedestrian detection)
- **Tertiary**: Lane detection model

**Pipeline**:
```
Frame → Preprocess → Model Inference → Post-process → Detections
         (resize,      (TFLite/         (NMS,          (bbox, class,
          normalize)    CoreML)          tracking)       confidence)
```

**Detections**:
- Vehicles (cars, trucks, motorcycles, bicycles)
- Pedestrians
- Traffic signs/lights
- Lane markings
- Obstacles

**Tracking**:
- Multi-object tracking (SORT/DeepSORT)
- Velocity estimation (optical flow / Kalman filter)
- Time-to-collision (TTC) calculation

#### Prediction Engine
**Purpose**: Predict dangerous events before they happen

**Input Features**:
- Vehicle positions, velocities, accelerations
- Ego-vehicle dynamics (speed, braking, steering)
- Road context (curves, intersections, weather)
- Historical patterns

**Model**: LSTM / Transformer (sequence prediction)
**Output**: Risk score (0-100), event type, time-to-event

#### Risk Scorer
**Purpose**: Real-time risk assessment

**Factors**:
- Time-to-collision (TTC) with detected objects
- Following distance (time gap)
- Lane departure risk
- Speed vs. road conditions
- Intersection conflict probability

**Output**: 
- Overall risk level (LOW / MEDIUM / HIGH / CRITICAL)
- Specific threats (list)
- Recommended actions

---

### 3. Application Core

#### Event Bus
**Purpose**: Asynchronous communication between components

**Events**:
- `FRAME_CAPTURED` - new camera frame
- `DETECTION_MADE` - object detected
- `COLLISION_RISK` - high collision probability
- `VEHICLE_APPROACHING` - fast-approaching vehicle
- `SUDDEN_BRAKING` - ego-vehicle hard brake
- `ROUTE_UPDATED` - navigation update
- `ALERT_TRIGGERED` - warning to user

#### State Manager
**Purpose**: Centralized application state

**State**:
- Current detections (list of tracked objects)
- Ego-vehicle state (speed, position, heading)
- Risk level and active threats
- Navigation state (route, ETA, next maneuver)
- User settings and preferences

#### Config Manager
**Purpose**: User preferences and system configuration

**Settings**:
- Detection sensitivity
- Alert thresholds (TTC, distance)
- Audio/visual/haptic feedback preferences
- Privacy settings (data retention)
- Model selection (performance vs. accuracy)

---

### 4. Alert System

#### Alert Types
1. **Visual**: HUD overlay, color-coded warnings, flashing indicators
2. **Audio**: Voice alerts, warning sounds
3. **Haptic**: Vibration patterns (severity-based)

#### Alert Priorities
- **CRITICAL** (immediate danger): Loud audio + strong vibration + red flash
- **HIGH** (approaching danger): Medium audio + vibration + orange
- **MEDIUM** (potential risk): Soft audio + yellow indicator
- **LOW** (informational): Visual only + blue indicator

#### Alert Logic
```
IF TTC < 2.0s AND relative_velocity > 30 km/h:
    TRIGGER CRITICAL alert
ELIF TTC < 4.0s AND object_approaching:
    TRIGGER HIGH alert
ELIF following_distance < 1.5s:
    TRIGGER MEDIUM alert
```

---

### 5. Navigation Engine

#### Features
- Turn-by-turn navigation
- Real-time traffic integration (optional)
- Route risk assessment (high-risk segments)
- Alternative route suggestions

#### Data Sources
- Offline maps (Mapbox / OSM)
- GPS positioning
- Optional: traffic API (Google Maps, Waze)

---

### 6. Data Layer

#### Local Database (SQLite / Realm)
**Tables**:
- `trips` - recorded journeys
- `incidents` - detected events (timestamp, type, severity, location)
- `routes` - saved routes
- `settings` - user preferences

#### Event Store
**Purpose**: Store detected incidents for analysis

**Schema**:
```json
{
  "id": "uuid",
  "timestamp": "ISO8601",
  "type": "collision_risk | vehicle_approaching | sudden_braking | ...",
  "severity": "low | medium | high | critical",
  "location": {"lat": 52.23, "lon": 21.01},
  "ego_speed": 65.5,
  "object_type": "vehicle | pedestrian | obstacle",
  "ttc": 2.3,
  "video_clip": "path/to/clip.mp4",
  "sensor_data": {...}
}
```

#### Route Cache
**Purpose**: Offline map tiles and route data

---

### 7. UI/UX

#### Dashboard (Main View)
- Live camera feed with AR overlay
- Speed indicator
- Risk level indicator (color-coded)
- Active alerts
- Mini-map with route

#### HUD (Heads-Up Display)
- Transparent overlay on camera feed
- Detected objects (bounding boxes)
- TTC indicators
- Navigation arrows
- Speed and distance info

#### Settings Panel
- Detection sensitivity
- Alert preferences
- Privacy controls
- Model selection
- Data export

#### Trip History
- List of recorded trips
- Incident timeline
- Risk heatmap
- Statistics (distance, time, incidents)

---

## Technology Stack

### Mobile Framework
**Option A: React Native**
- Pros: Cross-platform, large ecosystem, JavaScript/TypeScript
- Cons: Performance overhead for real-time CV
- Bridge: Native modules for camera/AI inference

**Option B: Flutter**
- Pros: Better performance, Dart, good camera plugins
- Cons: Smaller ML ecosystem
- Bridge: Platform channels for native code

**Option C: Native (Kotlin/Swift)**
- Pros: Best performance, direct API access
- Cons: Separate codebases for Android/iOS
- Recommendation: Start with React Native/Flutter, migrate critical paths to native

### AI/ML Frameworks
- **TensorFlow Lite** (Android/iOS)
- **Core ML** (iOS only, better performance)
- **MediaPipe** (Google's CV framework)
- **ONNX Runtime Mobile** (cross-platform)

### Computer Vision Models
- **MobileNet SSD** - fast object detection
- **EfficientDet-Lite** - balanced accuracy/speed
- **YOLO-Nano** - alternative detector
- **DeepSORT** - multi-object tracking

### Navigation
- **Mapbox** - offline maps, navigation SDK
- **OpenStreetMap** - free map data
- **Google Maps SDK** - traffic data (optional)

### Database
- **SQLite** - lightweight, embedded
- **Realm** - mobile-first database (optional)

### State Management
- **Redux / Zustand** (React Native)
- **Riverpod / Bloc** (Flutter)

---

## Data Flow

### Real-Time Processing Loop

```
1. Camera captures frame (30 FPS)
   ↓
2. Preprocess frame (resize, normalize)
   ↓
3. Run MobileNet/EfficientDet inference
   ↓
4. Post-process detections (NMS, filtering)
   ↓
5. Update object tracker (SORT/DeepSORT)
   ↓
6. Calculate TTC and risk scores
   ↓
7. Check alert thresholds
   ↓
8. IF risk > threshold:
     Trigger alert (visual/audio/haptic)
   ↓
9. Update UI (HUD overlay, dashboard)
   ↓
10. Store event if incident detected
    ↓
11. Repeat (target: <50ms per frame)
```

### Sensor Fusion

```
Camera frames ──┐
                ├──→ Sensor Fusion ──→ Unified State
GPS position ───┤     (Kalman Filter)
                │
IMU data ───────┘

Output:
- Ego-vehicle state (position, velocity, acceleration)
- Object states (relative position, velocity, predicted path)
- Confidence estimates
```

---

## Performance Requirements

### Latency Targets
- **Frame capture to detection**: <50ms
- **Detection to alert**: <100ms
- **End-to-end latency**: <150ms

### Accuracy Targets
- **Vehicle detection**: >95% recall, >90% precision
- **Pedestrian detection**: >90% recall, >85% precision
- **TTC estimation**: ±0.5s error
- **False positive rate**: <1 per 10 minutes

### Resource Usage
- **CPU**: <30% average (mid-range phone)
- **GPU**: <50% (for inference)
- **RAM**: <500MB
- **Battery**: <15% per hour (with screen on)
- **Storage**: <2GB (app + models + offline maps)

---

## Privacy & Security

### Data Handling
- **Local-first**: All processing on-device
- **No cloud upload**: Video/images never leave device (unless user explicitly exports)
- **Anonymization**: Faces/license plates blurred in stored clips
- **Encryption**: Local database encrypted at rest
- **Retention**: Auto-delete old data (configurable)

### Permissions
- Camera (required)
- Location (required)
- Microphone (optional, for audio detection)
- Storage (for saving clips)
- Notifications (for alerts)

---

## Development Roadmap

### Phase 1: Foundation (Weeks 1-4)
- [ ] Setup React Native / Flutter project
- [ ] Integrate camera API (frame capture)
- [ ] Setup TFLite / CoreML inference
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

---

## Risk Assessment

### Technical Risks
1. **Real-time performance**: Mobile devices may struggle with 30 FPS + AI inference
   - Mitigation: Optimize models, use GPU acceleration, reduce frame rate if needed
   
2. **Detection accuracy**: False positives/negatives in real-world conditions
   - Mitigation: Extensive testing, confidence thresholds, user feedback loop
   
3. **Battery drain**: Continuous camera + AI processing is power-hungry
   - Mitigation: Optimize code, reduce frame rate when stationary, user warnings
   
4. **GPS accuracy**: Urban canyons, tunnels, poor signal
   - Mitigation: IMU dead reckoning, map matching, graceful degradation

### Safety Risks
1. **False sense of security**: Users may over-rely on system
   - Mitigation: Clear disclaimers, driver responsibility warnings
   
2. **Distraction**: Alerts may distract from driving
   - Mitigation: Minimal UI, audio-only alerts, user customization
   
3. **System failure**: App crash or freeze while driving
   - Mitigation: Robust error handling, watchdog timer, fail-safe mode

### Legal Risks
1. **Liability**: System misses critical hazard
   - Mitigation: Terms of service, "assistive only" disclaimer
   
2. **Privacy**: Recording public spaces
   - Mitigation: Local processing, anonymization, user consent

---

## Success Metrics

### Technical KPIs
- Detection accuracy (precision/recall)
- False positive rate
- Latency (frame-to-alert)
- Battery consumption
- Crash-free sessions

### User KPIs
- Daily active users
- Session duration
- Incidents detected per trip
- User satisfaction (ratings)
- Retention rate

### Safety KPIs
- Near-misses detected
- Collision warnings issued
- User-reported incidents prevented
- Insurance claim reduction (long-term)

---

## Conclusion

**Alicja RoadSense** to ambitny projekt, który łączy computer vision, AI prediction i mobile development w aplikacji ratującej życie. Kluczowe jest:

1. **Real-time performance** - <150ms end-to-end latency
2. **High accuracy** - >95% detection recall
3. **Low false positives** - <1 per 10 minutes
4. **Privacy-first** - all processing on-device
5. **User trust** - clear disclaimers, reliable alerts

Rozpoczynamy od Phase 1 (Foundation) i iteracyjnie budujemy kolejne funkcje. Priorytetem jest bezpieczeństwo i niezawodność.

---

## Next Steps

1. **Setup development environment** (React Native / Flutter)
2. **Choose AI framework** (TFLite vs CoreML vs MediaPipe)
3. **Prepare training data** (vehicle detection dataset)
4. **Train/convert MobileNet SSD model**
5. **Build camera integration prototype**
6. **Run first inference test**

**Let's build it!** 🚗💨
