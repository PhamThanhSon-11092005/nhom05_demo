import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'models.dart';

sealed class MotionEvent {}

class SensorReading extends MotionEvent {
  SensorReading(this.kind, this.value);
  final SensorKind kind;
  final Vector3 value;
}

class StepReading extends MotionEvent {
  StepReading(this.steps, this.time);
  final int steps;
  final DateTime time;
}

class WalkingReading extends MotionEvent {
  WalkingReading(this.status);
  final String status;
}

class SourceIssue extends MotionEvent {
  SourceIssue(this.channel, this.message, {this.permission = false});
  final String channel, message;
  final bool permission;
}

abstract class MotionSource {
  Stream<MotionEvent> get events;
  Future<void> start({required bool simulated, bool requestPermission = false});
  Future<void> stop();
  void setSimulation(String activity);
  Future<void> dispose();
}

class DeviceMotionSource implements MotionSource {
  final _events = StreamController<MotionEvent>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _simulation;
  int _generation = 0;
  String _activity = 'walking';
  @override
  Stream<MotionEvent> get events => _events.stream;

  @override
  void setSimulation(String activity) => _activity = activity;

  void _listen<T>(
    Stream<T> Function() stream,
    MotionEvent Function(T) convert,
    String channel,
    String errorMessage,
    int generation,
  ) {
    try {
      _subscriptions.add(
        stream().listen(
          (value) {
            if (generation == _generation) _events.add(convert(value));
          },
          onError: (Object error) {
            if (generation == _generation) {
              _events.add(SourceIssue(channel, errorMessage));
            }
          },
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (generation == _generation) {
        _events.add(SourceIssue(channel, errorMessage));
      }
    }
  }

  @override
  Future<void> start({
    required bool simulated,
    bool requestPermission = false,
  }) async {
    final expectedGeneration = _generation + 1;
    await stop();
    if (_generation != expectedGeneration) return;
    final generation = _generation;
    if (simulated) {
      var tick = 0;
      var cumulative = 1000;
      _events.add(StepReading(cumulative, DateTime.now()));
      _simulation = Timer.periodic(const Duration(milliseconds: 50), (_) {
        tick++;
        final t = tick / 20;
        final walking = _activity == 'walking';
        final shaking = _activity == 'shake';
        final rotating = _activity == 'rotate';
        final wave = math.sin(t * 4 * math.pi);
        final amplitude = walking ? 2.8 : (shaking ? 15.0 : 0.03);
        final x = amplitude * wave;
        final y = amplitude * 0.3 * math.cos(t * 4 * math.pi);
        final z = amplitude * 0.5 * wave;
        _events.add(
          SensorReading(SensorKind.acceleration, Vector3(x, y, 9.81 + z)),
        );
        _events.add(
          SensorReading(SensorKind.userAcceleration, Vector3(x, y, z)),
        );
        _events.add(
          SensorReading(
            SensorKind.gyroscope,
            Vector3(0.02, rotating ? 3.5 * math.sin(t * 2) : 0.02, 0.01),
          ),
        );
        _events.add(
          SensorReading(
            SensorKind.magnetometer,
            Vector3(22 + (rotating ? 12 * math.sin(t) : 0), 6, -38),
          ),
        );
        if (tick % 10 == 0) {
          if (walking) cumulative++;
          _events.add(StepReading(cumulative, DateTime.now()));
          _events.add(WalkingReading(walking ? 'walking' : 'stopped'));
        }
      });
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _events.add(
        SourceIssue(
          'steps',
          'Bản demo đo thật dành cho Android. Hãy dùng mô phỏng trên thiết bị này.',
        ),
      );
      return;
    }
    const period = Duration(milliseconds: 50);
    _listen(
      () => accelerometerEventStream(samplingPeriod: period),
      (e) => SensorReading(SensorKind.acceleration, Vector3(e.x, e.y, e.z)),
      SensorKind.acceleration.name,
      'Không có dữ liệu gia tốc kế.',
      generation,
    );
    _listen(
      () => userAccelerometerEventStream(samplingPeriod: period),
      (e) => SensorReading(SensorKind.userAcceleration, Vector3(e.x, e.y, e.z)),
      SensorKind.userAcceleration.name,
      'Gia tốc tuyến tính không khả dụng.',
      generation,
    );
    _listen(
      () => gyroscopeEventStream(samplingPeriod: period),
      (e) => SensorReading(SensorKind.gyroscope, Vector3(e.x, e.y, e.z)),
      SensorKind.gyroscope.name,
      'Con quay hồi chuyển không khả dụng.',
      generation,
    );
    _listen(
      () => magnetometerEventStream(samplingPeriod: period),
      (e) => SensorReading(SensorKind.magnetometer, Vector3(e.x, e.y, e.z)),
      SensorKind.magnetometer.name,
      'Từ kế không khả dụng.',
      generation,
    );
    try {
      final permission = requestPermission
          ? await Permission.activityRecognition.request()
          : await Permission.activityRecognition.status;
      if (generation != _generation) return;
      if (!permission.isGranted) {
        _events.add(
          SourceIssue(
            'steps',
            permission.isPermanentlyDenied
                ? 'Quyền vận động bị chặn. Mở Cài đặt → Quyền → Hoạt động thể chất.'
                : 'Cấp quyền hoạt động thể chất để đọc số bước chân.',
            permission: true,
          ),
        );
        return;
      }
      _listen(
        () => Pedometer.stepCountStream,
        (e) => StepReading(e.steps, e.timeStamp),
        'steps',
        'Không đọc được bộ đếm bước. Thiết bị có thể không hỗ trợ cảm biến này.',
        generation,
      );
      _listen(
        () => Pedometer.pedestrianStatusStream,
        (e) => WalkingReading(e.status),
        'status',
        'Trạng thái đi bộ không khả dụng trên thiết bị này.',
        generation,
      );
    } catch (_) {
      if (generation == _generation) {
        _events.add(
          SourceIssue(
            'steps',
            'Không truy cập được quyền vận động. Thử kết nối lại.',
            permission: true,
          ),
        );
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    _simulation?.cancel();
    _simulation = null;
    final old = List<StreamSubscription<dynamic>>.of(_subscriptions);
    _subscriptions.clear();
    await Future.wait(old.map((subscription) => subscription.cancel()));
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
