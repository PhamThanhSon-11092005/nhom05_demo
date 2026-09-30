import 'dart:math' as math;

enum SensorKind {
  acceleration(
    'Gia tốc kế',
    'm/s²',
    'Bao gồm trọng lực. Độ lớn khi để yên thường gần 9,81 m/s².',
  ),
  userAcceleration(
    'Gia tốc tuyến tính',
    'm/s²',
    'Đã loại trọng lực. Khi để yên, ba trục thường gần 0.',
  ),
  gyroscope(
    'Con quay hồi chuyển',
    'rad/s',
    'Đo tốc độ xoay quanh ba trục, không phải góc xoay.',
  ),
  magnetometer(
    'Từ kế',
    'µT',
    'Đo từ trường xung quanh. Kim loại và nam châm có thể gây nhiễu.',
  );

  const SensorKind(this.label, this.unit, this.description);
  final String label;
  final String unit;
  final String description;
}

class Vector3 {
  const Vector3(this.x, this.y, this.z);
  final double x, y, z;
  double get magnitude => math.sqrt(x * x + y * y + z * z);
}

/// Counts only deltas within an active segment. A fresh segment waits for
/// its first event, so stale/batched counts from a pause are not added.
class SessionCounter {
  int? _previous;
  int steps = 0;
  bool hasReading = false;
  bool running = false;
  int resets = 0;
  bool get awaitingBaseline => _previous == null;

  void startSegment() {
    _previous = null;
    running = true;
  }

  void pause() {
    running = false;
    _previous = null;
  }

  bool accept(int cumulative) {
    if (!running || cumulative < 0) return false;
    final previous = _previous;
    _previous = cumulative;
    hasReading = true;
    if (previous == null) return false;
    if (cumulative < previous) {
      resets++;
      return true;
    }
    steps += cumulative - previous;
    return false;
  }
}

class SessionRecord {
  const SessionRecord({
    required this.started,
    required this.seconds,
    required this.steps,
    required this.simulated,
    required this.stepLength,
    required this.goal,
    required this.note,
  });
  final DateTime started;
  final int seconds;
  final int? steps;
  final bool simulated;
  final double stepLength;
  final int goal;
  final String note;
  double? get kilometers => steps == null ? null : steps! * stepLength / 1000;
  Map<String, Object?> toJson() => {
    'started': started.toIso8601String(),
    'seconds': seconds,
    'steps': steps,
    'simulated': simulated,
    'stepLength': stepLength,
    'goal': goal,
    'note': note,
  };
  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    started: DateTime.parse(json['started'] as String),
    seconds: json['seconds'] as int,
    steps: json['steps'] as int?,
    simulated: json['simulated'] as bool,
    stepLength: (json['stepLength'] as num).toDouble(),
    goal: json['goal'] as int,
    note: json['note'] as String? ?? '',
  );
}

String durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${timeLabel(date)}';

String timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
