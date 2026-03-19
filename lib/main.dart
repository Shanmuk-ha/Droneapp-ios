import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const DroneApp());
}

class DroneApp extends StatelessWidget {
  const DroneApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DroneController(),
    );
  }
}

class DroneController extends StatefulWidget {
  const DroneController({super.key});
  @override
  State<DroneController> createState() => _DroneControllerState();
}

class _DroneControllerState extends State<DroneController> {
  int roll = 127, pitch = 127, throttle = 0, yaw = 127;
  double p = 0.85, i = 3.0, d = 0.06, a = 10.0, rT = 0.8, pT = 0.9;
  bool isPaired = false;
  bool isArmed = false;
  bool serverError = false;
  bool txError = false;
  bool throttleError = false;

  RawDatagramSocket? socket;
  final String droneIp = '192.168.4.1';
  final int port = 12345;

  @override
  void initState() {
    super.initState();
    loadValues();
  }

  @override
  void dispose() {
    saveValues();
    socket?.close();
    super.dispose();
  }

  Future<void> loadValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      p  = prefs.getDouble('P')  ?? 0.85;
      i  = prefs.getDouble('I')  ?? 3.0;
      d  = prefs.getDouble('D')  ?? 0.06;
      a  = prefs.getDouble('A')  ?? 10.0;
      rT = prefs.getDouble('RT') ?? 0.8;
      pT = prefs.getDouble('PT') ?? 0.9;
    });
  }

  Future<void> saveValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('P',  p);
    await prefs.setDouble('I',  i);
    await prefs.setDouble('D',  d);
    await prefs.setDouble('A',  a);
    await prefs.setDouble('RT', rT);
    await prefs.setDouble('PT', pT);
  }

  void sendData() {
    if (!isPaired || !isArmed || socket == null) return;
    try {
      final data = '$roll,$pitch,$throttle,$yaw,$p,$i,$d,$a,$rT,$pT\n';
      socket!.send(data.codeUnits, InternetAddress(droneIp), port);
      setState(() => txError = false);
    } catch (e) {
      setState(() => txError = true);
      debugPrint('Send error: $e');
    }
  }

  void togglePair() async {
    if (isArmed) return;
    setState(() {
      isPaired = !isPaired;
      serverError = false;
      txError = false;
      throttleError = false;
    });
    if (isPaired) {
      try {
        socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      } catch (e) {
        setState(() {
          isPaired = false;
          serverError = true;
        });
      }
    } else {
      socket?.close();
      socket = null;
    }
  }

  void toggleArm() {
    if (!isPaired) return;
    if (!isArmed && throttle > 25) {
      setState(() => throttleError = true);
      return;
    }
    setState(() {
      isArmed = !isArmed;
      throttleError = false;
    });
  }

  void editPID(String param, double currentValue) {
    if (isArmed) return;
    final controller =
    TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E2E),
        title: Text('Edit $param',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade800),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5A7AFF)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                setState(() {
                  switch (param) {
                    case 'P':  p  = val; break;
                    case 'I':  i  = val; break;
                    case 'D':  d  = val; break;
                    case 'A':  a  = val; break;
                    case 'R':  rT = val; break;
                    case 'Pt': pT = val; break;
                  }
                });
                saveValues();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set',
                style: TextStyle(color: Color(0xFF5A7AFF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final outerR = size.height * 0.36;
    final innerR = size.height * 0.12;
    final maxR   = outerR - innerR;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1E2E),
      body: Column(
        children: [
          _buildPIDBar(),
          Expanded(
            child: Stack(
              children: [
                // ── LEFT JOYSTICK — Throttle + Yaw ──
                Positioned(
                  left: size.width * 0.04,
                  top: size.height * 0.48 - outerR - 30,
                  child: JoystickWidget(
                    outerRadius: outerR,
                    innerRadius: innerR,
                    initialOffset: Offset(0, maxR),
                    onMove: (offset) {
                      setState(() {
                        yaw = (((offset.dx / maxR) + 1) / 2 * 255)
                            .clamp(0, 255).toInt();
                        throttle = (((-offset.dy / maxR) + 1) / 2 * 255)
                            .clamp(0, 255).toInt();
                        if (yaw > 115 && yaw < 140) yaw = 127;
                      });
                      sendData();
                    },
                    onRelease: () {
                      setState(() => yaw = 127);
                    },
                    resetX: true,
                    resetY: false,
                  ),
                ),

                // ── RIGHT JOYSTICK — Roll + Pitch ──
                Positioned(
                  right: size.width * 0.04,
                  top: size.height * 0.48 - outerR - 30,
                  child: JoystickWidget(
                    outerRadius: outerR,
                    innerRadius: innerR,
                    onMove: (offset) {
                      setState(() {
                        roll = (((offset.dx / maxR) + 1) / 2 * 255)
                            .clamp(0, 255).toInt();
                        pitch = (((-offset.dy / maxR) + 1) / 2 * 255)
                            .clamp(0, 255).toInt();
                        if (roll  > 120 && roll  < 135) roll  = 127;
                        if (pitch > 120 && pitch < 135) pitch = 127;
                      });
                      sendData();
                    },
                    onRelease: () {
                      setState(() {
                        roll  = 127;
                        pitch = 127;
                      });
                    },
                    resetX: true,
                    resetY: true,
                  ),
                ),

                // ── CENTER PANEL ──
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: size.width * 0.34,
                  right: size.width * 0.34,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // PAIR button
                      GestureDetector(
                        onTap: togglePair,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPaired
                                ? const Color(0xFF0E2E1A)
                                : const Color(0xFF3A1010),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPaired
                                  ? const Color(0xFF3DDA82)
                                  : const Color(0xFFFF5757),
                            ),
                          ),
                          child: Text(
                            isPaired ? 'PAIRED' : 'PAIR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isPaired
                                  ? const Color(0xFF3DDA82)
                                  : const Color(0xFFFF5757),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // Error messages
                      if (serverError)
                        const Text('Server\nNot Available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFFF5757),
                                fontSize: 12))
                      else if (txError)
                        const Text('Transmission\nError',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFFF5757),
                                fontSize: 12))
                      else if (throttleError && throttle > 25)
                          const Text('Lower Throttle\nto ARM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFFF5C842),
                                  fontSize: 12)),

                      // ARM button
                      if (isPaired)
                        GestureDetector(
                          onTap: toggleArm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: isArmed
                                  ? const Color(0xFF0E2E1A)
                                  : const Color(0xFF3A1010),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isArmed
                                    ? const Color(0xFF3DDA82)
                                    : const Color(0xFFFF5757),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              isArmed ? 'ARMED' : 'ARM',
                              style: TextStyle(
                                color: isArmed
                                    ? const Color(0xFF3DDA82)
                                    : const Color(0xFFFF5757),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),

                      // Telemetry
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              _telemetryBox('ROLL',  roll.toString()),
                              _telemetryBox('PITCH', pitch.toString()),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              _telemetryBox('THR', throttle.toString(),
                                  highlight: true),
                              _telemetryBox('YAW', yaw.toString()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPIDBar() {
    final params = ['P', 'I', 'D', 'A', 'R', 'Pt'];
    final values = [p, i, d, a, rT, pT];
    return Container(
      color: const Color(0xFF11152A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (idx) {
          return GestureDetector(
            onTap: () => editPID(params[idx], values[idx]),
            child: Container(
              width: 70,
              padding: const EdgeInsets.symmetric(
                  vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A3050)),
              ),
              child: Column(
                children: [
                  Text(params[idx],
                      style: const TextStyle(
                          color: Color(0xFF5A6A99), fontSize: 11)),
                  Text(
                    values[idx].toString(),
                    style: const TextStyle(
                        color: Color(0xFF7EB3FF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _telemetryBox(String label, String value,
      {bool highlight = false}) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF11152A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2840)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF3A4A70), fontSize: 9)),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFFF5C842)
                  : const Color(0xFF5A7AFF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── JOYSTICK WIDGET ──────────────────────────────────────────────────────────
class JoystickWidget extends StatefulWidget {
  final double outerRadius;
  final double innerRadius;
  final Offset? initialOffset;
  final ValueChanged<Offset> onMove;
  final VoidCallback onRelease;
  final bool resetX;
  final bool resetY;

  const JoystickWidget({
    super.key,
    required this.outerRadius,
    required this.innerRadius,
    required this.onMove,
    required this.onRelease,
    this.initialOffset,
    this.resetX = true,
    this.resetY = true,
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
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final double outerRadius;
  final double innerRadius;
  final Offset thumbCenter;

  _JoystickPainter({
    required this.outerRadius,
    required this.innerRadius,
    required this.thumbCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(outerRadius, outerRadius);

    // Outer circle
    canvas.drawCircle(center, outerRadius,
        Paint()..color = const Color(0xFF11152A));
    canvas.drawCircle(center, outerRadius,
        Paint()
          ..color = const Color(0xFF2E3A60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF1E2840)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(10, outerRadius),
        Offset(size.width - 10, outerRadius), crossPaint);
    canvas.drawLine(Offset(outerRadius, 10),
        Offset(outerRadius, size.height - 10), crossPaint);

    // Inner guide ring
    canvas.drawCircle(center, outerRadius * 0.6,
        Paint()
          ..color = const Color(0xFF1E2840)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Thumb
    canvas.drawCircle(thumbCenter, innerRadius,
        Paint()..color = const Color(0xFF1E2650));
    canvas.drawCircle(thumbCenter, innerRadius,
        Paint()
          ..color = const Color(0xFF5A7AFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(thumbCenter, innerRadius * 0.18,
        Paint()..color = const Color(0xFF5A7AFF));
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.thumbCenter != thumbCenter;
}