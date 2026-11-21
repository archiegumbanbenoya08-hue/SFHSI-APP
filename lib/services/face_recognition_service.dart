import 'dart:collection';

/// Lightweight face-recognition event service used by Parent/Admin pages.
///
/// - Call `FaceRecognitionService.instance.processEvent(...)` when your
///   face-recognition system detects a student entry/exit.
/// - Pages can register listeners with `register(listener)` to receive
///   `FaceEvent` updates.
///
/// This file adds only logic (no UI changes) and provides the function the
/// app can call to update parent/admin state.

class FaceEvent {
  final String studentId;
  final String studentName;
  final String grade;
  final String status; // 'Inside Campus' | 'Outside Campus'
  final DateTime timestamp;
  final List<String> parentEmails;

  FaceEvent({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.status,
    required this.timestamp,
    required this.parentEmails,
  });
}

typedef FaceEventListener = void Function(FaceEvent event);

class FaceRecognitionService {
  FaceRecognitionService._internal();
  static final FaceRecognitionService instance = FaceRecognitionService._internal();

  final List<FaceEventListener> _listeners = [];
  final List<FaceEvent> _history = [];

  /// Register a listener to receive events.
  void register(FaceEventListener listener) {
    _listeners.add(listener);
  }

  /// Unregister a previously-registered listener.
  void unregister(FaceEventListener listener) {
    _listeners.remove(listener);
  }

  /// Process an incoming face-recognition event.
  ///
  /// This is the primary function you asked for: call it from your
  /// recognition flow; it updates internal history and notifies listeners
  /// (Parent/Admin pages will update themselves when they receive the event).
  void processEvent(FaceEvent event) {
    _history.add(event);

    // notify listeners
    for (final l in List<FaceEventListener>.from(_listeners)) {
      try {
        l(event);
      } catch (_) {
        // swallow listener errors — pages should guard themselves
      }
    }
  }

  /// Returns read-only history of processed events.
  UnmodifiableListView<FaceEvent> get history => UnmodifiableListView(_history);

}
