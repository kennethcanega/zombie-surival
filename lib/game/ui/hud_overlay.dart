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
        width: 280,
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
            Text('Money: \$${game.money}', style: const TextStyle(color: Colors.amberAccent)),
            Text('Weapon: ${game.player.currentWeapon.name}', style: const TextStyle(color: Colors.white)),
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
            const SizedBox(height: 10),
            _buildBuyWeaponButton(game),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyWeaponButton(ZombieSurvivalGame game) {
    if (!game.player.canUpgradeWeapon()) {
      return const Text('All guns unlocked', style: TextStyle(color: Colors.greenAccent));
    }

    final price = game.player.nextWeaponCost();
    final canAfford = game.money >= price;

    return ElevatedButton(
      onPressed: canAfford
          ? () {
              game.buyNextWeapon();
              setState(() {});
            }
          : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        backgroundColor: canAfford ? Colors.orange : Colors.grey,
      ),
      child: Text('Buy Next Gun (\$$price)'),
    );
  }
}
