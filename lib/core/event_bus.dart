import 'dart:async';

enum EventType {
  frameCaptured,
  detectionMade,
  collisionRisk,
  vehicleApproaching,
  suddenBraking,
  laneDeparture,
  routeUpdated,
  alertTriggered,
  gpsUpdated,
  imuUpdated,
}

class Event {
  final EventType type;
  final dynamic payload;
  final DateTime timestamp;

  Event({
    required this.type,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _controller = StreamController<Event>.broadcast();

  Stream<Event> get stream => _controller.stream;

  void emit(Event event) {
    _controller.add(event);
  }

  void emitType(EventType type, [dynamic payload]) {
    emit(Event(type: type, payload: payload));
  }

  Stream<Event> on(EventType type) {
    return stream.where((event) => event.type == type);
  }

  void dispose() {
    _controller.close();
  }
}
