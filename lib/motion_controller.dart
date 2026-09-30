import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'motion_source.dart';

class MotionController extends ChangeNotifier {
  MotionController({required this.preferences, MotionSource? source})
    : source = source ?? DeviceMotionSource() {
    goal = (preferences.getInt('goal') ?? 100).clamp(20, 10000);
    stepLength = (preferences.getDouble('stepLength') ?? 0.7).clamp(0.3, 1.2);
    for (final raw in preferences.getStringList('sessions') ?? <String>[]) {
      try {
        history.add(
          SessionRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        storageMessage = 'Một bản ghi cũ không đọc được đã được bỏ qua.';
      }
    }
    _subscription = this.source.events.listen(_onEvent);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_suspended) notifyListeners();
    });
  }

  final SharedPreferences preferences;
  final MotionSource source;
  late final StreamSubscription<MotionEvent> _subscription;
  late final Timer _ticker;
  final Map<SensorKind, Vector3> readings = {};
  final Map<SensorKind, List<Vector3>> traces = {
    for (final kind in SensorKind.values) kind: [],
  };
  final Map<String, String> issues = {};
  final Map<SensorKind, DateTime> sensorTimes = {};
  final List<SessionRecord> history = [];
  final Stopwatch _watch = Stopwatch();
  SessionCounter counter = SessionCounter();
  bool simulated = false;
  bool connecting = false;
  bool needsPermission = false;
  bool _suspended = false;
  bool _disposed = false;
  int _connectVersion = 0;
  int? systemSteps;
  DateTime? lastStepTime;
  DateTime? started;
  String walkingStatus = 'Chưa xác định';
  String simulationActivity = 'walking';
  String notice = '';
  String storageMessage = '';
  String gesture = 'Chưa phát hiện thao tác';
  DateTime? gestureTime;
  int shakes = 0;
  int rotations = 0;
  DateTime? _lastShake;
  DateTime? _lastRotation;
  bool _stepInterrupted = false;
  late int goal;
  late double stepLength;
  bool get hasSession => started != null;
  bool get running => counter.running;
  int get seconds => _watch.elapsed.inSeconds;
  int? get sessionSteps => counter.hasReading ? counter.steps : null;
  double? get kilometers =>
      sessionSteps == null ? null : sessionSteps! * stepLength / 1000;
  double get progress => ((sessionSteps ?? 0) / goal).clamp(0, 1);
  int? get cadence => sessionSteps == null || seconds < 5
      ? null
      : (sessionSteps! * 60 / seconds).round();

  Future<void> connect({bool requestPermission = false}) async {
    if (_disposed || _suspended || connecting) return;
    final version = ++_connectVersion;
    connecting = true;
    issues.clear();
    needsPermission = false;
    systemSteps = null;
    lastStepTime = null;
    walkingStatus = 'Chưa xác định';
    readings.clear();
    sensorTimes.clear();
    for (final trace in traces.values) {
      trace.clear();
    }
    notifyListeners();
    try {
      await source.start(
        simulated: simulated,
        requestPermission: requestPermission,
      );
    } catch (_) {
      if (!_disposed && version == _connectVersion) {
        issues['steps'] =
            'Không kết nối được cảm biến. Hãy thử lại hoặc dùng mô phỏng.';
      }
    } finally {
      if (!_disposed && version == _connectVersion) {
        connecting = false;
        notifyListeners();
      }
    }
  }

  void _onEvent(MotionEvent event) {
    if (_disposed || _suspended) return;
    switch (event) {
      case SensorReading():
        readings[event.kind] = event.value;
        sensorTimes[event.kind] = DateTime.now();
        issues.remove(event.kind.name);
        final trace = traces[event.kind]!;
        trace.add(event.value);
        if (trace.length > 120) trace.removeAt(0);
        _detectGesture(event);
      case StepReading():
        final firstReading = counter.awaitingBaseline;
        systemSteps = event.steps;
        lastStepTime = event.time;
        issues.remove('steps');
        needsPermission = false;
        if (counter.accept(event.steps)) {
          notice =
              'Bộ đếm hệ thống vừa đặt lại. Giữ số bước đã ghi và lấy mốc mới.';
        } else if (running && firstReading) {
          notice = 'Đã nhận mốc bước. Hãy bắt đầu đi bộ; bộ đếm có thể cập nhật theo đợt.';
        }
      case WalkingReading():
        walkingStatus = switch (event.status) {
          'walking' => 'Đang đi bộ',
          'stopped' => 'Đã dừng',
          _ => 'Chưa xác định',
        };
        issues.remove('status');
      case SourceIssue():
        issues[event.channel] = event.message;
        if (event.channel == 'steps') {
          needsPermission = event.permission;
          if (hasSession) _stepInterrupted = true;
        }
        if (event.channel == 'status') walkingStatus = 'Không khả dụng';
    }
  }

  void _detectGesture(SensorReading event) {
    final now = DateTime.now();
    if (event.kind == SensorKind.userAcceleration &&
        event.value.magnitude > 12 &&
        (_lastShake == null ||
            now.difference(_lastShake!).inMilliseconds > 1000)) {
      _lastShake = now;
      shakes++;
      gesture = 'Phát hiện lắc máy';
      gestureTime = now;
    }
    if (event.kind == SensorKind.gyroscope &&
        event.value.magnitude > 2.5 &&
        (_lastRotation == null ||
            now.difference(_lastRotation!).inMilliseconds > 1500)) {
      _lastRotation = now;
      rotations++;
      gesture = 'Phát hiện xoay máy';
      gestureTime = now;
    }
  }

  void setActivity(String activity) {
    simulationActivity = activity;
    source.setSimulation(activity);
    notifyListeners();
  }

  Future<void> setSimulated(bool value) async {
    if (hasSession || connecting || value == simulated) return;
    simulated = value;
    shakes = rotations = 0;
    gesture = 'Chưa phát hiện thao tác';
    gestureTime = _lastShake = _lastRotation = null;
    notice = '';
    counter = SessionCounter();
    await connect();
  }

  void startSession() {
    if (hasSession || connecting || _suspended) return;
    started = DateTime.now();
    counter = SessionCounter()..startSegment();
    _stepInterrupted = issues.containsKey('steps');
    _watch
      ..reset()
      ..start();
    notice = 'Chờ sự kiện đầu tiên để lấy mốc; các bước trước mốc này không được tính.';
    notifyListeners();
  }

  void pauseSession({bool automatic = false}) {
    if (!running) return;
    counter.pause();
    _watch.stop();
    notice = automatic
        ? 'Phiên tự tạm dừng khi ứng dụng vào nền. Nhấn Tiếp tục khi quay lại.'
        : 'Đã tạm dừng. Khi tiếp tục, sự kiện đầu tiên sẽ là mốc mới.';
    notifyListeners();
  }

  void resumeSession() {
    if (!hasSession || running || connecting || _suspended) return;
    counter.startSegment();
    _watch.start();
    notice = 'Đang chờ mốc mới; bỏ qua bước trong thời gian tạm dừng.';
    notifyListeners();
  }

  Future<void> finishSession() async {
    if (!hasSession) return;
    pauseSession();
    history.insert(
      0,
      SessionRecord(
        started: started!,
        seconds: seconds,
        steps: sessionSteps,
        simulated: simulated,
        stepLength: stepLength,
        goal: goal,
        note: [
          if (_stepInterrupted) 'Dữ liệu bước có lúc không khả dụng.',
          if (counter.resets > 0)
            'Bộ đếm hệ thống đặt lại ${counter.resets} lần.',
          if (!counter.hasReading) 'Chưa nhận được dữ liệu bước.',
        ].join(' '),
      ),
    );
    if (history.length > 50) history.removeRange(50, history.length);
    started = null;
    counter = SessionCounter();
    _watch.reset();
    notice = 'Đã kết thúc phiên. Xem kết quả trong Lịch sử.';
    await _persist();
    if (!_disposed) notifyListeners();
  }

  Future<void> updateSettings(int newGoal, double newStepLength) async {
    if (hasSession) return;
    goal = newGoal.clamp(20, 10000);
    stepLength = newStepLength.clamp(0.3, 1.2);
    await _persist();
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final results = await Future.wait([
        preferences.setInt('goal', goal),
        preferences.setDouble('stepLength', stepLength),
        preferences.setStringList(
          'sessions',
          history.map((e) => jsonEncode(e.toJson())).toList(),
        ),
      ]);
      storageMessage = results.every((saved) => saved)
          ? ''
          : 'Chưa lưu được dữ liệu vào thiết bị.';
    } catch (_) {
      storageMessage = 'Chưa lưu được dữ liệu. Kết quả hiện chỉ còn trong phiên mở ứng dụng này.';
    }
  }

  Future<void> suspend() async {
    if (_disposed || _suspended) return;
    pauseSession(automatic: true);
    _suspended = true;
    ++_connectVersion;
    connecting = false;
    await source.stop();
  }

  Future<void> wake() async {
    if (_disposed || !_suspended) return;
    _suspended = false;
    await connect();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.cancel();
    _watch.stop();
    unawaited(_subscription.cancel());
    unawaited(source.dispose());
    super.dispose();
  }
}
