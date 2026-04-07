import 'dart:async';

import 'package:flutter/material.dart';

import '../zombie_survival_game.dart';

class HudOverlay extends StatefulWidget {
  const HudOverlay({required this.game, super.key});

  static const String id = 'hud';
  final ZombieSurvivalGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final hpPercent = (game.player.currentHp / game.player.maxHp).clamp(0, 1).toDouble();
    final expPercent = (game.exp / game.expToNextLevel).clamp(0, 1).toDouble();

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        width: 260,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day: ${game.day}', style: const TextStyle(color: Colors.white)),
            Text('Level: ${game.level}', style: const TextStyle(color: Colors.white)),
            Text('Kills: ${game.kills}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            const Text('HP', style: TextStyle(color: Colors.white)),
            LinearProgressIndicator(value: hpPercent, minHeight: 8),
            const SizedBox(height: 8),
            const Text('EXP', style: TextStyle(color: Colors.white)),
            LinearProgressIndicator(value: expPercent, minHeight: 8, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              'Day Time Left: ${game.daySystem.timeLeft.clamp(0, 999).toStringAsFixed(1)}s',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
