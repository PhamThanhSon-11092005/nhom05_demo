import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhom05_demo/main.dart';
import 'package:nhom05_demo/motion_controller.dart';
import 'package:nhom05_demo/motion_source.dart';

import 'fake_source.dart';

void main() {
  testWidgets('simulation session saves and all tabs fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final source = FakeSource();
    final c = MotionController(
      preferences: await SharedPreferences.getInstance(),
      source: source,
    );
    await tester.pumpWidget(MotionLabApp(controller: c));
    await tester.pump();
    expect(find.text('MOTION LAB'), findsOneWidget);
    await tester.tap(find.text('Mô phỏng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.simulated, isTrue);
    final start = find.byKey(const Key('start-session'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    source.emit(StepReading(1000, DateTime.now()));
    source.emit(StepReading(1030, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.sessionSteps, 30);
    await tester.ensureVisible(find.text('Kết thúc'));
    await tester.tap(find.text('Kết thúc'));
    await tester.pump();
    await tester.tap(find.text('Lịch sử'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('0.021'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cảm biến'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Nhìn thấy chuyển động.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Kiến thức'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('MEMS là gì?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('timer simulation generates steps and respects pause', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final c = MotionController(
      preferences: await SharedPreferences.getInstance(),
    );
    await c.setSimulated(true);
    c.startSession();
    await tester.pump(const Duration(seconds: 3));
    expect(c.sessionSteps, greaterThanOrEqualTo(4));
    c.pauseSession();
    final count = c.sessionSteps;
    await tester.pump(const Duration(seconds: 2));
    expect(c.sessionSteps, count);
    c.dispose();
    await tester.pump();
  });
}
