import 'package:flutter_test/flutter_test.dart';
import 'package:nhom05_demo/models.dart';

void main() {
  test('first event is a baseline, not session steps', () {
    final c = SessionCounter()..startSegment();
    expect(c.hasReading, isFalse);
    c.accept(1250);
    c.accept(1280);
    expect(c.steps, 30);
  });
  test(
    'pause excludes intervening steps and resume takes a fresh baseline',
    () {
      final c = SessionCounter()..startSegment();
      c.accept(100);
      c.accept(120);
      c.pause();
      c.accept(150);
      c.startSegment();
      c.accept(180);
      c.accept(185);
      expect(c.steps, 25);
    },
  );
  test('detects reset below previous event even above original baseline', () {
    final c = SessionCounter()..startSegment();
    c.accept(100);
    c.accept(150);
    expect(c.accept(120), isTrue);
    c.accept(130);
    expect(c.steps, 60);
    expect(c.resets, 1);
  });
  test('duplicates and negative counts do not create extra steps', () {
    final c = SessionCounter()..startSegment();
    c.accept(10);
    c.accept(10);
    c.accept(-1);
    c.accept(15);
    expect(c.steps, 5);
  });
  test('record round trip preserves missing measurement and source', () {
    final record = SessionRecord(
      started: DateTime(2026, 9, 29),
      seconds: 12,
      steps: null,
      simulated: true,
      stepLength: .7,
      goal: 100,
      note: 'Chưa có dữ liệu',
    );
    final restored = SessionRecord.fromJson(record.toJson());
    expect(restored.steps, isNull);
    expect(restored.kilometers, isNull);
    expect(restored.simulated, isTrue);
    expect(restored.note, record.note);
  });
}
