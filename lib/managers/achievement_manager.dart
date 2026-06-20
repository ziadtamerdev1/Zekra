import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class AchievementManager {
  static final List<Map<String, dynamic>> _definitions = [
    {
      "id": "first_tasbeeh",
      "title": "أول تسبيحة",
      "desc": "أتممت أول 33 تسبيحة"
    },
    {
      "id": "t1000",
      "title": "ألف تسبيحة",
      "desc": "أكملت 1000 تسبيحة إجمالاً"
    },
    {
      "id": "morning7",
      "title": "صباح الخير",
      "desc": "أتممت أذكار الصباح 7 أيام متتالية"
    },
    {
      "id": "evening7",
      "title": "مساء النور",
      "desc": "أتممت أذكار المساء 7 أيام متتالية"
    },
    {
      "id": "all_azkar",
      "title": "الورد المتكامل",
      "desc": "أتممت الصباح والمساء في نفس اليوم"
    },
    {
      "id": "prayer_reader",
      "title": "قارئ الأدعية",
      "desc": "فتحت 10 أدعية مختلفة"
    },
  ];

  static Future<List<Achievement>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return _definitions.map((a) {
      final unlocked = prefs.getBool('ach_${a['id']}') ?? false;
      return Achievement(
        id: a['id'] as String,
        title: a['title'] as String,
        description: a['desc'] as String,
        unlocked: unlocked,
      );
    }).toList();
  }

  static Future<void> checkAndUnlock(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('ach_$achievementId') ?? false;
    if (!already) {
      await prefs.setBool('ach_$achievementId', true);
    }
  }

  static Future<void> onTasbeehIncrement(int totalCount) async {
    if (totalCount >= 33) await checkAndUnlock('first_tasbeeh');
    if (totalCount >= 1000) await checkAndUnlock('t1000');
  }
}