// Optional Windows UI preview: flutter test tool/preview_test.dart
// Uses simulated fixtures, not measurements from a phone.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhom05_demo/main.dart';
import 'package:nhom05_demo/models.dart';
import 'package:nhom05_demo/motion_controller.dart';
import 'package:nhom05_demo/motion_source.dart';

import '../test/fake_source.dart';

void main() {
  testWidgets('render presentation previews', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = File(
        '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/arial.ttf',
      );
      final loader = FontLoader('Roboto')
        ..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    // This file is a Flutter test kept in tool/ for optional preview generation.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final source = FakeSource();
    final c = MotionController(
      preferences: await SharedPreferences.getInstance(),
      source: source,
    );
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MotionLabApp(controller: c),
      ),
    );
    await tester.pump();
    await c.setSimulated(true);
    c.startSession();
    source.emit(StepReading(1000, DateTime.now()));
    source.emit(StepReading(1042, DateTime.now()));
    source.emit(WalkingReading('walking'));
    for (var i = 0; i < 120; i++) {
      source.emit(
        SensorReading(
          SensorKind.userAcceleration,
          Vector3((i % 16 - 8) * .3, (i % 12 - 6) * .2, (i % 20 - 10) * .1),
        ),
      );
    }
    Future<void> capture(String name) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('docs/previews').create(recursive: true);
        await File('docs/previews/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await capture('overview');
    await tester.tap(find.text('Cảm biến'));
    await capture('sensors');
    await c.finishSession();
    await tester.tap(find.text('Lịch sử'));
    await capture('history');
    await tester.tap(find.text('Kiến thức'));
    await capture('learn');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
