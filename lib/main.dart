import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'managers/theme_manager.dart';
import 'services/notification_service.dart';
import 'managers/achievement_manager.dart';
import 'pages/settings_page.dart';
import 'pages/achievements_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.scheduleMorningEvening();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: ZekraApp(isFirstTime: isFirstTime),
    ),
  );
}

class ZekraApp extends StatelessWidget {
  final bool isFirstTime;
  const ZekraApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zekra',
          // فرض الاتجاه العربي RTL
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFFDF5E6),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5D4037),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFD700),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: themeManager.themeMode,
          home: isFirstTime ? const WelcomePage() : const MainNavigation(),
        );
      },
    );
  }
}

// ---------------------- MainNavigation ----------------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // مفتاح عام للتحكم في تبويبات الأذكار (صباح/مساء)
  final GlobalKey<AzkarPageState> _azkarPageKey = GlobalKey<AzkarPageState>();

  // التنقل إلى تبويب رئيسي
  void _onNavigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // التنقل لتبويب الأذكار مع فتح تبويب فرعي معين (0 صباح - 1 مساء)
  void _navigateToAzkarTab(int subIndex) {
    setState(() {
      _selectedIndex = 3; // تبويب الأذكار
    });
    // ننتظر لحظة حتى يتم بناء الـ widget ثم نغير التبويب الفرعي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _azkarPageKey.currentState?.switchTab(subIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(
        onNavigateToTab: _onNavigateToTab,
        onNavigateToAzkarTab: _navigateToAzkarTab,
      ),
      const CounterPage(),
      const PrayersPage(),
      AzkarPage(key: _azkarPageKey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ذِكْرَى",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5D4037),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF5D4037),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
          BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: "السبحة"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "الأدعية"),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "الأذكار",
          ),
        ],
      ),
    );
  }
}

// ---------------------- HomePage (معدلة) ----------------------
class HomePage extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;
  final ValueChanged<int> onNavigateToAzkarTab;
  const HomePage({
    super.key,
    required this.onNavigateToTab,
    required this.onNavigateToAzkarTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _dailyVerse = '';
  String _dailySurah = '';
  bool _verseLoaded = false;

  final List<Map<String, String>> _verses = const [
    {
      "text": "وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ",
      "surah": "الذاريات - 56"
    },
    {
      "text": "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
      "surah": "البقرة - 152"
    },
    {
      "text":
          "الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
      "surah": "الرعد - 28"
    },
    {
      "text": "وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ وَقَبْلَ غُرُوبِهَا",
      "surah": "طه - 130"
    },
    {
      "text": "يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا",
      "surah": "الأحزاب - 41"
    },
    {
      "text": "وَلَذِكْرُ اللَّهِ أَكْبَرُ ۗ وَاللَّهُ يَعْلَمُ مَا تَصْنَعُونَ",
      "surah": "العنكبوت - 45"
    },
    {
      "text": "فَإِذَا قَضَيْتُمُ الصَّلَاةَ فَاذْكُرُوا اللَّهَ قِيَامًا وَقُعُودًا وَعَلَىٰ جُنُوبِكُمْ",
      "surah": "النساء - 103"
    },
    {
      "text": "وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا",
      "surah": "الأحزاب - 35"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyVerse();
  }

  Future<void> _loadDailyVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    String savedDate = prefs.getString('verse_date') ?? '';
    int index;
    if (savedDate == today) {
      index = prefs.getInt('verse_index') ?? 0;
    } else {
      index = Random().nextInt(_verses.length);
      await prefs.setString('verse_date', today);
      await prefs.setInt('verse_index', index);
    }
    setState(() {
      _dailyVerse = _verses[index]['text']!;
      _dailySurah = _verses[index]['surah']!;
      _verseLoaded = true;
    });
  }

  Future<Map<String, dynamic>> _getStats() async {
    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString('user_name') ?? "ذاكر";

    int tasbeeh = prefs.getInt('free_tasbeeh_count') ?? 0;
    int morningProgress =
        await _calculateProgress(prefs, 'morning_azkar.json', 'morning_azkar');
    int eveningProgress =
        await _calculateProgress(prefs, 'evening_azkar.json', 'evening_azkar');

    return {
      'user_name': userName,
      'tasbeeh': tasbeeh,
      'morning': morningProgress,
      'evening': eveningProgress,
      'morning_total':
          await _getTotalCount('morning_azkar.json', 'morning_azkar'),
      'evening_total':
          await _getTotalCount('evening_azkar.json', 'evening_azkar'),
    };
  }

  Future<int> _calculateProgress(
      SharedPreferences prefs, String file, String key) async {
    try {
      final String response = await rootBundle.loadString('assets/$file');
      final data = json.decode(response);
      int completed = 0;
      for (var item in data[key]) {
        if ((prefs.getInt(item['id'].toString()) ?? 0) >= item['count']) {
          completed++;
        }
      }
      return completed;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalCount(String file, String key) async {
    try {
      final String response = await rootBundle.loadString('assets/$file');
      final data = json.decode(response);
      return (data[key] as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_verseLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5D4037)));
    }

    // ✅ أضفنا return هنا
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5D4037)),
          );
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "مرحباً بك يا ${stats['user_name']}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote,
                        color: Color(0xFFFFD700), size: 30),
                    const SizedBox(height: 15),
                    Text(
                      _dailyVerse,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _dailySurah,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Text(
                "متابعة الورد اليومي",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.9,
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigateToAzkarTab(0),
                    child: _buildStatCard(
                      "أذكار الصباح",
                      "${stats['morning']}/${stats['morning_total']}",
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigateToAzkarTab(1),
                    child: _buildStatCard(
                      "أذكار المساء",
                      "${stats['evening']}/${stats['evening_total']}",
                      Icons.nightlight_round,
                      Colors.indigo,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigateToTab(1),
                    child: _buildStatCard(
                      "التسبيح",
                      "${stats['tasbeeh']}",
                      Icons.fingerprint,
                      Colors.teal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsPage()),
                      );
                    },
                    child: _buildStatCard(
                      "الإعدادات",
                      "تخصيص",
                      Icons.settings,
                      Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- CounterPage (سبحة متطورة) ----------------------
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _freeCounter = 0; // العداد الحر

  // الأذكار الثابتة
  final List<String> _fixedAdhkar = [
    'سُبْحَانَ اللهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللهُ',
    'اللهُ أَكْبَرُ',
    'أَسْتَغْفِرُ اللهَ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ',
    'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
    'سُبْحَانَ اللهِ الْعَظِيمِ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
  ];

  Map<String, int> _counts = {};
  final int _target = 33;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _freeCounter = prefs.getInt('free_tasbeeh_count') ?? 0;
    Map<String, int> loaded = {};
    for (var dhikr in _fixedAdhkar) {
      loaded[dhikr] = prefs.getInt('tasbeeh_$dhikr') ?? 0;
    }
    if (mounted) {
      setState(() {
        _counts = loaded;
      });
    }
  }

  Future<void> _openFreeTasbeeh() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FreeTasbeehPage()),
    );
    // عند الرجوع نعيد تحميل العدد
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _freeCounter = prefs.getInt('free_tasbeeh_count') ?? 0;
    });
  }

  // أذكار ثابتة
  Future<void> _incrementFixed(String dhikr) async {
    if ((_counts[dhikr] ?? 0) < _target) {
      HapticFeedback.lightImpact();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _counts[dhikr] = (_counts[dhikr] ?? 0) + 1;
        prefs.setInt('tasbeeh_$dhikr', _counts[dhikr]!);
      });
    }
  }

  Future<void> _resetFixed(String dhikr) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counts[dhikr] = 0;
      prefs.setInt('tasbeeh_$dhikr', 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // بطاقة تسبيح حر
        GestureDetector(
          onTap: _openFreeTasbeeh,
          child: Card(
            margin: const EdgeInsets.all(15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تسبيح حر",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037)),
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFFD700),
                    radius: 25,
                    child: Text(
                      '$_freeCounter',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFFFD700)),
        // قائمة الأذكار الثابتة
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _fixedAdhkar.length,
            itemBuilder: (context, index) {
              final dhikr = _fixedAdhkar[index];
              final count = _counts[dhikr] ?? 0;
              final done = count >= _target;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                color: done ? Colors.green.shade50 : Colors.white,
                child: InkWell(
                  onTap: () => _incrementFixed(dhikr),
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dhikr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الهدف: $_target',
                                style: TextStyle(
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: done
                                  ? Colors.green
                                  : const Color(0xFFFFD700),
                              radius: 22,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.redAccent, size: 22),
                              onPressed: () => _resetFixed(dhikr),
                              tooltip: 'إعادة',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
// ---------------------- PrayersPage (مفضلة + مشاركة) ----------------------
class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});
  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage> {
  final List<Map<String, String>> _allPrayers = const [
    {
      "title": "دعاء استفتاح الصلاة",
      "content":
          "اللهم باعد بيني وبين خطاياي كما باعدت بين المشرق والمغرب، اللهم نقني من خطاياي كما ينقى الثوب الأبيض من الدنس.",
    },
    {
      "title": "دعاء الهم والحزن",
      "content":
          "اللهم إني أعوذ بك من الهم والحزن، والعجز والكسل، والبخل والجبن، وضلع الدين، وغلبة الرجال.",
    },
    {
      "title": "دعاء قضاء الدين",
      "content": "اللهم اكفني بحلالك عن حرامك، وأغنني بفضلك عمن سواك.",
    },
    {
      "title": "دعاء لراحة البال",
      "content":
          "اللهم إني أسألك النفس الطيبة التي تؤمن بلقائك، وترضى بقضائك، وتقنع بعطائك.",
    },
    {
      "title": "دعاء الهداية",
      "content": "اللهم اهدني وسددني، اللهم إني أسألك الهدى والسداد.",
    },
    {
      "title": "دعاء طلب العلم",
      "content": "اللهم انفعني بما علمتني، وعلمني ما ينفعني، وزدني علماً.",
    },
    {
      "title": "دعاء الكرب",
      "content":
          "لا إله إلا الله العظيم الحليم، لا إله إلا الله رب العرش العظيم، لا إله إلا الله رب السموات ورب الأرض.",
    },
    {
      "title": "دعاء تفريج الهم",
      "content":
          "يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين.",
    },
    {
      "title": "دعاء الشفاء",
      "content":
          "اللهم رب الناس، أذهب البأس، اشف أنت الشافي، لا شفاء إلا شفاؤك.",
    },
    {
      "title": "دعاء تيسير الأمور",
      "content":
          "اللهم لا سهل إلا ما جعلته سهلاً، وأنت تجعل الحزن إذا شئت سهلاً.",
    },
    {
      "title": "دعاء المغفرة",
      "content": "اللهم إنك عفو كريم تحب العفو فاعفُ عني.",
    },
    {"title": "دعاء الثبات", "content": "يا مقلب القلوب ثبت قلبي على دينك."},
    {
      "title": "دعاء الوالدين",
      "content": "رب اغفر لي ولوالدي، رب ارحمهما كما ربياني صغيراً.",
    },
    {
      "title": "دعاء الرزق",
      "content":
          "اللهم ارزقني رزقاً واسعاً حلالاً طيباً من غير كد، واستجب دعائي من غير رد.",
    },
    {
      "title": "دعاء ختم القرآن",
      "content": "اللهم ارحمني بالقرآن، واجعله لي إماماً ونوراً وهدى ورحمة.",
    },
    {
      "title": "دعاء الصباح",
      "content": "اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور.",
    },
    {
      "title": "دعاء المساء",
      "content": "اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير.",
    },
    {
      "title": "دعاء النوم",
      "content": "باسمك ربي وضعت جنبي وبك أرفعه، إن أمسكت نفسي فارحمها.",
    },
    {
      "title": "دعاء الاستيقاظ",
      "content": "الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور.",
    },
    {
      "title": "دعاء السفر",
      "content": "اللهم إنا نسألك في سفرنا هذا البر والتقوى ومن العمل ما ترضى.",
    },
    {
      "title": "دعاء دخول البيت",
      "content": "اللهم إني أسألك خير المولج وخير المخرج.",
    },
    {
      "title": "دعاء الخروج من البيت",
      "content": "بسم الله توكلت على الله ولا حول ولا قوة إلا بالله.",
    },
    {
      "title": "دعاء السوق",
      "content":
          "لا إله إلا الله وحده لا شريك له، له الملك وله الحمد يحيي ويميت وهو حي لا يموت.",
    },
    {
      "title": "دعاء لبس الثوب",
      "content":
          "الحمد لله الذي كساني هذا الثوب ورزقني اياه من غير حول مني ولا قوة.",
    },
    {
      "title": "دعاء الطعام",
      "content": "اللهم بارك لنا فيما رزقتنا وقنا عذاب النار، بسم الله.",
    },
    {
      "title": "دعاء الفراغ من الطعام",
      "content": "الحمد لله الذي أطعمني هذا ورزقنيه من غير حول مني ولا قوة.",
    },
    {
      "title": "دعاء دخول الخلاء",
      "content": "اللهم إني أعوذ بك من الخبث والخبائث.",
    },
    {"title": "دعاء الخروج من الخلاء", "content": "غفرانك."},
    {
      "title": "دعاء الوضوء",
      "content":
          "أشهد أن لا إله إلا الله وحده لا شريك له وأشهد أن محمداً عبده ورسوله.",
    },
    {"title": "دعاء نزول المطر", "content": "اللهم صيباً نافعاً."},
    {
      "title": "دعاء الرعد",
      "content": "سبحان الذي يسبح الرعد بحمده والملائكة من خيفته.",
    },
    {
      "title": "دعاء شدة الريح",
      "content": "اللهم إني أسألك خيرها وخير ما فيها وخير ما أرسلت به.",
    },
    {
      "title": "دعاء رؤية القمر",
      "content": "أعوذ بالله من شر هذا الغاسق إذا وقب.",
    },
    {
      "title": "دعاء ليلة القدر",
      "content": "اللهم إنك عفو تحب العفو فاعف عني.",
    },
    {
      "title": "دعاء يوم عرفة",
      "content":
          "لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.",
    },
    {
      "title": "دعاء زيارة القبور",
      "content":
          "السلام عليكم أهل الديار من المؤمنين والمسلمين، وإنا إن شاء الله بكم للاحقون.",
    },
    {
      "title": "دعاء التعزية",
      "content": "إن لله ما أخذ وله ما أعطى وكل شيء عنده بأجل مسمى.",
    },
    {
      "title": "دعاء صلاة الجنازة",
      "content": "اللهم اغفر لحينا وميتنا وشاهدنا وغائبنا وصغيرنا وكبيرنا.",
    },
    {
      "title": "دعاء ذبح الأضحية",
      "content": "بسم الله والله أكبر، اللهم هذا منك ولك.",
    },
    {
      "title": "دعاء إفطار الصائم",
      "content": "ذهب الظمأ وابتلت العروق وثبت الأجر إن شاء الله.",
    },
    {"title": "دعاء الغضب", "content": "أعوذ بالله من الشيطان الرجيم."},
    {
      "title": "دعاء من استصعب عليه أمر",
      "content":
          "اللهم لا سهل إلا ما جعلته سهلاً وأنت تجعل الحزن إذا شئت سهلاً.",
    },
    {
      "title": "دعاء صلاة الحاجة",
      "content": "لا إله إلا الله الحليم الكريم، سبحان الله رب العرش العظيم.",
    },
    {
      "title": "دعاء للمتزوجين",
      "content": "بارك الله لكما وبارك عليكما وجمع بينكما في خير.",
    },
    {
      "title": "دعاء المولود الجديد",
      "content": "بورك لك في الموهوب وشكرت الواهب وبلغ أشده ورزقت بره.",
    },
    {"title": "دعاء العطس", "content": "الحمد لله (ويرد عليه: يرحمكم الله)."},
    {"title": "دعاء صياح الديك", "content": "اللهم إني أسألك من فضلك."},
    {"title": "دعاء نهيق الحمار", "content": "أعوذ بالله من الشيطان الرجيم."},
    {"title": "دعاء نباح الكلاب", "content": "أعوذ بالله من الشيطان الرجيم."},
    {
      "title": "دعاء كفارة المجلس",
      "content":
          "سبحانك اللهم وبحمدك، أشهد أن لا إله إلا أنت أستغفرك وأتوب إليك.",
    },
    {"title": "دعاء من صنع إليك معروفاً", "content": "جزاك الله خيراً."},
    {
      "title": "دعاء حفظ النفس",
      "content": "تحصنت بذي العزة والجبروت، واعتصمت برب الملكوت.",
    },
    {
      "title": "دعاء الفزع في النوم",
      "content": "أعوذ بكلمات الله التامات من غضبه وعقابه وشر عباده.",
    },
    {
      "title": "دعاء الحماية من الدجال",
      "content": "اللهم إني أعوذ بك من فتنة المسيح الدجال.",
    },
    {
      "title": "دعاء الاستعاذة من عذاب القبر",
      "content": "اللهم إني أعوذ بك من عذاب القبر ومن عذاب جهنم.",
    },
    {
      "title": "دعاء تيسير الزواج",
      "content": "رب إني لما أنزلت إلي من خير فقير.",
    },
    {
      "title": "دعاء طلب الذرية",
      "content": "رب لا تذرني فرداً وأنت خير الوارثين.",
    },
    {
      "title": "دعاء للنجاح",
      "content": "اللهم إني أسألك فتوح العارفين وتوفيق الصالحين.",
    },
    {
      "title": "دعاء الامتحان",
      "content": "اللهم ذكرني ما نسيت وعلمني ما جهلت.",
    },
    {
      "title": "دعاء الشكر",
      "content": "اللهم أعني على ذكرك وشكرك وحسن عبادتك.",
    },
    {
      "title": "دعاء التوبة",
      "content": "اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك.",
    },
    {
      "title": "دعاء عند النظر في المرآة",
      "content": "اللهم كما حسنت خلقي فحسن خلقي.",
    },
    {
      "title": "دعاء عند سماع الأذان",
      "content": "اللهم رب هذه الدعوة التامة والصلاة القائمة.",
    },
    {"title": "دعاء بين السجدتين", "content": "رب اغفر لي، رب اغفر لي."},
    {
      "title": "دعاء سجود التلاوة",
      "content": "سجد وجهي للذي خلقه وشق سمعه وبصره بحوله وقوته.",
    },
    {
      "title": "دعاء صلاة الوتر",
      "content": "اللهم اهدني فيمن هديت وعافني فيمن عافيت.",
    },
    {
      "title": "دعاء القنوت",
      "content": "اللهم إنا نستعينك ونستغفرك ونثني عليك الخير.",
    },
    {
      "title": "دعاء يوم الجمعة",
      "content": "اللهم اجعل هذه الجمعة فرجاً لكل صابر واستجابة لكل دعاء.",
    },
    {
      "title": "دعاء بداية السنة",
      "content": "اللهم أدخله علينا بالأمن والإيمان والسلامة والإسلام.",
    },
    {
      "title": "دعاء نهاية السنة",
      "content":
          "اللهم ما عملت في هذه السنة مما نهيتني عنه ولم ترضه فنسألك المغفرة.",
    },
    {
      "title": "دعاء رؤية الكعبة",
      "content": "اللهم زد هذا البيت تشريفاً وتعظيماً وتكريماً.",
    },
    {
      "title": "دعاء الطواف",
      "content": "ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.",
    },
    {
      "title": "دعاء شرب ماء زمزم",
      "content": "اللهم إني أسألك علماً نافعاً ورزقاً واسعاً وشفاءً من كل داء.",
    },
    {
      "title": "دعاء الوقوف على الصفا والمروة",
      "content":
          "الله أكبر الله أكبر الله أكبر، لا إله إلا الله وحده لا شريك له.",
    },
    {
      "title": "دعاء دخول المدينة المنورة",
      "content": "اللهم اجعل لي بها قراراً ورزقاً حسناً.",
    },
    {
      "title": "دعاء لمن قال لك أحبك في الله",
      "content": "أحبك الذي أحببتني له.",
    },
    {
      "title": "دعاء لمن عرض عليك ماله",
      "content": "بارك الله لك في أهلك ومالك.",
    },
    {
      "title": "دعاء عند لقاء العدو",
      "content": "اللهم إنا نجعلك في نحورهم ونعوذ بك من شرورهم.",
    },
    {
      "title": "دعاء وسوسة الصلاة",
      "content": "أعوذ بالله من الشيطان الرجيم (واتفل عن يسارك ثلاثاً).",
    },
    {
      "title": "دعاء من أحس بوجع في جسده",
      "content":
          "ضع يدك على الذي تألم وقل: بسم الله (3) وأعوذ بعزة الله وقدرته (7).",
    },
    {
      "title": "دعاء الخوف من الشرك",
      "content":
          "اللهم إني أعوذ بك أن أشرك بك وأنا أعلم، وأستغفرك لما لا أعلم.",
    },
    {
      "title": "دعاء طرد الشيطان",
      "content": "أعوذ بكلمات الله التامات التي لا يجاوزهن بر ولا فاجر.",
    },
    {
      "title": "دعاء استيداع الأهل",
      "content": "أستودعكم الله الذي لا تضيع ودائعه.",
    },
    {
      "title": "دعاء ركوب الدابة",
      "content": "سبحان الذي سخر لنا هذا وما كنا له مقرنين.",
    },
    {
      "title": "دعاء المسافر للمقيم",
      "content": "أستودعك الله الذي لا تضيع ودائعه.",
    },
    {
      "title": "دعاء المقيم للمسافر",
      "content": "أستودع الله دينك وأمانتك وخواتيم عملك.",
    },
    {"title": "دعاء التكبير عند المرتفعات", "content": "الله أكبر."},
    {"title": "دعاء التسبيح عند المنحدرات", "content": "سبحان الله."},
    {
      "title": "دعاء إذا نزل منزلاً في سفر",
      "content": "أعوذ بكلمات الله التامات من شر ما خلق.",
    },
    {
      "title": "دعاء الرجوع من السفر",
      "content": "آيبون تائبون عابدون لربنا حامدون.",
    },
    {
      "title": "دعاء من أتاه أمر يسره",
      "content": "الحمد لله الذي بنعمته تتم الصالحات.",
    },
    {"title": "دعاء من أتاه أمر يكرهه", "content": "الحمد لله على كل حال."},
    {
      "title": "دعاء فضل الصلاة على النبي",
      "content": "اللهم صل وسلم على نبينا محمد.",
    },
    {
      "title": "دعاء إفشاء السلام",
      "content": "السلام عليكم ورحمة الله وبركاته.",
    },
    {
      "title": "دعاء سماع الديك في الليل",
      "content": "اللهم إني أسألك من فضلك.",
    },
  ];

  List<Map<String, String>> _filteredPrayers = [];
  int? _openTileIndex;
  Set<String> _favorites = {};

  @override
  void initState() {
    _filteredPrayers = _allPrayers;
    _loadFavorites();
    super.initState();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    _favorites = Set<String>.from(favList);
    setState(() {});
  }

  Future<void> _toggleFavorite(String title) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(title)) {
      _favorites.remove(title);
    } else {
      _favorites.add(title);
    }
    await prefs.setStringList('favorites', _favorites.toList());
    setState(() {});
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, String>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allPrayers;
    } else {
      results = _allPrayers
          .where((prayer) => prayer["title"]!.contains(enteredKeyword))
          .toList();
    }
    setState(() {
      _filteredPrayers = results;
      _openTileIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: TextField(
            onChanged: _runFilter,
            decoration: InputDecoration(
              labelText: 'ابحث عن دعاء...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _filteredPrayers.length,
            itemBuilder: (context, index) {
              final prayer = _filteredPrayers[index];
              final isFav = _favorites.contains(prayer['title']);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Color(0xFFFFD700)),
                ),
                child: ExpansionTile(
                  initiallyExpanded: index == _openTileIndex,
                  onExpansionChanged: (exp) =>
                      setState(() => _openTileIndex = exp ? index : null),
                  title: Text(
                    prayer['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFD700),
                    ),
                    onPressed: () => _toggleFavorite(prayer['title']!),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          Text(
                            prayer['content']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy,
                                    color: Color(0xFF5D4037)),
                                label: const Text('نسخ'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: prayer['content']!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('تم النسخ إلى الحافظة')),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.share,
                                    color: Color(0xFF5D4037)),
                                label: const Text('مشاركة'),
                                onPressed: () {
                                  final text =
                                      '${prayer['title']}\n${prayer['content']}';
                                  Share.share(text,
                                      subject: prayer['title']);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------- AzkarPage & AzkarListLoader ----------------------
class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => AzkarPageState();
}

class AzkarPageState extends State<AzkarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void switchTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF5D4037),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFFD700),
            labelColor: const Color(0xFFFFD700),
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.wb_sunny), text: "الصباح"),
              Tab(icon: Icon(Icons.nightlight_round), text: "المساء"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AzkarListLoader(
                  fileName: 'morning_azkar.json', dataKey: 'morning_azkar'),
              AzkarListLoader(
                  fileName: 'evening_azkar.json', dataKey: 'evening_azkar'),
            ],
          ),
        ),
      ],
    );
  }
}

class AzkarListLoader extends StatefulWidget {
  final String fileName;
  final String dataKey;
  const AzkarListLoader({
    super.key,
    required this.fileName,
    required this.dataKey,
  });
  @override
  State<AzkarListLoader> createState() => _AzkarListLoaderState();
}

class _AzkarListLoaderState extends State<AzkarListLoader> {
  List _items = [];
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/${widget.fileName}');
      final data = json.decode(response);
      final prefs = await SharedPreferences.getInstance();

      String timeKey = '${widget.dataKey}_last_reset';
      int lastReset = prefs.getInt(timeKey) ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch;
      bool isOverdue = (now - lastReset) > (6 * 60 * 60 * 1000);

      Map<String, int> savedCounts = {};
      for (var item in data[widget.dataKey]) {
        String id = item['id'].toString();
        if (isOverdue) {
          await prefs.setInt(id, 0);
          savedCounts[id] = 0;
        } else {
          savedCounts[id] = prefs.getInt(id) ?? 0;
        }
      }

      if (isOverdue) {
        await prefs.setInt(timeKey, now);
      }

      if (mounted) {
        setState(() {
          _items = data[widget.dataKey];
          _counts = savedCounts;
        });
      }
    } catch (e) {
      debugPrint("Data Loading Error: $e");
    }
  }

  Future<void> _increment(String id, int target) async {
    if ((_counts[id] ?? 0) < target) {
      HapticFeedback.selectionClick();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _counts[id] = (_counts[id] ?? 0) + 1;
        prefs.setInt(id, _counts[id]!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5D4037)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final id = item['id'].toString();
        final current = _counts[id] ?? 0;
        final target = item['count'];
        final isDone = current >= target;

        return GestureDetector(
          onTap: () => _increment(id, target),
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            color: isDone ? Colors.green.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: isDone ? Colors.green : const Color(0xFFFFD700),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    item['text'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDone
                          ? Colors.green.shade900
                          : const Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "الهدف: $target",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor:
                            isDone ? Colors.green : const Color(0xFFFFD700),
                        child: Text(
                          "$current",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
// ---------------------- صفحة التسبيح الحر ----------------------
class FreeTasbeehPage extends StatefulWidget {
  const FreeTasbeehPage({super.key});
  @override
  State<FreeTasbeehPage> createState() => _FreeTasbeehPageState();
}

class _FreeTasbeehPageState extends State<FreeTasbeehPage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('free_tasbeeh_count') ?? 0;
    });
  }

  String get _currentDhikr {
    int cycle = (_counter ~/ 30) % 4;
    switch (cycle) {
      case 0:
        return "سُبْحَانَ اللهِ";
      case 1:
        return "الْحَمْدُ لِلَّهِ";
      case 2:
        return "لَا إِلَهَ إِلَّا اللهُ";
      case 3:
        return "أَسْتَغْفِرُ اللهَ";
      default:
        return "سُبْحَانَ اللهِ";
    }
  }

  Future<void> _increment() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter++;
      prefs.setInt('free_tasbeeh_count', _counter);
    });
    AchievementManager.onTasbeehIncrement(_counter);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = 0;
      prefs.setInt('free_tasbeeh_count', 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تسبيح حر", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5D4037),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentDhikr,
              style: const TextStyle(
                  fontSize: 28,
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFFFD700), width: 8),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_counter',
                    style: const TextStyle(
                        fontSize: 65,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _increment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("تـسـبيـح",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037))),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _reset,
              child: const Text("اعادة البدء",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
// ---------------------- WelcomePage ----------------------
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveNameAndStart() async {
    if (_nameController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setBool('is_first_time', false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D4037),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo.jpg', // تأكد من وجود الصورة بهذا الاسم
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "مرحباً بك في تطبيق ذِكرى",
              style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "ما هو الاسم الذي تحب أن نناديك به؟",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "اكتب اسمك هنا...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveNameAndStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "ابدأ الرحلة",
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}