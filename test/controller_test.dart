import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhom05_demo/models.dart';
import 'package:nhom05_demo/motion_controller.dart';
import 'package:nhom05_demo/motion_source.dart';

import 'fake_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MotionController c;
  late FakeSource source;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    source = FakeSource();
    c = MotionController(
      preferences: await SharedPreferences.getInstance(),
      source: source,
    );
    await c.connect();
  });
  tearDown(() => c.dispose());
  test('permission failure preserves missing steps but sensors still work', () {
    source.emit(SourceIssue('steps', 'Thiếu quyền', permission: true));
    source.emit(
      SensorReading(SensorKind.acceleration, const Vector3(0, 0, 9.81)),
    );
    c.startSession();
    expect(c.sessionSteps, isNull);
    expect(c.needsPermission, isTrue);
    expect(c.readings[SensorKind.acceleration]!.magnitude, closeTo(9.81, .01));
  });
  test('status failure does not disable step stream', () {
    c.startSession();
    source.emit(SourceIssue('status', 'Không khả dụng'));
    source.emit(StepReading(100, DateTime.now()));
    source.emit(StepReading(130, DateTime.now()));
    expect(c.sessionSteps, 30);
    expect(c.walkingStatus, 'Không khả dụng');
  });
  test(
    'lifecycle pauses and requires explicit resume with new baseline',
    () async {
      c.startSession();
      source.emit(StepReading(100, DateTime.now()));
      source.emit(StepReading(110, DateTime.now()));
      await c.suspend();
      source.emit(StepReading(150, DateTime.now()));
      expect(c.running, isFalse);
      expect(source.stops, 1);
      await c.wake();
      expect(c.running, isFalse);
      c.resumeSession();
      source.emit(StepReading(200, DateTime.now()));
      source.emit(StepReading(205, DateTime.now()));
      expect(c.sessionSteps, 15);
    },
  );
  test('saved simulation and settings survive controller restart', () async {
    await c.updateSettings(30, .8);
    await c.setSimulated(true);
    c.startSession();
    source.emit(StepReading(1000, DateTime.now()));
    source.emit(StepReading(1030, DateTime.now()));
    await c.finishSession();
    final restored = MotionController(
      preferences: c.preferences,
      source: FakeSource(),
    );
    expect(restored.history.single.steps, 30);
    expect(restored.history.single.simulated, isTrue);
    expect(restored.history.single.kilometers, closeTo(.024, .0001));
    expect(restored.goal, 30);
    expect(c.hasSession, isFalse);
    restored.dispose();
  });
  test('source and settings cannot change during session', () async {
    c.startSession();
    await c.setSimulated(true);
    await c.updateSettings(500, 1);
    expect(c.simulated, isFalse);
    expect(c.goal, 100);
  });
  test('gesture cooldown suppresses duplicates and never adds steps', () {
    c.startSession();
    for (var i = 0; i < 10; i++) {
      source.emit(
        SensorReading(SensorKind.userAcceleration, const Vector3(15, 0, 0)),
      );
      source.emit(SensorReading(SensorKind.gyroscope, const Vector3(0, 3, 0)));
    }
    expect(c.shakes, 1);
    expect(c.rotations, 1);
    expect(c.sessionSteps, isNull);
  });
  test('missing measurements saved as null rather than zero', () async {
    c.startSession();
    await c.finishSession();
    expect(c.history.single.steps, isNull);
    expect(c.history.single.note, contains('Chưa nhận'));
  });
  test('trace is bounded to 120 samples', () {
    for (var i = 0; i < 200; i++) {
      source.emit(
        SensorReading(SensorKind.acceleration, Vector3(i.toDouble(), 0, 0)),
      );
    }
    expect(c.traces[SensorKind.acceleration]!.length, 120);
    expect(c.traces[SensorKind.acceleration]!.first.x, 80);
  });
}
