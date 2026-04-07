import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zombie_survival_game.dart';

class ControlsOverlay extends StatefulWidget {
  const ControlsOverlay({required this.game, super.key});

  static const String id = 'controls';
  final ZombieSurvivalGame game;

  @override
  State<ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<ControlsOverlay> {
  @override
  void dispose() {
    widget.game.setMoveDirection(Vector2.zero());
    widget.game.setAimDirection(Vector2.zero());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.game.isGameOver || widget.game.isPausedForLevelUp,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Joystick(
                label: 'MOVE',
                onDirection: widget.game.setMoveDirection,
              ),
              _Joystick(
                label: 'AIM',
                onDirection: widget.game.setAimDirection,
                color: const Color(0x44FF7043),
                knobColor: const Color(0xFFFF7043),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Joystick extends StatefulWidget {
  const _Joystick({
    required this.label,
    required this.onDirection,
    this.color = const Color(0x443FA7F5),
    this.knobColor = const Color(0xFF42A5F5),
  });

  final String label;
  final ValueChanged<Vector2> onDirection;
  final Color color;
  final Color knobColor;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double baseSize = 130;
  static const double knobSize = 52;
  Offset knobOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: SizedBox(
        width: baseSize,
        height: baseSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
            Positioned(
              left: (baseSize - knobSize) / 2 + knobOffset.dx,
              top: (baseSize - knobSize) / 2 + knobOffset.dy,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.knobColor),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Text(
                widget.label,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _handleGlobal(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _handleGlobal(details.globalPosition);
  }

  void _handleGlobal(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);
    final center = const Offset(baseSize / 2, baseSize / 2);
    var delta = local - center;

    final maxRadius = (baseSize - knobSize) / 2;
    if (delta.distance > maxRadius) {
      final scale = maxRadius / delta.distance;
      delta = Offset(delta.dx * scale, delta.dy * scale);
    }

    setState(() {
      knobOffset = delta;
    });

    final direction = Vector2(delta.dx, delta.dy);
    if (direction.length2 > 0) {
      widget.onDirection(direction.normalized());
    }
  }

  void _release() {
    setState(() {
      knobOffset = Offset.zero;
    });
    widget.onDirection(Vector2.zero());
  }
}
