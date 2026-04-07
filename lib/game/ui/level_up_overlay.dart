import 'package:flutter/material.dart';

import '../systems/upgrade.dart';
import '../zombie_survival_game.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({required this.game, super.key});

  static const String id = 'level_up';
  final ZombieSurvivalGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Level Up! Choose 1 Upgrade',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...game.currentUpgradeChoices.map(_buildUpgradeButton),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton(Upgrade upgrade) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () => game.applyUpgrade(upgrade),
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: Column(
          children: [
            Text(upgrade.title),
            Text(upgrade.description, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
