import 'package:flutter/material.dart';
import '../managers/achievement_manager.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنجازات'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Achievement>>(
        future: AchievementManager.getAchievements(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5D4037)),
            );
          }
          final achievements = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (ctx, i) {
              final a = achievements[i];
              return Card(
                color: a.unlocked ? Colors.green.shade50 : Colors.grey.shade200,
                child: ListTile(
                  leading: Icon(
                    a.unlocked ? Icons.emoji_events : Icons.lock,
                    color: a.unlocked ? Colors.amber : Colors.grey,
                  ),
                  title: Text(a.title),
                  subtitle: Text(a.description),
                ),
              );
            },
          );
        },
      ),
    );
  }
}