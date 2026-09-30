import 'dart:async';

import 'package:nhom05_demo/motion_source.dart';

class FakeSource implements MotionSource {
  final controller = StreamController<MotionEvent>.broadcast(sync: true);
  int starts = 0;
  int stops = 0;
  @override
  Stream<MotionEvent> get events => controller.stream;
  void emit(MotionEvent event) => controller.add(event);
  @override
  Future<void> start({
    required bool simulated,
    bool requestPermission = false,
  }) async {
    starts++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  void setSimulation(String activity) {}
  @override
  Future<void> dispose() async {
    await controller.close();
  }
}
