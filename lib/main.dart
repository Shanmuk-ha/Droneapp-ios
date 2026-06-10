import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math';
import 'dart:ui' show instantiateImageCodec;

// ── THEME SYSTEM ──────────────────────────────────────────────────────────────
class AppTheme {
  static bool isDark = false;

  static const Color darkBg          = Color(0xFF1A1E2E);
  static const Color darkSurface     = Color(0xFF11152A);
  static const Color darkCard        = Color(0xFF11152A);
  static const Color darkBorder      = Color(0xFF1E2840);
  static const Color darkText        = Color(0xFFD0D8FF);
  static const Color darkSubtext     = Color(0xFF4A5A88);
  static const Color darkAccent      = Color(0xFF5A7AFF);
  static const Color darkAccentLight = Color(0xFF7EB3FF);

  static const Color lightBg          = Color(0xFFF0F2FA);
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightCard        = Color(0xFFFFFFFF);
  static const Color lightBorder      = Color(0xFFDDE3F5);
  static const Color lightText        = Color(0xFF1A1E3A);
  static const Color lightSubtext     = Color(0xFF6B7BAD);
  static const Color lightAccent      = Color(0xFF4060FF);
  static const Color lightAccentLight = Color(0xFF5A7AFF);

  static Color get bg          => isDark ? darkBg          : lightBg;
  static Color get surface     => isDark ? darkSurface     : lightSurface;
  static Color get card        => isDark ? darkCard        : lightCard;
  static Color get border      => isDark ? darkBorder      : lightBorder;
  static Color get text        => isDark ? darkText        : lightText;
  static Color get subtext     => isDark ? darkSubtext     : lightSubtext;
  static Color get accent      => isDark ? darkAccent      : lightAccent;
  static Color get accentLight => isDark ? darkAccentLight : lightAccentLight;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const DroneApp());
}

// ── DRONE APP ─────────────────────────────────────────────────────────────────
class DroneApp extends StatefulWidget {
  const DroneApp({super.key});
  static _DroneAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_DroneAppState>();
  @override
  State<DroneApp> createState() => _DroneAppState();
}

class _DroneAppState extends State<DroneApp> {
  bool _isDark = false;

  void toggleTheme() {
    setState(() {
      _isDark = !_isDark;
      AppTheme.isDark = _isDark;
    });
    SharedPreferences.getInstance()
        .then((p) => p.setBool('isDark', _isDark));
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final saved = p.getBool('isDark') ?? false;
      if (saved != _isDark) {
        setState(() {
          _isDark = saved;
          AppTheme.isDark = saved;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.bg,
        colorScheme: ColorScheme(
          brightness: _isDark ? Brightness.dark : Brightness.light,
          primary: AppTheme.accent,
          onPrimary: Colors.white,
          secondary: AppTheme.accent,
          onSecondary: Colors.white,
          error: const Color(0xFFFF5757),
          onError: Colors.white,
          surface: AppTheme.surface,
          onSurface: AppTheme.text,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/home': (ctx) => const DroneController(),
      },
    );
  }
}

// ── SPLASH SCREEN ─────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _barController;
  late Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _barProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 1400),
            () { if (mounted) _barController.forward(); });
    Future.delayed(const Duration(milliseconds: 4000),
            () { if (mounted) Navigator.pushReplacementNamed(context, '/home'); });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _barController.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111520),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                // QUANTUM (STATIC)
                const Text(
                  'QUANTUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(width: 4),

                // ONLY LOGO ANIMATES
                AnimatedBuilder(
                  animation: _logoController,

                  builder: (_, __) {

                    return Transform.scale(
                      scale: 0.85 + (_logoController.value * 0.15),

                     child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.modulate,
                        ),

                        child: Image.asset(
                          'assets/Logo.png',
                          width: 120,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 4),

                // ROBOTIX (STATIC)
                const Text(
                  'ROBOTIX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _barController,
              builder: (_, __) => Opacity(
                opacity: 1.0,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: 160,
                        height: 2,
                        child: Stack(children: [
                          Container(color: const Color(0xFF1E2840)),
                          FractionallySizedBox(
                            widthFactor: _barProgress.value,
                            child: Container(
                                color: const Color(0xFF5A7AFF)),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final phase = (_barController.value * 3 - i)
                            .clamp(0.0, 1.0);
                        return Container(
                          margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5A7AFF)
                                .withOpacity(0.3 + 0.7 * phase),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── LOGO PAINTER ──────────────────────────────────────────────────────────────
class _LogoPainter extends CustomPainter {
  final double progress;
  _LogoPainter({required this.progress});

  static const int linePairs = 7;
  static const double half = 36.0;

  double _easeOutBack(double x) {
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2);
  }
  double _easeOut(double x) => 1 - pow(1 - x, 3).toDouble();
  double _prog(double s, double e, double v) =>
      ((v - s) / (e - s)).clamp(0.0, 1.0);

  double _lineOpacity(int i) {
    const mid = (linePairs - 1) / 2.0;
    final dist = (i - mid).abs() / mid;
    return 1.0 - dist * 0.75;
  }

  double _lineWidth(int i) {
    const mid = (linePairs - 1) / 2.0;
    final dist = (i - mid).abs() / mid;
    return 1.8 - dist * 1.1;
  }

  List<double> get _offsets {
    final list = <double>[];
    for (int i = 0; i < linePairs; i++) {
      list.add((i - (linePairs - 1) / 2) *
          (half * 0.82 / (linePairs - 1) * 2) *
          0.5);
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const white = Color(0xFFE0E8FF);

    final p = progress;
    final diamP   = _easeOutBack(_prog(0.0,  0.22, p));
    final linesP  = _easeOut(_prog(0.18, 0.78, p));
    final borderP = _easeOut(_prog(0.70, 1.0,  p));
    final textP   = _easeOut(_prog(0.55, 1.0,  p));

    if (textP > 0) {
      final style = TextStyle(
        color: white.withOpacity(textP),
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: 3,
      );
      final quantum = TextPainter(
        text: TextSpan(text: 'QUANTUM', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      quantum.paint(canvas,
          Offset(cx - half - 14 - quantum.width,
              cy - quantum.height / 2));
      final robotix = TextPainter(
        text: TextSpan(text: 'ROBOTIX', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      robotix.paint(canvas,
          Offset(cx + half + 14, cy - robotix.height / 2));
    }

    canvas.save();
    canvas.translate(cx, cy);

    if (borderP > 0) {
      canvas.save();
      canvas.rotate(pi / 4);
      const side = half * 2;
      final path = Path()..addRect(Rect.fromCenter(
          center: Offset.zero, width: side, height: side));
      final metric = path.computeMetrics().first;
      final drawn = metric.extractPath(0, metric.length * borderP);
      canvas.drawPath(drawn, Paint()
        ..color = white.withOpacity(borderP)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round);
      canvas.restore();
    }

    if (linesP > 0) {
      const maxLen = half * 1.42;
      final offsets = _offsets;
      for (int i = 0; i < linePairs; i++) {
        final off = offsets[i];
        final alpha = _lineOpacity(i);
        final lw = _lineWidth(i);
        final len = maxLen * linesP;
        final paint = Paint()
          ..color = white.withOpacity(alpha)
          ..strokeWidth = lw
          ..strokeCap = StrokeCap.round;
        const a1 = pi / 4;
        const perp1 = a1 + pi / 2;
        final ox1 = off * cos(perp1);
        final oy1 = off * sin(perp1);
        canvas.drawLine(
          Offset(ox1 - cos(a1) * len, oy1 - sin(a1) * len),
          Offset(ox1 + cos(a1) * len, oy1 + sin(a1) * len),
          paint,
        );
        const a2 = -pi / 4;
        const perp2 = a2 + pi / 2;
        final ox2 = off * cos(perp2);
        final oy2 = off * sin(perp2);
        canvas.drawLine(
          Offset(ox2 - cos(a2) * len, oy2 - sin(a2) * len),
          Offset(ox2 + cos(a2) * len, oy2 + sin(a2) * len),
          paint,
        );
      }
    }

    if (diamP > 0) {
      canvas.save();
      canvas.rotate(pi / 4);
      final ds = diamP * 8;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: ds, height: ds),
        Paint()
          ..color = white.withOpacity(diamP.clamp(0, 1))
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.progress != progress;
}

// ── TUTORIAL OVERLAY ──────────────────────────────────────────────────────────
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const TutorialOverlay({super.key, required this.onDone});
  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  static const List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.flight_takeoff,
      'color': Color(0xFF5A7AFF),
      'title': 'Welcome to QR Drone Controller',
      'body':
      'This quick guide will walk you through all the features of the app. Tap Next to continue.',
      'tip': null,
    },
    {
      'icon': Icons.wifi,
      'color': Color(0xFF3DDA82),
      'title': 'Step 1 — Pair with your drone',
      'body':
      'Connect your phone to the drone\'s Wi-Fi network first. Then tap the PAIR button in the top-left corner.',
      'tip': '💡 The button turns green when successfully paired.',
    },
    {
      'icon': Icons.lock_open,
      'color': Color(0xFFF5C842),
      'title': 'Step 2 — Arm the drone',
      'body':
      'After pairing, tap ARM to arm the motors. Make sure throttle is at zero before arming.',
      'tip':
      '⚠ Keep throttle at 0 before arming. The app will warn you if throttle is too high.',
    },
    {
      'icon': Icons.gamepad,
      'color': Color(0xFF5A7AFF),
      'title': 'Step 3 — Joystick controls',
      'body':
      'Left joystick: Throttle (up/down) and Yaw (rotate left/right).\n\nRight joystick: Roll (tilt left/right) and Pitch (tilt forward/back).',
      'tip':
      '💡 Throttle holds its position when released. All other controls return to centre.',
    },
    {
      'icon': Icons.videocam,
      'color': Color(0xFF3DDA82),
      'title': 'Step 4 — Camera feed',
      'body':
      'Tap CAM OFF to enable the live camera feed from your drone. The joystick backgrounds turn transparent so you can see the feed.',
      'tip':
      '💡 Camera connects to the drone over your local Wi-Fi.',
    },
    {
      'icon': Icons.fiber_manual_record,
      'color': Color(0xFFFF5757),
      'title': 'Step 5 — Recording',
      'body':
      'While the camera is ON, tap Record to start recording. Tap Stop to save the video to your gallery under the QR Drone Controller album.',
      'tip':
      '💡 Frames are captured in real time and encoded to MP4 when you stop.',
    },
    {
      'icon': Icons.tune,
      'color': Color(0xFF5A7AFF),
      'title': 'Step 6 — Flight control settings',
      'body':
      'Open Settings → Flight control settings to tune PID values.\n\n• P, I, D, A — tap the value badge to type directly\n• R (Roll) and Pt (Pitch trim) — use the bipolar slider',
      'tip':
      '💡 Changes are saved automatically and sent to the drone on each control packet.',
    },
    {
      'icon': Icons.explore_outlined,
      'color': Color(0xFF5A7AFF),
      'title': 'Step 7 — Level calibration',
      'body':
      'Place the drone on a flat surface, go to Settings → Level calibration, and tap Start calibration. The drone will receive calibration signals for 5 seconds.',
      'tip': '⚠ Drone must be paired but NOT armed for calibration.',
    },
    {
      'icon': Icons.analytics_outlined,
      'color': Color(0xFF7EB3FF),
      'title': 'Step 8 — Telemetry display',
      'body':
      'The centre of the screen shows live telemetry:\n\n• ROLL — tilt angle left/right\n• PITCH — tilt angle forward/back\n• THR — throttle percentage\n• YAW — rotation angle',
      'tip': '💡 Telemetry is hidden when camera feed is enabled.',
    },
    {
      'icon': Icons.brightness_6,
      'color': Color(0xFFF5C842),
      'title': 'Step 9 — Theme',
      'body':
      'You can switch between dark and light mode from Settings → Appearance. The preference is saved automatically.',
      'tip': '💡 Dark mode is recommended for outdoor use.',
    },
    {
      'icon': Icons.power_settings_new,
      'color': Color(0xFFFF5757),
      'title': 'Step 10 — Closing the app',
      'body':
      'Tap the red power button in the top-left to safely close the app. If the drone is armed, you will be prompted to disarm first.',
      'tip': '💡 Always disarm before closing for safe motor shutdown.',
    },
    {
      'icon': Icons.check_circle_outline,
      'color': Color(0xFF3DDA82),
      'title': 'You\'re ready to fly!',
      'body':
      'You can replay this guide any time from Settings → Help → App guide.\n\nFly safe and have fun!',
      'tip': null,
    },
  ];
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }
  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }
  void _next() {
    if (_step >= _steps.length - 1) {
      widget.onDone();
      return;
    }
    _animCtrl.reverse().then((_) {
      setState(() => _step++);
      _animCtrl.forward();
    });
  }
  void _prev() {
    if (_step == 0) return;
    _animCtrl.reverse().then((_) {
      setState(() => _step--);
      _animCtrl.forward();
    });
  }
  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;
    final color = step['color'] as Color;
    return Material(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            width: 420,
            // ── FIX: constrain max height so the modal never exceeds the screen ──
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header (fixed, never scrolls) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Icon(step['icon'] as IconData,
                            color: color, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Body (scrollable) ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          step['body'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        if (step['tip'] != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: color.withOpacity(0.2)),
                            ),
                            child: Text(
                              step['tip'] as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // ── Progress dots (fixed) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == _step ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == _step ? color : AppTheme.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // ── Buttons (fixed) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            onPressed: _prev,
                            child: Text('Back',
                                style:
                                TextStyle(color: AppTheme.subtext)),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                          onPressed: _next,
                          child: Text(
                            isLast ? 'Start flying!' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_step == 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: widget.onDone,
                          child: Text('Skip',
                              style: TextStyle(
                                  color: AppTheme.subtext, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SETTINGS PAGE ─────────────────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  final bool isPaired;
  final bool isArmed;
  final RawDatagramSocket? droneSocket;

  const SettingsPage({
    super.key,
    required this.isPaired,
    required this.isArmed,
    this.droneSocket,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.air,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text('QR Drone Controller',
                style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Control'),
          _SettingsItem(
            title: 'Flight control settings',
            subtitle: 'PID tuning and angle limits',
            icon: Icons.tune,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FlightControlSettingsPage(),
              ),
            ),
          ),
          _SettingsItem(
            title: 'Level calibration',
            subtitle: widget.isPaired
                ? widget.isArmed
                ? 'Disarm drone first'
                : 'Tap to calibrate'
                : 'Pair drone first',
            icon: Icons.explore_outlined,
            showWarning: widget.isPaired && widget.isArmed,
            disabled: !widget.isPaired,
            onTap: () {
              if (!widget.isPaired) {
                _showInfoDialog(context,
                    icon: Icons.link_off,
                    iconColor: const Color(0xFFFF5757),
                    title: 'Drone not paired',
                    message:
                    'Please pair with your drone before calibrating.');
              } else if (widget.isArmed) {
                _showInfoDialog(context,
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFF5C842),
                    title: 'Drone is armed',
                    message:
                    'Please disarm the drone before calibrating.\n\nCalibration cannot be performed while armed.');
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelCalibrationPage(
                        isPaired: widget.isPaired,
                        mainSocket: widget.droneSocket,),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Appearance'),
          _SettingsItem(
            title: 'Theme',
            subtitle:
            AppTheme.isDark ? 'Dark mode' : 'Light mode',
            icon: AppTheme.isDark
                ? Icons.dark_mode
                : Icons.light_mode,
            showChevron: false,
            onTap: () {
              DroneApp.of(context)?.toggleTheme();
              setState(() {});
            },
            trailingWidget: Switch(
              value: AppTheme.isDark,
              onChanged: (_) {
                DroneApp.of(context)?.toggleTheme();
                setState(() {});
              },
              activeColor: AppTheme.accent,
            ),
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Help'),
          _SettingsItem(
            title: 'App guide',
            subtitle: 'Replay the getting started tutorial',
            icon: Icons.help_outline,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('tutorialSeen', false);
              if (!mounted) return;
              // Pop settings and signal DroneController to show tutorial
              Navigator.pop(context, 'showTutorial');
            },
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Legal & info'),
          _SettingsItem(
            title: 'Privacy policy',
            subtitle: 'How we handle your data',
            icon: Icons.privacy_tip_outlined,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage())),
          ),
          _SettingsItem(
            title: 'Terms of service',
            subtitle: 'Usage rules and liability',
            icon: Icons.gavel_outlined,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TermsOfServicePage())),
          ),
          _SettingsItem(
            title: 'Open source licences',
            subtitle: 'Third-party packages used',
            icon: Icons.code_outlined,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'QR Drone Controller',
              applicationVersion: '5.0.0',
              applicationLegalese: '© 2025 Quantum Robotix',
            ),
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'About'),
          _SettingsItem(
            title: 'App version',
            subtitle: '1.0.6 (build 1)',
            icon: Icons.info_outline,
            onTap: () {},
            showChevron: false,
          ),
          _SettingsItem(
            title: 'QR Drone Controller',
            subtitle: 'by Quantum Robotix · quantumrobotix.com',
            icon: Icons.business_outlined,
            onTap: () {},
            showChevron: false,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context,
      {required IconData icon,
        required Color iconColor,
        required String title,
        required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Flexible(
              child: Text(title,
                  style: TextStyle(color: iconColor))),
        ]),
        content: Text(message,
            style: TextStyle(
                color: AppTheme.text, fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.subtext,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final bool disabled;
  final bool showWarning;
  final bool showChevron;
  final Widget? trailingWidget;

  const _SettingsItem({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.disabled = false,
    this.showWarning = false,
    this.showChevron = true,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: icon != null
              ? Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: showWarning
                  ? const Color(0xFF3A2E00)
                  : disabled
                  ? AppTheme.bg
                  : AppTheme.isDark
                  ? const Color(0xFF1A2040)
                  : const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 18,
                color: showWarning
                    ? const Color(0xFFF5C842)
                    : disabled
                    ? AppTheme.subtext
                    : AppTheme.accent),
          )
              : null,
          title: Text(title,
              style: TextStyle(
                  color: disabled && !showWarning
                      ? AppTheme.subtext
                      : AppTheme.text,
                  fontSize: 15)),
          subtitle: subtitle != null
              ? Text(subtitle!,
              style: TextStyle(
                color: showWarning
                    ? const Color(0xFFF5C842)
                    : AppTheme.subtext,
                fontSize: 12,
              ))
              : null,
          trailing: trailingWidget ??
              (showChevron
                  ? Icon(
                  showWarning
                      ? Icons.warning_amber_rounded
                      : Icons.chevron_right,
                  color: showWarning
                      ? const Color(0xFFF5C842)
                      : disabled
                      ? AppTheme.border
                      : AppTheme.accent,
                  size: 20)
                  : null),
          onTap: onTap,
        ),
        Divider(
            color: AppTheme.border,
            height: 1,
            indent: 16,
            endIndent: 16),
      ],
    );
  }
}

// ── LEVEL CALIBRATION PAGE ────────────────────────────────────────────────────
class LevelCalibrationPage extends StatefulWidget {
  final bool isPaired;
  final RawDatagramSocket? mainSocket;
  const LevelCalibrationPage({super.key, required this.isPaired, this.mainSocket});
  @override
  State<LevelCalibrationPage> createState() =>
      _LevelCalibrationPageState();
}

class _LevelCalibrationPageState extends State<LevelCalibrationPage>
    with SingleTickerProviderStateMixin {
  bool _calibrated = false;
  bool _isCalibrating = false;
  int _calibrationSeconds = 0;
  Timer? _calibrationTimer;
  Timer? _sendTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const int _totalSeconds = 5;
  static const String _calData = '127,1800,0,127,0,0,0,0,0,0\n';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  @override
  void dispose() {
    _calibrationTimer?.cancel();
    _sendTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            content: SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.7,

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // TITLE
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accent,
                        size: 18,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        'Before calibrating',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // BULLETS
                  _BulletPoint(
                    'Place the drone on a flat, level surface',
                  ),

                  _BulletPoint(
                    'Make sure the drone is completely stationary',
                  ),

                  _BulletPoint(
                    'Drone must be paired but NOT armed',
                  ),

                  _BulletPoint(
                    'Do not touch the drone during calibration',
                  ),

                  _BulletPoint(
                    'Calibration takes 5 seconds to complete',
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),

                child: Text(
                  'Got it',
                  style: TextStyle(
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _startCalibration() async {
    setState(() {
      _isCalibrating = true;
      _calibrationSeconds = 0;
      _calibrated = false;
    });

    try {
      final ip = InternetAddress('192.168.4.1');
      const port = 12345;

      // Use the existing main socket — never create a new one
      // Creating a new socket drops the existing drone connection
      final socket = widget.mainSocket;

      if (socket == null) {
        throw Exception('Not connected to drone');
      }

      _sendTimer = Timer.periodic(
          const Duration(milliseconds: 100), (_) {
        try {
          socket.send(_calData.codeUnits, ip, port);
        } catch (e) {
          _DebugLog.add('Cal send error: $e');
        }
      });

      _calibrationTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted) {
              timer.cancel();
              _sendTimer?.cancel();
              return;
            }
            setState(() => _calibrationSeconds++);
            if (_calibrationSeconds >= _totalSeconds) {
              timer.cancel();
              _sendTimer?.cancel();
              // DO NOT close socket — it belongs to DroneController
              setState(() {
                _isCalibrating = false;
                _calibrated = true;
              });
              _showSuccessDialog();
            }
          });
    } catch (e) {
      _sendTimer?.cancel();
      if (!mounted) return;
      setState(() => _isCalibrating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Calibration failed: $e'),
        backgroundColor: const Color(0xFFFF5757),
      ));
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle,
                    color: Color(0xFF3DDA82), size: 24),
                SizedBox(width: 10),
                Text('Calibration complete',
                    style: TextStyle(color: Color(0xFF3DDA82))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The drone has been successfully level calibrated.',
                  style: TextStyle(color: AppTheme.text, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your flight control settings remain unchanged.',
                  style:
                  TextStyle(color: AppTheme.subtext, fontSize: 12),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DDA82),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery
        .of(context)
        .size
        .height;
    final screenW = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.accent, size: 20),
          onPressed:
          _isCalibrating ? null : () => Navigator.pop(context),
        ),
        title: Text('Level calibration',
            style: TextStyle(
                color: AppTheme.text,
                fontSize: 17,
                fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline,
                color: AppTheme.accent, size: 20),
            onPressed: _showInstructionsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenH * 0.02,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [


              GestureDetector(
              onTap: _isCalibrating
              ? null
                  : _startCalibration,

                child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) =>
                        Transform.scale(
                          scale: _isCalibrating
                              ? _pulseAnim.value
                              : 1.0,

                          child: Container(
                            width: screenW * 0.28,
                            height: screenW * 0.28,

                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,

                              border: Border.all(
                                color: _calibrated
                                    ? const Color(0xFF3DDA82)
                                    : _isCalibrating
                                    ? AppTheme.accent
                                    : AppTheme.border,

                                width: _isCalibrating ? 3 : 2,
                              ),
                            ),

                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children: [

                                Icon(
                                  _calibrated
                                      ? Icons.check_circle_outline
                                      : _isCalibrating
                                      ? Icons.sync
                                      : Icons.explore_outlined,

                                  color: _calibrated
                                      ? const Color(0xFF3DDA82)
                                      : AppTheme.accent,

                                  size: screenW * 0.05,
                                ),

                                SizedBox(
                                  height: screenH * 0.008,
                                ),

                                if (_isCalibrating) ...[

                                  Text(
                                    '$_calibrationSeconds / $_totalSeconds',

                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),

                                  SizedBox(
                                    height: screenH * 0.004,
                                  ),

                                  Text(
                                    'Calibrating...',
                                    style: TextStyle(
                                      color: AppTheme.accentLight,
                                      fontSize: 12,
                                    ),
                                  ),

                                ] else
                                  if (_calibrated) ...[

                                    const Text(
                                      'Calibrated',

                                      style: TextStyle(
                                        color: Color(0xFF3DDA82),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                  ] else
                                    ...[

                                      Text(
                                        'Ready',

                                        style: TextStyle(
                                          color: AppTheme.accentLight,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                              ],
                            ),
                          ),
                        ),
                  ),
              ),

                  SizedBox(height: screenH * 0.015),

                  if (_isCalibrating) ...[
                    SizedBox(
                      width: screenW * 0.36,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _calibrationSeconds / _totalSeconds,
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accent),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.006),
                    Text(
                      'Keep the drone still on a flat surface',
                      style: TextStyle(
                          color: AppTheme.subtext, fontSize: 12),
                    ),
                    SizedBox(height: screenH * 0.01),
                  ] else
                    SizedBox(height: screenH * 0.01),
                                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(
                  color: AppTheme.accent, fontSize: 13)),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppTheme.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── PRIVACY POLICY PAGE ───────────────────────────────────────────────────────
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  String _today() {
    final now = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy policy',
            style: TextStyle(color: AppTheme.text, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PolicyHeader(
              title: 'Privacy Policy',
              subtitle: 'Quantum Robotix — QR Drone Controller',
              date: 'Effective date: ${_today()}',
            ),
            const SizedBox(height: 20),
            const _PolicySection(title: 'Overview',
              content: 'Quantum Robotix ("we", "us", or "our") built the QR Drone Controller app. This page explains our privacy policy with respect to the collection, use, and disclosure of personal information when you use our app.',
            ),
            const _PolicySection(title: 'Information we collect',
              content: 'We do not collect, store, or transmit any personal information. The app operates entirely on your local device and communicates only with your drone over a local Wi-Fi connection.\n\nThe following data stays only on your device:\n• PID flight control settings (stored locally via SharedPreferences)\n• Recorded video footage (saved to your device gallery)\n\nNone of this data is transmitted to our servers or any third party.',
            ),
            const _PolicySection(title: 'Network communications',
              content: 'The app communicates exclusively with your drone via UDP over a local Wi-Fi network. No data is sent to the internet. The app requires Wi-Fi access only to detect and connect to your drone\'s access point.',
            ),
            const _PolicySection(title: 'Camera and video',
              content: 'If your drone has a camera, the app can display and record the live video feed. Recorded videos are saved directly to your device\'s gallery and are never uploaded or shared by the app.',
            ),
            const _PolicySection(title: 'Permissions',
              content: 'The app requests the following permissions:\n\n• Internet / Wi-Fi — to connect to your drone\n• Storage / Photos — to save recorded video to your gallery\n\nThese permissions are used solely for the stated purposes.',
            ),
            const _PolicySection(title: 'Third-party services',
              content: 'This app does not use any third-party analytics, advertising, or tracking services.',
            ),
            const _PolicySection(title: 'Children\'s privacy',
              content: 'This app is not directed at children under 13. We do not knowingly collect information from children. The app should only be used by adults or under adult supervision.',
            ),
            const _PolicySection(title: 'Changes to this policy',
              content: 'We may update this privacy policy from time to time. We will notify you of changes by updating the effective date above. Continued use of the app after changes constitutes acceptance.',
            ),
            const _PolicySection(title: 'Contact us',
              content: 'If you have questions about this privacy policy, contact us at:\n\nQuantum Robotix\nEmail: privacy@quantumrobotix.com\nWebsite: quantumrobotix.com',
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.isDark
                    ? const Color(0xFF0E1830)
                    : const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This app does not collect any personal data. All settings and recordings remain on your device.',
                      style: TextStyle(
                          color: AppTheme.accent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── TERMS OF SERVICE PAGE ─────────────────────────────────────────────────────
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  String _today() {
    final now = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Terms of service',
            style: TextStyle(color: AppTheme.text, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PolicyHeader(
              title: 'Terms of Service',
              subtitle: 'Quantum Robotix — QR Drone Controller',
              date: 'Effective date: ${_today()}',
            ),
            const SizedBox(height: 20),
            const _PolicySection(title: '1. Acceptance of terms',
              content: 'By downloading or using the QR Drone Controller app, you agree to be bound by these Terms of Service. If you do not agree, do not use the app.',
            ),
            const _PolicySection(title: '2. Intended use',
              content: 'This app is designed exclusively for controlling compatible Quantum Robotix drones. You agree to use the app only for its intended purpose and in accordance with all applicable laws.',
            ),
            const _PolicySection(title: '3. Safety and responsibility',
              content: 'Operating a drone carries inherent risks. You acknowledge that:\n\n• You are solely responsible for the safe operation of your drone\n• You will comply with all local laws regarding drone operation\n• You will not fly in restricted airspace or over crowds\n• You will maintain visual line-of-sight at all times\n• Quantum Robotix is not responsible for any damage or injury',
            ),
            const _PolicySection(title: '4. Disclaimer of warranties',
              content: 'This app is provided "as is" without warranties of any kind. Use of the app is at your own risk.',
            ),
            const _PolicySection(title: '5. Limitation of liability',
              content: 'To the maximum extent permitted by law, Quantum Robotix shall not be liable for any damages arising from use of this app, including drone crashes, property damage, or personal injury.',
            ),
            const _PolicySection(title: '6. Intellectual property',
              content: 'The app and all its content are the property of Quantum Robotix. You may not copy, modify, distribute, or reverse engineer the app.',
            ),
            const _PolicySection(title: '7. Updates and changes',
              content: 'We reserve the right to update these terms at any time. Continued use constitutes acceptance of updated terms.',
            ),
            const _PolicySection(title: '8. Governing law',
              content: 'These terms are governed by the laws of India. Any disputes shall be resolved in the courts of India.',
            ),
            const _PolicySection(title: '9. Contact',
              content: 'Quantum Robotix\nEmail: legal@quantumrobotix.com\nWebsite: quantumrobotix.com',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── SHARED POLICY WIDGETS ─────────────────────────────────────────────────────
class _PolicyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  const _PolicyHeader(
      {required this.title,
        required this.subtitle,
        required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: AppTheme.accent, fontSize: 13)),
          const SizedBox(height: 4),
          Text(date,
              style: TextStyle(
                  color: AppTheme.subtext, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  const _PolicySection(
      {required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppTheme.accentLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 13,
                  height: 1.6)),
        ],
      ),
    );
  }
}

// ── FLIGHT CONTROL SETTINGS PAGE ─────────────────────────────────────────────
class FlightControlSettingsPage extends StatefulWidget {
  const FlightControlSettingsPage({super.key});
  @override
  State<FlightControlSettingsPage> createState() =>
      _FlightControlSettingsPageState();
}

class _FlightControlSettingsPageState
    extends State<FlightControlSettingsPage> {
  double p = 0.42, i = 0.001, d = 0.036, a = 15.0, rT = 0.0, pT = 0.0;
  // ↑ Roll and Pitch trim default changed to 0.0

  final Map<String, List<double>> _bipolarRanges = {
    'R':  [-2.0, 2.0],
    'Pt': [-2.0, 2.0],
  };

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  Future<void> _loadValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        p  = prefs.getDouble('P')  ?? 0.42;
        i  = prefs.getDouble('I')  ?? 0.001;
        d  = prefs.getDouble('D')  ?? 0.036;
        a  = prefs.getDouble('A')  ?? 15.0;
        rT = prefs.getDouble('RT') ?? 0.0;  // ← default 0
        pT = prefs.getDouble('PT') ?? 0.0;  // ← default 0
      });
    } catch (_) {}
  }

  Future<void> _saveValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('P',  p);
      await prefs.setDouble('I',  i);
      await prefs.setDouble('D',  d);
      await prefs.setDouble('A',  a);
      await prefs.setDouble('RT', rT);
      await prefs.setDouble('PT', pT);
      _DebugLog.add('✓ Settings saved: P=$p I=$i D=$d A=$a R=$rT Pt=$pT');
    } catch (e) {
      _DebugLog.add('Settings save error: $e');
    }
  }

  String _format(String key, double val) {
    if (key == 'I') return val.toStringAsFixed(4);
    if (key == 'A') return val.toStringAsFixed(1);
    return val.toStringAsFixed(3);
  }

  // ── Direct value setter — always uses setState ──
  void _setValue(String key, double val) {
    setState(() {
      switch (key) {
        case 'P':  p  = val; break;
        case 'I':  i  = val; break;
        case 'D':  d  = val; break;
        case 'A':  a  = val; break;
        case 'R':  rT = val; break;
        case 'Pt': pT = val; break;
      }
    });
  }

  void _editTextOnly(String label, String key, double current) {
    final controller =
    TextEditingController(text: current.toStringAsFixed(4));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $label',
            style: TextStyle(
                color: AppTheme.accentLight,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          style: TextStyle(color: AppTheme.text, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Enter value',
            hintStyle: TextStyle(color: AppTheme.subtext),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                BorderSide(color: AppTheme.accent, width: 2)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.subtext))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                _setValue(key, val);
                // Save immediately after setting
                _saveValues();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editBipolar(String label, String key, double current) {
    final controller =
    TextEditingController(text: current.toStringAsFixed(4));
    final currentMin = _bipolarRanges[key]![0];
    final currentMax = _bipolarRanges[key]![1];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $label',
            style: TextStyle(
                color: AppTheme.accentLight,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Range: $currentMin – $currentMax',
                style:
                TextStyle(color: AppTheme.subtext, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Enter value outside range to auto-expand slider',
              style:
              TextStyle(color: AppTheme.subtext, fontSize: 11),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              style: TextStyle(color: AppTheme.text, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Enter value',
                hintStyle: TextStyle(color: AppTheme.subtext),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppTheme.accent, width: 2)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.subtext))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                setState(() {
                  // Auto-expand range if needed
                  final span = _bipolarRanges[key]![1] -
                      _bipolarRanges[key]![0];
                  if (val < _bipolarRanges[key]![0]) {
                    _bipolarRanges[key]![0] = val - span * 0.1;
                  }
                  if (val > _bipolarRanges[key]![1]) {
                    _bipolarRanges[key]![1] = val + span * 0.1;
                  }
                });
                _setValue(key, val);
                _saveValues();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard({
    required String label,
    required String key,
    required double val,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: TextStyle(
                          color: AppTheme.subtext, fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _editTextOnly(label, key, val),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.isDark
                      ? const Color(0xFF1A2040)
                      : const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _format(key, val),
                      style: TextStyle(
                        color: AppTheme.accentLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit,
                        color: AppTheme.accent, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBipolarCard({
    required String label,
    required String key,
    required double val,
    required String desc,
  }) {
    final min = _bipolarRanges[key]![0];
    final max = _bipolarRanges[key]![1];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(desc,
                        style: TextStyle(
                            color: AppTheme.subtext,
                            fontSize: 12)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _editBipolar(label, key, val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.isDark
                          ? const Color(0xFF1A2040)
                          : const Color(0xFFE8EEFF),
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      _format(key, val),
                      style: TextStyle(
                        color: AppTheme.accentLight,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BipolarSlider(
              value: val.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => _setValue(key, v),
              onChangeEnd: (_) => _saveValues(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    min == min.toInt()
                        ? min.toInt().toString()
                        : min.toStringAsFixed(1),
                    style: TextStyle(
                        color: AppTheme.subtext, fontSize: 11),
                  ),
                  Text('0',
                      style: TextStyle(
                          color: AppTheme.subtext, fontSize: 11)),
                  Text(
                    max == max.toInt()
                        ? max.toInt().toString()
                        : max.toStringAsFixed(1),
                    style: TextStyle(
                        color: AppTheme.subtext, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.accent, size: 20),
          onPressed: () {
            // Save before leaving to guarantee persistence
            _saveValues().then((_) => Navigator.pop(context));
          },
        ),
        title: Text('Flight control settings',
            style: TextStyle(
                color: AppTheme.text,
                fontSize: 17,
                fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.isDark
                  ? const Color(0xFF0E1830)
                  : const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'P, I, D, A — tap the value to enter directly. Roll and Pitch Trim have sliders with negative range.',
                    style: TextStyle(
                        color: AppTheme.accent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          _buildTextCard(label: 'P — Proportional', key: 'P',
              val: p, desc: 'How aggressively the drone corrects errors'),
          _buildTextCard(label: 'I — Integral', key: 'I',
              val: i, desc: 'Corrects steady-state drift'),
          _buildTextCard(label: 'D — Derivative', key: 'D',
              val: d, desc: 'Dampens oscillation'),
          _buildTextCard(label: 'A — Angle strength', key: 'A',
              val: a, desc: 'Strength of angle correction'),
          _buildBipolarCard(label: 'R — Roll', key: 'R',
              val: rT, desc: 'Roll axis trim (-2 to +2)'),
          _buildBipolarCard(label: 'Pt — Pitch trim', key: 'Pt',
              val: pT, desc: 'Pitch axis trim (-2 to +2)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Reset to defaults?',
                      style: TextStyle(color: AppTheme.text)),
                  content: Text(
                    'P=0.42  I=0.001  D=0.036  A=15\nR=0  Pt=0',
                    style: TextStyle(
                        color: AppTheme.subtext,
                        fontSize: 13,
                        fontFamily: 'monospace'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: AppTheme.subtext)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          p = 0.42; i = 0.001; d = 0.036;
                          a = 15.0; rT = 0.0;  pT = 0.0;
                          _bipolarRanges['R']  = [-2.0, 2.0];
                          _bipolarRanges['Pt'] = [-2.0, 2.0];
                        });
                        _saveValues();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh,
                      color: AppTheme.subtext, size: 16),
                  const SizedBox(width: 8),
                  Text('Reset to defaults',
                      style: TextStyle(
                          color: AppTheme.subtext,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── BIPOLAR SLIDER ────────────────────────────────────────────────────────────
class _BipolarSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _BipolarSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<_BipolarSlider> createState() => _BipolarSliderState();
}

class _BipolarSliderState extends State<_BipolarSlider> {
  double? _dragging;

  double _calc(double dx, double width) {
    if (width <= 0) return widget.value;
    final ratio = (dx / width).clamp(0.0, 1.0);
    return widget.min + ratio * (widget.max - widget.min);
  }

  @override
  Widget build(BuildContext context) {
    final current = _dragging ?? widget.value;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            final v = _calc(d.localPosition.dx, width);
            setState(() => _dragging = v);
            widget.onChanged(v);
          },
          onHorizontalDragUpdate: (d) {
            final v = _calc(d.localPosition.dx, width);
            setState(() => _dragging = v);
            widget.onChanged(v);
          },
          onHorizontalDragEnd: (_) {
            widget.onChangeEnd(current);
            setState(() => _dragging = null);
          },
          onTapDown: (d) {
            final v = _calc(d.localPosition.dx, width);
            setState(() => _dragging = v);
            widget.onChanged(v);
            widget.onChangeEnd(v);
            setState(() => _dragging = null);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CustomPaint(
              size: Size(width, 28),
              painter: _BipolarSliderPainter(
                value: current.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BipolarSliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  const _BipolarSliderPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const trackH = 3.0;
    const thumbR = 8.0;
    final cy = size.height / 2;
    final range = max - min;
    if (range <= 0) return;

    final valueX = ((value - min) / range) * size.width;
    final zeroX =
        ((0.0 - min) / range).clamp(0.0, 1.0) * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - trackH / 2, size.width, trackH),
        const Radius.circular(2),
      ),
      Paint()..color = AppTheme.border,
    );

    final left  = valueX < zeroX ? valueX : zeroX;
    final right = valueX < zeroX ? zeroX  : valueX;
    if (right > left) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              left, cy - trackH / 2, right - left, trackH),
          const Radius.circular(2),
        ),
        Paint()..color = AppTheme.accent,
      );
    }

    canvas.drawLine(
      Offset(zeroX, cy - 6),
      Offset(zeroX, cy + 6),
      Paint()
        ..color = AppTheme.subtext
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(valueX, cy), thumbR + 4,
        Paint()..color = AppTheme.accent.withOpacity(0.15));
    canvas.drawCircle(Offset(valueX, cy), thumbR,
        Paint()..color = AppTheme.isDark
            ? const Color(0xFF1E2650)
            : const Color(0xFFE8EEFF));
    canvas.drawCircle(
      Offset(valueX, cy), thumbR,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(valueX, cy), thumbR * 0.3,
        Paint()..color = AppTheme.accent);
  }

  @override
  bool shouldRepaint(_BipolarSliderPainter old) =>
      old.value != value || old.min != min || old.max != max;
}

// ── VIDEO STREAM SERVICE ──────────────────────────────────────────────────────
class VideoStreamService {
  Socket? _socket;
  bool _running = false;
  final String ip;
  final int port;
  final void Function(Uint8List) onFrame;
  final void Function(bool) onConnectionChange;

  VideoStreamService({
    required this.ip,
    required this.port,
    required this.onFrame,
    required this.onConnectionChange,
  });

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 3));
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      _running = true;
      onConnectionChange(true);
      _listen();
    } catch (e) {
      onConnectionChange(false);
      debugPrint('Video connect error: $e');
    }
  }

  void _listen() async {
    final buffer = <int>[];
    await for (final chunk in _socket!) {
      if (!_running) break;
      buffer.addAll(chunk);
      while (buffer.length >= 2) {
        final frameSize = (buffer[0] << 8) | buffer[1];
        if (frameSize <= 0) {
          buffer.removeRange(0, 2);
          continue;
        }
        if (buffer.length < 2 + frameSize) break;
        final frameData =
        Uint8List.fromList(buffer.sublist(2, 2 + frameSize));
        buffer.removeRange(0, 2 + frameSize);
        onFrame(frameData);
      }
    }
  }

  void disconnect() {
    _running = false;
    _socket?.destroy();
    _socket = null;
    onConnectionChange(false);
  }
}

// ── MAIN DRONE CONTROLLER ─────────────────────────────────────────────────────
class DroneController extends StatefulWidget {
  const DroneController({super.key});
  @override
  State<DroneController> createState() => _DroneControllerState();
}

class _DroneControllerState extends State<DroneController> {

  static const _videoChannel =
  MethodChannel('com.quantumrobotix/video');
  int roll = 127, pitch = 127, throttle = 0, yaw = 127;

  double get rollDeg  => (roll  / 254.0) * 30.0 - 15.0;
  double get pitchDeg => (pitch / 254.0) * 30.0 - 15.0;
  double get yawDeg   => (yaw   / 254.0) * 180.0 - 90.0;
  int    get thrPct   => (throttle / 254.0 * 100).round();

  double p = 0.42, i = 0.001, d = 0.036, a = 15.0, rT = 0.0, pT = 0.0;

  bool isPaired        = false;
  bool isArmed         = false;
  bool serverError     = false;
  bool txError         = false;
  bool throttleError   = false;
  bool wifiError       = false;
  bool cameraEnabled   = false;
  bool cameraConnected = false;
  bool isRecording     = false;
  bool _showTutorial   = false;
  bool _isEncoding     = false;
  int _headless = 0;   // toggles between 0 and 1
  int _flip = 0;       // momentary 1 then back to 0
  bool _flipDisabled = false;
  Timer? _flipTimer;

  int _txFailCount = 0;
  static const int _maxTxFails = 10; // 10 consecutive fails = disconnected
  Timer? _heartbeatTimer;

  Uint8List? currentFrame;
  VideoStreamService? _videoService;
  IOSink? _videoSink;
  String? _rawVideoPath;
  int _frameWidth = 0;
  int _frameHeight = 0;

  Timer? _recordTimer;
  int _recordSeconds = 0;
  bool _isRecording = false;
  bool _isSaving = false;
  int _framesSent = 0;
  String? _recordingDir;
  int _frameIndex = 0;
  final List<int> _frameTimestamps = [];
  int _lastFrameTime = 0;


  final GlobalKey<_JoystickWidgetState> _leftJoystickKey = GlobalKey();

  RawDatagramSocket? socket;
  final String droneIp = '192.168.4.1';
  final int udpPort    = 12345;
  final int videoPort  = 55555;

  void _sendSafePacket() {
    if (socket == null) return;
    try {
      // All zeros: throttle=0, roll/pitch/yaw centred, all PID params zeroed
      const safeData = '127,127,0,127,0,0,0,0,0,0\n';
      socket!.send(
          safeData.codeUnits, InternetAddress(droneIp), udpPort);
      _DebugLog.add('✓ Safe packet sent');
    } catch (e) {
      _DebugLog.add('Safe packet send error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _DebugLog.init();
    _loadValues();
    _checkFirstLaunch();
    Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      if (result.contains(ConnectivityResult.wifi)) {
        setState(() => wifiError = false);
      }
    });
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('tutorialSeen') ?? false;
      if (!seen && mounted) {
        setState(() => _showTutorial = true);
      }
    } catch (_) {}
  }

  Future<void> _markTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorialSeen', true);
    } catch (_) {}
  }



  @override
  void dispose() {
    _saveValues();
    _heartbeatTimer?.cancel();
    socket?.close();
    _videoService?.disconnect();
    _recordTimer?.cancel();
    super.dispose();
    _flipTimer?.cancel();
  }

  Future<void> _loadValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        p  = prefs.getDouble('P')  ?? 0.56;
        i  = prefs.getDouble('I')  ?? 0.001;
        d  = prefs.getDouble('D')  ?? 0.056;
        a  = prefs.getDouble('A')  ?? 35.0;
        rT = prefs.getDouble('RT') ?? 0;
        pT = prefs.getDouble('PT') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _saveValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('P', p);
      await prefs.setDouble('I', i);
      await prefs.setDouble('D', d);
      await prefs.setDouble('A', a);
      await prefs.setDouble('RT', rT);
      await prefs.setDouble('PT', pT);
    } catch (_) {}
  }

  void sendData() {
    if (!isPaired) return;
    if (!isArmed) return;
    if (socket == null) return;
    try {

      final data =
          '$roll,$pitch,$throttle,$yaw,$p,$i,$d,$a,$rT,$pT,$_headless,$_flip\n';
      socket!.send(
          data.codeUnits, InternetAddress(droneIp), udpPort);
      if (mounted) setState(() => txError = false);
    } catch (e) {
      if (mounted) setState(() => txError = true);
    }
  }
  //Head and Flip

  void _toggleHeadless() {
    setState(() => _headless = _headless == 0 ? 1 : 0);
    sendData();
  }

  void _triggerFlip() {
    if (_flipDisabled) return;

    setState(() {
      _flip = 1;
      _flipDisabled = true;
    });
    sendData();

    // Reset flip back to 0 after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _flip = 0);
      sendData();
    });
    // Re-enable button after 5 seconds
    _flipTimer?.cancel();
    _flipTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _flipDisabled = false);
    });
  }

  Widget _buildFlightButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Headless button ──
        GestureDetector(
          onTap: _toggleHeadless,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _headless == 1
                  ? const Color(0xFF0A1628)
                  : AppTheme.isDark
                  ? const Color(0xFF11152A)
                  : const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _headless == 1
                    ? const Color(0xFF38BDF8)
                    : AppTheme.border,
                width: _headless == 1 ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore,
                  size: 13,
                  color: _headless == 1
                      ? const Color(0xFF38BDF8)
                      : AppTheme.subtext,
                ),
                const SizedBox(width: 5),
                Text(
                  _headless == 1 ? 'HEADLESS' : 'HEADLESS',
                  style: TextStyle(
                    color: _headless == 1
                        ? const Color(0xFF38BDF8)
                        : AppTheme.subtext,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ── Flip button — same style as headless ──
        GestureDetector(
          onTap: _flipDisabled ? null : _triggerFlip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _flip == 1
                  ? const Color(0xFF11152A)
                  : AppTheme.isDark
                  ? const Color(0xFF11152A)
                  : const Color(0xFFE8EEFF),

              borderRadius: BorderRadius.circular(20),

              border: Border.all(
                color: _flip == 1
                    ? const Color(0xFF38BDF8)
                    : AppTheme.border,

                width: _flip == 1 ? 2 : 1,
              ),

              boxShadow: _flip == 1
                  ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8)
                      .withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flip_camera_android,
                  size: 13,
                  color: _flip == 1
                      ? const Color(0xFF38BDF8)
                      : AppTheme.subtext,
                ),
                const SizedBox(width: 5),
                Text(
                  'FLIP',
                  style: TextStyle(
                    color: _flip == 1
                        ? const Color(0xFF38BDF8)
                        : AppTheme.subtext,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  void _handleDroneDisconnect() {
    if (!mounted) return;
    if (!isPaired) return; // Already unpaired
    _DebugLog.add('Drone disconnected — unpairing');
    _heartbeatTimer?.cancel();
    _disconnectCamera();
    socket?.close();
    socket = null;
    _txFailCount = 0;
    setState(() {
      isPaired      = false;
      isArmed       = false;
      txError       = false;
      wifiError     = false;
      cameraEnabled = false;
      throttle      = 0;
      roll          = 127;
      pitch         = 127;
      yaw           = 127;
    });
    // Reset joystick
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leftJoystickKey.currentState?.resetToInitial();
    });
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Drone disconnected'),
          ],
        ),
        backgroundColor: const Color(0xFFFF5757),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Send a heartbeat packet every 2 seconds when paired but not armed
    // This lets us detect connection loss even when not actively flying
    _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 2), (_) {
      if (!isPaired || isArmed) return; // armed state uses sendData
      if (socket == null) return;
      try {
        // Send neutral safe packet as heartbeat
        const heartbeat =
            '127,127,0,127,0,0,0,0,0,0\n';
        socket!.send(
          heartbeat.codeUnits,
          InternetAddress(droneIp),
          udpPort,
        );
        _txFailCount = 0;
        if (mounted && txError) setState(() => txError = false);
      } catch (e) {
        _txFailCount++;
        _DebugLog.add('Heartbeat fail $_txFailCount');
        if (_txFailCount >= _maxTxFails) {
          _handleDroneDisconnect();
        }
      }
    });
  }

  void togglePair() async {
    if (isArmed) return;
    if (isPaired) {
      _heartbeatTimer?.cancel();
      _disconnectCamera();
      setState(() {
        isPaired      = false;
        serverError   = false;
        txError       = false;
        throttleError = false;
        wifiError     = false;
        cameraEnabled = false;
      });
      socket?.close();
      socket = null;
      return;
    }

    // Step 1 — Check Wi-Fi is connected at all
    final result = await Connectivity().checkConnectivity();
    if (!result.contains(ConnectivityResult.wifi)) {
      if (!mounted) return;
      setState(() { wifiError = true; serverError = false; });
      return;
    }

    if (!mounted) return;
    setState(() {
      wifiError   = false;
      serverError = false;
      txError     = false;
      throttleError = false;
    });

    // Step 2 — Passive check only: inspect phone's own IP address
    // The drone AP always assigns phone IPs in the 192.168.4.x subnet
    // We NEVER send any data to the drone during this check
    _DebugLog.add('Checking network interface for drone subnet...');

    bool onDroneNetwork = false;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          _DebugLog.add('Interface ${iface.name}: ${addr.address}');
          if (addr.address.startsWith('192.168.4.')) {
            onDroneNetwork = true;
            _DebugLog.add('✓ Drone subnet confirmed: ${addr.address}');
            break;
          }
        }
        if (onDroneNetwork) break;
      }
    } catch (e) {
      _DebugLog.add('Interface check error: $e');
      onDroneNetwork = false;
    }

    if (!onDroneNetwork) {
      if (!mounted) return;
      setState(() => wifiError = true);
      _showDroneWifiDialog();
      return;
    }

    // Step 3 — Bind UDP socket only — send NO data yet
    // Data is only sent when armed via sendData()
    try {
      socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (!mounted) return;
      setState(() {
        isPaired    = true;
        isArmed     = false;
        throttle    = 0;
        roll        = 127;
        pitch       = 127;
        yaw         = 127;
        wifiError   = false;
        serverError = false;
        txError     = false;
      });
      _txFailCount = 0;
      _startHeartbeat();
      _DebugLog.add('✓ Paired — socket bound, no data sent');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _leftJoystickKey.currentState?.resetToInitial();
      });
    } catch (e) {
      _DebugLog.add('Socket bind error: $e');
      if (!mounted) return;
      setState(() => serverError = true);
    }
  }

  void _showDroneWifiDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Color(0xFFFF5757), size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text('Drone Wi-Fi not detected',
                  style: TextStyle(color: Color(0xFFFF5757))),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are connected to a Wi-Fi network which does not belong to the drone',
              style: TextStyle(color: AppTheme.text, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.isDark
                    ? const Color(0xFF0E1830)
                    : const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To connect:',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _StepRow(
                      number: '1',
                      text: 'Power on your QR drone'),
                  _StepRow(
                      number: '2',
                      text: 'Go to phone Settings → Wi-Fi'),
                  _StepRow(
                      number: '3',
                      text:
                      'Connect to the drone\'s Wi-Fi network'),
                  _StepRow(
                      number: '4',
                      text: 'Return here and tap PAIR'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void toggleArm() {
    if (!isPaired) return;
    if (!isArmed && throttle > 25) {
      setState(() => throttleError = true);
      return;
    }
    setState(() { isArmed = !isArmed; throttleError = false; });
    if (isArmed) {
      // Armed — heartbeat not needed, sendData handles detection
      _heartbeatTimer?.cancel();
    } else {
      // Disarmed — restart heartbeat to detect disconnection
      _startHeartbeat();
    }
  }

  void toggleCamera() async {
    if (!isPaired) return;
    if (cameraEnabled) {
      _disconnectCamera();
      setState(() { cameraEnabled = false; currentFrame = null; });
      return;
    }
    setState(() => cameraEnabled = true);
    _videoService = VideoStreamService(
      ip: droneIp,
      port: videoPort,
// ── Replace the onFrame section in toggleCamera ──
      onFrame: (frameData) {
        if (!mounted) return;
        setState(() => currentFrame = frameData);

        // Send to native encoder — every 2nd frame = 15fps
        if (isRecording && !_isSaving) {
          _framesSent++;
          if (_framesSent % 2 != 0) return;
          // Fire and forget — don't await
          _videoChannel.invokeMethod('addFrame', {
            'bytes': Uint8List.fromList(frameData),
          }).catchError((e) {
            _DebugLog.add('Frame send error: $e');
          });
        }
      },
      onConnectionChange: (connected) {
        if (!mounted) return;
        setState(() => cameraConnected = connected);
        if (!connected && cameraEnabled) {
          setState(() => cameraEnabled = false);
        }
      },
    );
    await _videoService!.connect();
  }

  void _disconnectCamera() {
    if (isRecording) _stopRecording();
    _videoService?.disconnect();
    _videoService = null;
    if (mounted) setState(() => cameraConnected = false);
  }

  void toggleRecording() {
    if (!cameraEnabled || !cameraConnected) return;
    isRecording ? _stopRecording() : _startRecording();
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new,
                color: Color(0xFFFF5757), size: 22),
            SizedBox(width: 8),
            Text('Close app?',
                style: TextStyle(color: Color(0xFFFF5757))),
          ],
        ),
        content: Text(
          isArmed
              ? 'The drone is currently ARMED.\n\nPlease disarm before closing for safe motor shutdown.'
              : isPaired
              ? 'This will disconnect from the drone and close the app.'
              : 'Close QR Drone Controller?',
          style: TextStyle(color: AppTheme.text, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.subtext)),
          ),
          if (isArmed)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5C842),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  isArmed = false;
                  throttleError = false;
                });
                Future.delayed(const Duration(milliseconds: 300),
                        () => _confirmClose(context));
              },
              child: const Text('Disarm first',
                  style: TextStyle(color: Colors.black)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5757),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _disconnectCamera();
              _sendSafePacket();
              socket?.close();
              socket = null;
              SystemNavigator.pop();
            },
            child: Text(
              isArmed ? 'Force close' : 'Close',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _startRecording() async {
    if (_isSaving) {
      _showError('Please wait for previous video to finish.');
      return;
    }
    try {
      _DebugLog.add('Starting native recording...');

      // Get frame dimensions from current frame
      int width = 640;
      int height = 480;
      if (currentFrame != null) {
        try {
          final codec = await instantiateImageCodec(currentFrame!);
          final frame = await codec.getNextFrame();
          width = frame.image.width;
          height = frame.image.height;
          frame.image.dispose();
          codec.dispose();
        } catch (_) {}
      }

      await _videoChannel.invokeMethod('startRecording', {
        'width': width,
        'height': height,
      });

      _framesSent = 0;
      _recordSeconds = 0;

      if (!mounted) return;
      setState(() => isRecording = true);
      _DebugLog.add('✓ Native recording started ${width}x$height');

      _recordTimer =
          Timer.periodic(const Duration(seconds: 1), (t) {
            if (!mounted) { t.cancel(); return; }
            setState(() => _recordSeconds++);
          });
    } catch (e) {
      _DebugLog.add('Start error: $e');
      _showError('Failed to start recording: $e');
    }
  }

  void _stopRecording() async {
    _recordTimer?.cancel();
    if (!mounted) return;
    setState(() { isRecording = false; _isSaving = true; });

    _DebugLog.add('Stopping — frames sent: $_framesSent');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.accent),
              const SizedBox(width: 16),
              Text('Saving video...',
                  style: TextStyle(color: AppTheme.text)),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _videoChannel
          .invokeMethod<String>('stopRecording');
      _DebugLog.add('✓ Saved: $result');

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isSaving = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle,
                  color: Color(0xFF3DDA82), size: 22),
              SizedBox(width: 8),
              Text('Video saved!',
                  style: TextStyle(color: Color(0xFF3DDA82))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration: ${_formatTime(_recordSeconds)}',
                  style: TextStyle(
                      color: AppTheme.text, fontSize: 13)),
              Text('Frames: $_framesSent',
                  style: TextStyle(
                      color: AppTheme.text, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                'Saved to Gallery → QR Drone Controller',
                style: TextStyle(
                    color: AppTheme.accentLight, fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      _DebugLog.add('Stop error: $e');
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      setState(() => _isSaving = false);
      _showError('Failed to save: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFFF5757),
    ));
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final outerR = size.height * 0.36;
    final innerR = size.height * 0.12;
    final maxR   = outerR - innerR;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Main content ──
          Stack(
            children: [
              if (cameraEnabled && currentFrame != null)
                Positioned.fill(
                  child: Image.memory(currentFrame!,
                      fit: BoxFit.cover, gaplessPlayback: true),
                )
              else if (cameraEnabled &&
                  cameraConnected &&
                  currentFrame == null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: AppTheme.accent),
                          const SizedBox(height: 12),
                          Text('Waiting for feed...',
                              style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                )
              else if (cameraEnabled && !cameraConnected)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: const Center(
                        child: Text('Camera not available',
                            style: TextStyle(
                                color: Color(0xFFFF5757),
                                fontSize: 14)),
                      ),
                    ),
                  ),

              if (cameraEnabled)
                Positioned.fill(
                  child: Container(
                      color: Colors.black.withOpacity(0.25)),
                ),

              Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          left: size.width * 0.04,
                          top: size.height * 0.48 - outerR - 30,
                          child: JoystickWidget(
                            key: _leftJoystickKey,
                            outerRadius: outerR,
                            innerRadius: innerR,
                            initialOffset: Offset(0, maxR),
                            transparent: cameraEnabled,
                            onMove: (offset) {
                              setState(() {
                                yaw = (((offset.dx / maxR) + 1) /
                                    2 *
                                    254)
                                    .clamp(0, 254)
                                    .toInt();
                                throttle =
                                    (((-offset.dy / maxR) + 1) /
                                        2 *
                                        254)
                                        .clamp(0, 254)
                                        .toInt();
                                if (yaw > 114 && yaw < 140)
                                  yaw = 127;
                              });
                              sendData();
                            },
                            onRelease: () {
                              setState(() => yaw = 127);
                              sendData();
                            },
                            resetX: true,
                            resetY: false,
                          ),
                        ),

                        Positioned(
                          right: size.width * 0.04,
                          top: size.height * 0.48 - outerR - 30,
                          child: JoystickWidget(
                            outerRadius: outerR,
                            innerRadius: innerR,
                            transparent: cameraEnabled,
                            onMove: (offset) {
                              setState(() {
                                roll = (((offset.dx / maxR) + 1) /
                                    2 *
                                    254)
                                    .clamp(0, 254)
                                    .toInt();
                                pitch =
                                    (((-offset.dy / maxR) + 1) /
                                        2 *
                                        254)
                                        .clamp(0, 254)
                                        .toInt();
                                if (roll  > 120 && roll  < 134)
                                  roll  = 127;
                                if (pitch > 120 && pitch < 134)
                                  pitch = 127;
                              });
                              sendData();
                            },
                            onRelease: () {
                              setState(() {
                                roll = 127;
                                pitch = 127;
                              });
                              sendData();
                            },
                            resetX: true,
                            resetY: true,
                          ),
                        ),

                        if (!cameraEnabled)
                          Positioned(
                            top: 0,
                            bottom: size.height * 0.12,
                            left: size.width * 0.34,
                            right: size.width * 0.34,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _telemetryBox(
                                      'ROLL',
                                      '${rollDeg.toStringAsFixed(1)}°',
                                    ),
                                    _telemetryBox(
                                      'PITCH',
                                      '${pitchDeg.toStringAsFixed(1)}°',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _telemetryBox(
                                      'THR',
                                      '$thrPct%',
                                      highlight: true,
                                    ),
                                    _telemetryBox(
                                      'YAW',
                                      '${yawDeg.toStringAsFixed(1)}°',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        Positioned(
                          bottom: 70,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildFlightButtons(),
                          ),
                        ),

                        if (isRecording)
                          Positioned(
                            top: 8, left: 0, right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.red.withOpacity(0.85),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle,
                                        color: Colors.white,
                                        size: 10),
                                    const SizedBox(width: 6),
                                    Text(
                                      'REC  ${_formatTime(_recordSeconds)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Tutorial overlay ──
          if (_showTutorial)
            TutorialOverlay(
              onDone: () {
                setState(() => _showTutorial = false);
                _markTutorialSeen();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: cameraEnabled
          ? Colors.black.withOpacity(0.6)
          : AppTheme.surface,
      padding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        children: [
          // ── Close button ──
          GestureDetector(
            onTap: () => _confirmClose(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1010),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFF5757)),
              ),
              child: const Icon(Icons.power_settings_new,
                  color: Color(0xFFFF5757), size: 18),
            ),
          ),

          // PAIR
          GestureDetector(
            onTap: togglePair,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: wifiError
                    ? const Color(0xFF3A2E00)
                    : isPaired
                    ? const Color(0xFF0E2E1A)
                    : const Color(0xFF3A1010),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: wifiError
                      ? const Color(0xFFF5C842)
                      : isPaired
                      ? const Color(0xFF3DDA82)
                      : const Color(0xFFFF5757),
                ),
              ),
              child: Text(
                wifiError
                    ? 'NO WIFI'
                    : isPaired ? 'PAIRED' : 'PAIR',
                style: TextStyle(
                  color: wifiError
                      ? const Color(0xFFF5C842)
                      : isPaired
                      ? const Color(0xFF3DDA82)
                      : const Color(0xFFFF5757),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          if (isPaired) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: toggleArm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isArmed
                      ? const Color(0xFF0E2E1A)
                      : const Color(0xFF3A1010),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isArmed
                        ? const Color(0xFF3DDA82)
                        : const Color(0xFFFF5757),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isArmed ? 'ARMED' : 'ARM',
                  style: TextStyle(
                    color: isArmed
                        ? const Color(0xFF3DDA82)
                        : const Color(0xFFFF5757),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],

          if (wifiError)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                isPaired ? 'Connect to Drone WiFi' : 'Connect to Drone WiFi',
                style: const TextStyle(
                    color: Color(0xFFF5C842),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            )
          else if (throttleError && throttle > 25)
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text('Lower throttle to ARM',
                  style: TextStyle(
                      color: Color(0xFFF5C842), fontSize: 11)),
            )
          else if (serverError)
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text('Server not available',
                    style: TextStyle(
                        color: Color(0xFFFF5757), fontSize: 11)),
              )
            else if (txError)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text('Transmission error',
                      style: TextStyle(
                          color: Color(0xFFFF5757), fontSize: 11)),
                ),

          const Spacer(),

          if (cameraEnabled)
            GestureDetector(
              onTap: toggleRecording,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isRecording
                      ? Colors.red.withOpacity(0.2)
                      : AppTheme.isDark
                      ? const Color(0xFF1A2040)
                      : const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isRecording
                        ? Colors.red
                        : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRecording
                          ? Icons.stop
                          : Icons.fiber_manual_record,
                      color: isRecording
                          ? Colors.red
                          : const Color(0xFFFF5757),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRecording
                          ? 'Stop  ${_formatTime(_recordSeconds)}'
                          : 'Record',
                      style: TextStyle(
                        color: isRecording
                            ? Colors.red
                            : const Color(0xFFFF5757),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isPaired)
            GestureDetector(
              onTap: toggleCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: cameraEnabled
                      ? const Color(0xFF0E2E1A)
                      : const Color(0xFF3A1010),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cameraEnabled
                        ? const Color(0xFF3DDA82)
                        : const Color(0xFFFF5757),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cameraEnabled
                          ? Icons.videocam
                          : Icons.videocam_off,
                      color: cameraEnabled
                          ? const Color(0xFF3DDA82)
                          : const Color(0xFFFF5757),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cameraEnabled ? 'Cam ON' : 'Cam OFF',
                      style: TextStyle(
                        color: cameraEnabled
                            ? const Color(0xFF3DDA82)
                            : const Color(0xFFFF5757),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          //Debug log button
          GestureDetector(
            onTap: () async {
              final allLogs = await _DebugLog.getAll();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF0A0E1A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  title: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Debug Log',
                          style: TextStyle(
                              color: Color(0xFF5A7AFF),
                              fontSize: 14)),
                      TextButton(
                        onPressed: () async {
                          await _DebugLog.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear',
                            style: TextStyle(
                                color: Color(0xFFFF5757),
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 350,
                    child: allLogs.isEmpty
                        ? const Center(
                        child: Text('No logs',
                            style: TextStyle(
                                color: Color(0xFF4A5A88))))
                        : ListView.builder(
                      reverse: true,
                      itemCount: allLogs.length,
                      itemBuilder: (_, i) {
                        final log = allLogs[
                        allLogs.length - 1 - i];
                        Color c = const Color(0xFFD0D8FF);
                        if (log.contains('ERROR') ||
                            log.contains('FAILED') ||
                            log.contains('Exception')) {
                          c = const Color(0xFFFF5757);
                        } else if (log.contains('✓') ||
                            log.contains('COMPLETE')) {
                          c = const Color(0xFF3DDA82);
                        } else if (log.contains('FFmpeg')) {
                          c = const Color(0xFFF5C842);
                        } else if (log.contains('===')) {
                          c = const Color(0xFF5A7AFF);
                        }
                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 2),
                          child: Text(log,
                              style: TextStyle(
                                  color: c,
                                  fontSize: 10,
                                  fontFamily: 'monospace')),
                        );
                      },
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A7AFF),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 4),
              child: Icon(Icons.bug_report,
                  color: AppTheme.subtext, size: 20),
            ),
          ),

          // Settings
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  isPaired: isPaired,
                  isArmed: isArmed,
                  droneSocket: socket,
                ),
              ),
            ).then((result) {
              _loadValues();
              if (result == 'showTutorial' && mounted) {
                setState(() => _showTutorial = true);
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.settings,
                  color: AppTheme.accentLight, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetryBox(String label, String value,
      {bool highlight = false}) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cameraEnabled
            ? Colors.black.withOpacity(0.5)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.subtext, fontSize: 9)),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFFF5C842)
                  : AppTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── FLIP COUNTDOWN ────────────────────────────────────────────────────────────
class _FlipCountdown extends StatefulWidget {
  final int seconds;
  final Color color;
  const _FlipCountdown({super.key, required this.seconds, required this.color});
  @override
  State<_FlipCountdown> createState() => _FlipCountdownState();
}

class _FlipCountdownState extends State<_FlipCountdown> {
  late int _remaining;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Text(
    '${_remaining}s',
    style: TextStyle(
        color: widget.color, fontSize: 9, fontFamily: 'monospace'),
  );
}

// ── JOYSTICK WIDGET ───────────────────────────────────────────────────────────
class JoystickWidget extends StatefulWidget {
  final double outerRadius;
  final double innerRadius;
  final Offset? initialOffset;
  final ValueChanged<Offset> onMove;
  final VoidCallback onRelease;
  final bool resetX;
  final bool resetY;
  final bool transparent;

  const JoystickWidget({
    super.key,
    required this.outerRadius,
    required this.innerRadius,
    required this.onMove,
    required this.onRelease,
    this.initialOffset,
    this.resetX = true,
    this.resetY = true,
    this.transparent = false,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  late Offset _thumbPos;

  @override
  void initState() {
    super.initState();
    _thumbPos = widget.initialOffset ?? Offset.zero;
  }

  void resetToInitial() {
    setState(() {
      _thumbPos = widget.initialOffset ?? Offset.zero;
    });
  }

  void _updatePosition(Offset localPos) {
    final center = Offset(widget.outerRadius, widget.outerRadius);
    final delta = localPos - center;
    final maxR = widget.outerRadius - widget.innerRadius;
    final clamped = delta.distance > maxR
        ? Offset.fromDirection(delta.direction, maxR)
        : delta;
    setState(() => _thumbPos = clamped);
    widget.onMove(clamped);
  }

  void _release() {
    setState(() {
      _thumbPos = Offset(
        widget.resetX ? 0 : _thumbPos.dx,
        widget.resetY ? 0 : _thumbPos.dy,
      );
    });
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.outerRadius * 2;
    final center = Offset(widget.outerRadius, widget.outerRadius);
    final thumbCenter = center + _thumbPos;

    return GestureDetector(
      onPanStart:  (d) => _updatePosition(d.localPosition),
      onPanUpdate: (d) => _updatePosition(d.localPosition),
      onPanEnd:    (_) => _release(),
      child: CustomPaint(
        size: Size(size, size),
        painter: _JoystickPainter(
          outerRadius: widget.outerRadius,
          innerRadius: widget.innerRadius,
          thumbCenter: thumbCenter,
          transparent: widget.transparent,
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppTheme.text, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
class _JoystickPainter extends CustomPainter {
  final double outerRadius;
  final double innerRadius;
  final Offset thumbCenter;
  final bool transparent;

  _JoystickPainter({
    required this.outerRadius,
    required this.innerRadius,
    required this.thumbCenter,
    this.transparent = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(outerRadius, outerRadius);
    final bool isDark = AppTheme.isDark;

    canvas.drawCircle(center, outerRadius,
        Paint()
          ..color = transparent
              ? const Color(0x22111520)
              : (isDark
              ? const Color(0xFF11152A)
              : const Color(0xFFEEF0FA)));
    canvas.drawCircle(center, outerRadius,
        Paint()
          ..color = AppTheme.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
    );

    final crossPaint = Paint()
      ..color = transparent
          ? const Color(0x331E2840)
          : (isDark
          ? const Color(0xFF1E2840)
          : const Color(0xFFCDD3ED))
      ..strokeWidth = 1;
    canvas.drawLine(Offset(10, outerRadius),
        Offset(size.width - 10, outerRadius), crossPaint);
    canvas.drawLine(Offset(outerRadius, 10),
        Offset(outerRadius, size.height - 10), crossPaint);

    canvas.drawCircle(center, outerRadius * 0.6,
        Paint()
          ..color = transparent
              ? const Color(0x331E2840)
              : (isDark
              ? const Color(0xFF1E2840)
              : const Color(0xFFCDD3ED))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    canvas.drawCircle(thumbCenter, innerRadius,
        Paint()
          ..color = transparent
              ? const Color(0x441E2650)
              : (isDark
              ? const Color(0xFF1E2650)
              : const Color(0xFFD0D8FF)));
    canvas.drawCircle(thumbCenter, innerRadius,
        Paint()
          ..color = transparent
              ? const Color(0xAA5A7AFF)
              : AppTheme.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(thumbCenter, innerRadius * 0.18,
        Paint()
          ..color = transparent
              ? const Color(0xAA5A7AFF)
              : AppTheme.accent);
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.thumbCenter != thumbCenter ||
          old.transparent != transparent;
}

// ── EXTENSION ─────────────────────────────────────────────────────────────────
extension TakeLastExt<T> on List<T> {
  List<T> takeLast(int n) =>
      length <= n ? List.from(this) : sublist(length - n);
}

// ── DEBUG LOG (file-persistent) ───────────────────────────────────────────────
class _DebugLog {
  static String? _logPath;
  static final List<String> _memLogs = [];

  static Future<void> init() async {
    try {
      const dir =
          '/data/data/com.quantumrobotix.qrdronecontroller/cache';
      await Directory(dir).create(recursive: true);
      _logPath = '$dir/drone_debug.log';
      final f = File(_logPath!);
      if (await f.exists()) {
        final lines = await f.readAsLines();
        if (lines.length > 200) {
          await f.writeAsString(
              lines.skip(lines.length - 200).join('\n') + '\n');
        }
        _memLogs.addAll(lines.takeLast(50));
      }
      add('=== APP STARTED ===');
    } catch (e) {
      debugPrint('Log init failed: $e');
    }
  }

  static void add(String msg) {
    final time = DateTime.now().toString().substring(11, 19);
    final line = '[$time] $msg';
    _memLogs.add(line);
    if (_memLogs.length > 100) _memLogs.removeAt(0);
    debugPrint(line);
    if (_logPath != null) {
      File(_logPath!).writeAsString('$line\n',
          mode: FileMode.append,
          flush: true).catchError((e) {
        debugPrint('Log write error: $e');
      });
    }
  }

  static Future<List<String>> getAll() async {
    if (_logPath == null) return List.from(_memLogs);
    try {
      final f = File(_logPath!);
      if (await f.exists()) {
        return await f.readAsLines();
      }
    } catch (_) {}
    return List.from(_memLogs);
  }

  static Future<void> clear() async {
    _memLogs.clear();
    if (_logPath != null) {
      try { await File(_logPath!).writeAsString(''); } catch (_) {}
    }
  }

  static List<String> get logs => List.from(_memLogs);
}


// 4114 - colour