import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../managers/theme_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  String _currentName = 'ذاكر';
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'ذاكر';
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    setState(() {
      _currentName = name;
      _nameController.text = name;
      _isDark = isDark;
    });
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text.trim());
      setState(() => _currentName = _nameController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الاسم بنجاح')),
      );
    }
  }

  Future<void> _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إعادة الضبط'),
        content: const Text('هل تريد مسح جميع العدادات والإنجازات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key != 'user_name' &&
            key != 'is_dark_mode' &&
            key != 'is_first_time') {
          await prefs.remove(key);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح جميع العدادات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الاسم الظاهر',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'اكتب اسمك',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _saveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                    child: const Text('حفظ',
                        style: TextStyle(color: Color(0xFF5D4037))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text('الوضع الليلي',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تبديل المظهر إلى داكن'),
            value: _isDark,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_dark_mode', val);
              setState(() => _isDark = val);
              themeManager.toggleTheme(val);
            },
            activeColor: const Color(0xFFFFD700),
            secondary:
                const Icon(Icons.dark_mode, color: Color(0xFF5D4037)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
            title: const Text('إعادة ضبط جميع العدادات'),
            subtitle: const Text('مسح تقدم الأذكار والتسبيح والإنجازات'),
            onTap: _resetAllData,
          ),
        ],
      ),
    );
  }
}