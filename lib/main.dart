import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'motion_controller.dart';
import 'ui_components.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    runApp(MotionLabApp(controller: MotionController(preferences: preferences)));
  }, (error, stack) {
    if (error is PlatformException && error.message != null && error.message!.contains('StepDetection')) {
      debugPrint('Ignored Pedometer plugin error: $error');
    } else {
      debugPrint('Unhandled error: $error\n$stack');
    }
  });
}

class MotionLabApp extends StatelessWidget {
  const MotionLabApp({super.key, required this.controller});
  final MotionController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Motion Lab · Nhóm 05',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        surface: paper,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: mint.withValues(alpha: .55),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    home: MotionHome(controller: controller),
  );
}

class MotionHome extends StatefulWidget {
  const MotionHome({super.key, required this.controller});
  final MotionController controller;
  @override
  State<MotionHome> createState() => _MotionHomeState();
}

class _MotionHomeState extends State<MotionHome> with WidgetsBindingObserver {
  int _page = 0;
  SensorKind _sensor = SensorKind.userAcceleration;
  String _historyFilter = 'all';
  MotionController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(c.connect());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(c.suspend());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(c.wake());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    key: PageStorageKey(_page),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.simulated)
                          const InfoStrip(
                            'CHẾ ĐỘ MÔ PHỎNG.',
                            warning: true,
                          ),
                        if (c.storageMessage.isNotEmpty)
                          InfoStrip(c.storageMessage, warning: true),
                        ...switch (_page) {
                          0 => _overview(),
                          1 => _sensors(),
                          _ => _learn(),
                        },
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (value) => setState(() => _page = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(icon: Icon(Icons.sensors), label: 'Cảm biến'),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            label: 'Kiến thức',
          ),
        ],
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.graphic_eq_rounded, color: mint, size: 29),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOTION LAB',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                'NHÓM 05  /  CẢM BIẾN CHUYỂN ĐỘNG',
                style: TextStyle(fontSize: 9, color: muted, letterSpacing: .7),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _settings,
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Cài đặt phiên đo',
        ),
      ],
    ),
  );

  List<Widget> _overview() => [
    const SectionHeading(
      'Mỗi bước, một chuyển động.',
      'Quan sát cảm biến. Khám phá cách điện thoại hiểu bước chân.',
    ),
    _sourceSelector(),
    const SizedBox(height: 18),
    Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ink, Color(0xFF21494D)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PHIÊN VẬN ĐỘNG',
                  style: TextStyle(
                    color: Color(0xFFB4C8C6),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Badge(
                c.running
                    ? 'Đang ghi'
                    : (c.hasSession ? 'Tạm dừng' : 'Sẵn sàng'),
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ProgressDial(
            progress: c.progress,
            value: c.sessionSteps?.toString() ?? '—',
            label: 'bước trong phiên',
          ),
          Text(
            'Mục tiêu ${c.goal} bước  ·  ${(c.progress * 100).round()}%',
            style: const TextStyle(
              color: mint,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (c.progress >= 1)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Đã hoàn thành mục tiêu phiên!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF426065), height: 1),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Metric(
                  Icons.timer_outlined,
                  durationLabel(c.seconds),
                  'Thời gian ghi',
                  dark: true,
                ),
              ),
              Expanded(
                child: Metric(
                  Icons.route_rounded,
                  c.kilometers?.toStringAsFixed(3) ?? '—',
                  'km ước tính',
                  dark: true,
                ),
              ),
              Expanded(
                child: Metric(
                  Icons.speed_rounded,
                  c.cadence?.toString() ?? '—',
                  'bước/phút TB',
                  dark: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    if (!c.hasSession)
      FilledButton.icon(
        key: const Key('start-session'),
        onPressed: c.connecting ? null : c.startSession,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Bắt đầu phiên'),
      )
    else
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: c.connecting
                  ? null
                  : (c.running ? () => c.pauseSession() : c.resumeSession),
              icon: Icon(
                c.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(c.running ? 'Tạm dừng' : 'Tiếp tục'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: c.finishSession,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Kết thúc'),
            ),
          ),
        ],
      ),
    if (c.notice.isNotEmpty) InfoStrip(c.notice),
    if (c.simulated) ...[const SizedBox(height: 16), _simulationControls()],
    if (c.issues['steps'] != null) ...[
      InfoStrip(c.issues['steps']!, warning: true),
      Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: c.connecting
                ? null
                : () => _reconnect(requestPermission: true),
            icon: const Icon(Icons.refresh),
            label: Text(
              c.needsPermission ? 'Cấp quyền / thử lại' : 'Kết nối lại',
            ),
          ),
          if (c.needsPermission)
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: const Text('Mở Cài đặt'),
            ),
        ],
      ),
    ],
    const SectionHeading(
      'Điện thoại đang ghi nhận gì?',
      'Hai luồng độc lập từ pedometer.',
    ),
    Panel(
      child: Column(
        children: [
          _detailRow(
            Icons.directions_walk_rounded,
            'Trạng thái',
            c.walkingStatus,
          ),
          const Divider(height: 28),
          _detailRow(
            Icons.memory_rounded,
            'Bộ đếm hệ thống',
            c.systemSteps?.toString() ?? 'Chưa có dữ liệu',
          ),
          const SizedBox(height: 15),
          _detailRow(
            Icons.update_rounded,
            'Cập nhật bước',
            c.lastStepTime == null ? 'Đang chờ' : timeLabel(c.lastStepTime!),
          ),
          if (c.issues['status'] != null) InfoStrip(c.issues['status']!),
        ],
      ),
    ),
    const InfoStrip(
      'Bước hệ thống không phải tổng bước hôm nay. Số bước phiên được cộng từ các lần cập nhật sau mốc bắt đầu. Quãng đường = số bước × độ dài bước đã đặt.',
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () => setState(() => _page = 1),
      icon: const Icon(Icons.show_chart),
      label: const Text('Khám phá dữ liệu cảm biến'),
    ),
    const SizedBox(height: 32),
    ..._history(),
  ];

  Widget _sourceSelector() => Panel(
    padding: 14,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'NGUỒN DỮ LIỆU',
          style: TextStyle(
            fontSize: 10,
            color: muted,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Thiết bị thật'),
              icon: Icon(Icons.phone_android_rounded),
            ),
            ButtonSegment(
              value: true,
              label: Text('Mô phỏng'),
              icon: Icon(Icons.science_outlined),
            ),
          ],
          selected: {c.simulated},
          onSelectionChanged: c.hasSession || c.connecting
              ? null
              : (value) => c.setSimulated(value.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        if (c.hasSession)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Kết thúc phiên để đổi nguồn dữ liệu.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
        if (c.connecting)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
      ],
    ),
  );

  Widget _simulationControls() => Panel(
    color: const Color(0xFFFFF8ED),
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bàn điều khiển mô phỏng',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final entry in {
              'walking': 'Đi bộ',
              'stopped': 'Đứng yên',
              'shake': 'Lắc máy',
              'rotate': 'Xoay máy',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: c.simulationActivity == entry.key,
                onSelected: (_) => c.setActivity(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Đi bộ tạo 2 bước/giây. Lắc và xoay chỉ minh họa tín hiệu, không cộng bước mô phỏng.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: teal, size: 21),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label, style: const TextStyle(color: muted, fontSize: 13)),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    ],
  );

  List<Widget> _sensors() {
    final value = c.readings[_sensor];
    final timestamp = c.sensorTimes[_sensor];
    final fresh =
        timestamp != null && DateTime.now().difference(timestamp).inSeconds < 3;
    return [
      const SectionHeading(
        'Nhìn thấy chuyển động.',
        'Dữ liệu ba trục từ sensors_plus, cập nhật liên tục.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final kind in SensorKind.values)
            ChoiceChip(
              label: Text(kind.label),
              selected: _sensor == kind,
              onSelected: (_) => setState(() => _sensor = kind),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _sensor.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Badge(
                  fresh
                      ? (c.simulated ? 'Mô phỏng' : 'Trực tiếp')
                      : 'Chờ tín hiệu',
                  warning: !fresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _sensor.description,
              style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 22),
            SensorChart(values: c.traces[_sensor]!, unit: _sensor.unit),
            const SizedBox(height: 22),
            Row(
              children: [
                for (var axis = 0; axis < 3; axis++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          ['X', 'Y', 'Z'][axis],
                          style: TextStyle(
                            color: axisColors[axis],
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value == null
                              ? '—'
                              : [
                                  value.x,
                                  value.y,
                                  value.z,
                                ][axis].toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _sensor.unit,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 30),
            _detailRow(
              Icons.functions,
              'Độ lớn √(x² + y² + z²)',
              value == null
                  ? '—'
                  : '${value.magnitude.toStringAsFixed(2)} ${_sensor.unit}',
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Mẫu cuối: ${timeLabel(timestamp)}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            if (c.issues[_sensor.name] != null)
              InfoStrip(c.issues[_sensor.name]!, warning: true),
            if (!fresh && value != null)
              const InfoStrip(
                'Chưa nhận mẫu mới. Các giá trị đang hiển thị là mẫu cuối cùng.',
                warning: true,
              ),
          ],
        ),
      ),
      if (c.simulated) ...[const SizedBox(height: 16), _simulationControls()],
      const SectionHeading(
        'Thử lắc hoặc xoay máy',
        'Minh họa nhận diện thao tác bằng ngưỡng.',
      ),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Metric(
                    Icons.vibration_rounded,
                    '${c.shakes}',
                    'Lần phát hiện lắc',
                  ),
                ),
                Expanded(
                  child: Metric(
                    Icons.screen_rotation_alt_rounded,
                    '${c.rotations}',
                    'Lần phát hiện xoay',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Badge(c.gesture, icon: Icons.bolt_rounded),
            if (c.gestureTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Lần cuối: ${timeLabel(c.gestureTime!)}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
            const InfoStrip(
              'Lắc: |a tuyến tính| > 12 m/s², cách lần trước > 1 giây. Xoay: |ω| > 2,5 rad/s, cách lần trước > 1,5 giây. Thao tác kéo dài có thể được nhận nhiều lần. Đây là ngưỡng minh họa, không phải thuật toán đếm bước của pedometer.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TextButton.icon(
        onPressed: c.connecting ? null : _reconnect,
        icon: const Icon(Icons.refresh),
        label: const Text('Kết nối lại cảm biến'),
      ),
    ];
  }

  List<SessionRecord> get _filteredHistory => c.history
      .where(
        (record) =>
            _historyFilter == 'all' ||
            (_historyFilter == 'simulation'
                ? record.simulated
                : !record.simulated),
      )
      .toList();

  List<Widget> _history() {
    final records = _filteredHistory;
    return [
      const SectionHeading(
        'Lịch sử phiên đo',
        'Các phiên gần nhất được lưu tự động sau khi kết thúc.',
      ),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'all', label: Text('Tất cả')),
          ButtonSegment(value: 'real', label: Text('Đo thật')),
          ButtonSegment(value: 'simulation', label: Text('Mô phỏng')),
        ],
        selected: {_historyFilter},
        onSelectionChanged: (v) => setState(() => _historyFilter = v.first),
      ),
      const SizedBox(height: 18),
      if (records.isEmpty)
        Panel(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.route_rounded, size: 56, color: teal),
              const SizedBox(height: 18),
              const Text(
                'Chưa có phiên nào ở đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bắt đầu một phiên và nhấn Kết thúc\nđể lưu kết quả vào lịch sử.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.6),
              ),
              const SizedBox(height: 12),
            ],
          ),
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: Text(
                '${records.length} phiên đã lưu',
                style: const TextStyle(color: muted),
              ),
            ),
            TextButton.icon(
              onPressed: _copyHistory,
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Sao chép CSV'),
            ),
          ],
        ),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        dateLabel(record.started),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Badge(
                        record.simulated ? 'Mô phỏng' : 'Đo thật',
                        warning: record.simulated,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Metric(
                          Icons.directions_walk,
                          record.steps?.toString() ?? '—',
                          'bước',
                        ),
                      ),
                      Expanded(
                        child: Metric(
                          Icons.timer_outlined,
                          durationLabel(record.seconds),
                          'thời gian',
                        ),
                      ),
                      Expanded(
                        child: Metric(
                          Icons.route,
                          record.kilometers?.toStringAsFixed(3) ?? '—',
                          'km ước tính',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ((record.steps ?? 0) / record.goal).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: paper,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mục tiêu ${record.goal} bước · độ dài bước ${record.stepLength.toStringAsFixed(2)} m',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  if (record.note.isNotEmpty)
                    InfoStrip(record.note, warning: true),
                ],
              ),
            ),
          ),
      ],
      const InfoStrip(
        'Lịch sử gồm các phiên đã kết thúc, không phải tổng vận động cả ngày. Phiên đang ghi chưa được lưu nếu ứng dụng bị đóng.',
      ),
    ];
  }

  List<Widget> _learn() => [
    const SectionHeading(
      'Từ chuyển động đến dữ liệu.',
      'Góc giải thích dành cho buổi thuyết trình của nhóm.',
    ),
    Panel(
      color: ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Badge(
            '01  /  BÊN TRONG ĐIỆN THOẠI',
            dark: true,
            icon: Icons.memory,
          ),
          const SizedBox(height: 16),
          const Text(
            'MEMS là gì?',
            style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hệ thống vi cơ điện tử kết hợp cấu trúc cơ học rất nhỏ với mạch điện. Trong mô hình gia tốc kế, khối quán tính dịch chuyển tương đối với khung khi máy tăng tốc.',
            style: TextStyle(color: Color(0xFFCEE0DC), height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vertical_align_center, color: mint),
                Expanded(
                  child: Text(
                    '~ ~ ~',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mint, fontSize: 30),
                  ),
                ),
                Icon(Icons.crop_square_rounded, color: mint, size: 60),
                Expanded(
                  child: Text(
                    '~ ~ ~',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mint, fontSize: 30),
                  ),
                ),
                Icon(Icons.vertical_align_center, color: mint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Khung  ·  Lò xo  ·  Khối quán tính  ·  Lò xo  ·  Khung',
            style: TextStyle(fontSize: 11, color: Color(0xFFB4C8C6)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chuyển động → độ lệch → thay đổi điện dung → tín hiệu điện → dữ liệu số.',
            style: TextStyle(
              color: mint,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
    const SectionHeading(
      'Hai thư viện, hai vai trò',
      'Liên hệ trực tiếp với các màn hình của demo.',
    ),
    _lesson(
      Icons.sensors,
      'sensors_plus',
      'Trả về các luồng dữ liệu cảm biến. Ứng dụng tự tính độ lớn, vẽ đồ thị và kiểm tra ngưỡng lắc/xoay. Trong demo này: 4 loại cảm biến, chu kỳ yêu cầu 50 ms; nhịp thực tế tùy thiết bị.',
    ),
    const SizedBox(height: 12),
    _lesson(
      Icons.directions_walk_rounded,
      'pedometer',
      'Trả về số bước và trạng thái từ nền tảng. Ứng dụng quản lý quyền, mốc phiên, lỗi và lưu kết quả. Không suy ra trạng thái chạy bộ hay đi xe từ hai giá trị walking/stopped.',
    ),
    const SectionHeading(
      'Vì sao điện thoại đếm được bước?',
      'Một cách giải thích nguyên lý nhận diện, không phải mã bên trong pedometer.',
    ),
    Panel(
      child: Column(
        children: [
          _learningStep(
            '1',
            'Thu tín hiệu',
            'Bước chân tạo biến đổi gia tốc gần tuần hoàn.',
          ),
          _learningStep(
            '2',
            'Chuẩn bị và lọc',
            'Xử lý trọng lực và giảm nhiễu trong tín hiệu.',
          ),
          _learningStep(
            '3',
            'Tìm đỉnh',
            'Chọn cực đại vượt ngưỡng, tránh đếm nhiều mẫu của cùng một đỉnh.',
          ),
          _learningStep(
            '4',
            'Kiểm tra thời gian',
            'Loại đỉnh quá sát; bản thực tế còn kiểm tra nhịp lặp lại.',
          ),
          _learningStep(
            '5',
            'Ghi nhận bước',
            'Vẫn cần kiểm chứng: lắc máy có thể tạo đỉnh giống bước chân.',
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    _lesson(
      Icons.calculate_outlined,
      '1.280 − 1.250 = 30 bước',
      '1.250 là mốc ban đầu, 1.280 là bộ đếm hệ thống mới nhất. Phiên ghi 30 bước. Mỗi lần tiếp tục sau tạm dừng sẽ lấy mốc mới ở sự kiện đầu tiên; một số bước đầu đoạn có thể chưa được tính.',
    ),
    const SectionHeading(
      'Kịch bản trình diễn · khoảng 3 phút',
      'Thử mô phỏng trước, sau đó đối chiếu trên Android thật.',
    ),
    Panel(
      child: Column(
        children: [
          _learningStep(
            '1',
            'Để máy yên',
            'So sánh độ lớn gia tốc kế gần 9,81 m/s² với gia tốc tuyến tính gần 0.',
          ),
          _learningStep(
            '2',
            'Lắc và xoay nhẹ',
            'Quan sát X/Y/Z, đồ thị và thông báo nhận diện thao tác.',
          ),
          _learningStep(
            '3',
            'Đi bộ 30 bước',
            'Cấp quyền, bắt đầu phiên, chờ mốc rồi đếm thủ công 30 bước. Chờ dữ liệu cập nhật trước khi kết thúc.',
          ),
          _learningStep(
            '4',
            'Dừng và xem kết quả',
            'Tạm dừng, tiếp tục, kết thúc và mở lịch sử. Ghi sai lệch thực tế để báo cáo.',
          ),
        ],
      ),
    ),
    const InfoStrip(
      'Demo đo trong lúc ứng dụng ở màn hình trước; vào nền sẽ tự tạm dừng. Dữ liệu bước có thể cập nhật theo đợt. Máy có gia tốc kế chưa chắc có bộ đếm bước. Chưa kiểm thử thực nghiệm thì không kết luận độ chính xác.',
    ),
    const SizedBox(height: 22),
    const Text(
      'TÀI LIỆU THAM KHẢO',
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1,
        color: muted,
        fontWeight: FontWeight.w800,
      ),
    ),
    const SizedBox(height: 8),
    const SelectableText(
      'Biên soạn dựa trên 4 tài liệu nhóm cung cấp.\npub.dev/packages/sensors_plus\npub.dev/packages/pedometer\ndeveloper.android.com/develop/sensors-and-location/sensors/sensors_motion',
      style: TextStyle(color: muted, fontSize: 12, height: 1.8),
    ),
  ];

  Widget _lesson(IconData icon, String title, String body) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: teal, size: 28),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: muted, height: 1.6)),
      ],
    ),
  );

  Widget _learningStep(String number, String title, String body) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE7F2ED),
          child: Text(
            number,
            style: const TextStyle(
              color: teal,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _reconnect({bool requestPermission = false}) async {
    c.pauseSession();
    await c.connect(requestPermission: requestPermission);
  }

  Future<void> _copyHistory() async {
    final lines = ['thoi_gian,nguon,buoc,giay,km_uoc_tinh,muc_tieu,ghi_chu'];
    for (final r in _filteredHistory) {
      lines.add(
        '${r.started.toIso8601String()},${r.simulated ? "mo_phong" : "do_that"},${r.steps ?? ""},${r.seconds},${r.kilometers?.toStringAsFixed(3) ?? ""},${r.goal},"${r.note.replaceAll('"', '""')}"',
      );
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép CSV. Có thể dán vào bảng tính.'),
        ),
      );
    }
  }

  Future<void> _settings() async {
    var goal = c.goal.toDouble();
    var length = c.stepLength;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thiết lập phiên đo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  c.hasSession
                      ? 'Kết thúc phiên hiện tại để thay đổi thiết lập.'
                      : 'Chọn mục tiêu nhỏ để dễ trình diễn trong lớp.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mục tiêu: ${goal.round()} bước',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: goal,
                  min: 20,
                  max: 10000,
                  divisions: 499,
                  label: '${goal.round()}',
                  onChanged: c.hasSession
                      ? null
                      : (value) => update(() => goal = value),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final preset in [30, 100, 500, 1000])
                      ActionChip(
                        label: Text('$preset bước'),
                        onPressed: c.hasSession
                            ? null
                            : () => update(() => goal = preset.toDouble()),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Độ dài một bước: ${length.toStringAsFixed(2)} m',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: length,
                  min: .3,
                  max: 1.2,
                  divisions: 90,
                  onChanged: c.hasSession
                      ? null
                      : (value) => update(() => length = value),
                ),
                const Text(
                  'Dùng để ước tính quãng đường. Đây là độ dài một bước, không phải khoảng cách của hai bước liên tiếp.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: c.hasSession
                      ? null
                      : () async {
                          await c.updateSettings(goal.round(), length);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                  child: const Text('Lưu thiết lập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
