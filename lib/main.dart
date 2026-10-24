import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const DayApp());
}

const dayNames = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const monthNames = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];

const palettes = <List<Color>>[
  [Color(0xFF141E30), Color(0xFF243B55)],
  [Color(0xFF2B1055), Color(0xFF5B6FD6)],
  [Color(0xFF134E5E), Color(0xFF3E8E6B)],
  [Color(0xFF42275A), Color(0xFF9B5C8F)],
  [Color(0xFF0F5E6B), Color(0xFF1FA2A6)],
  [Color(0xFF8E2DE2), Color(0xFF3A1C71)],
  [Color(0xFFCB5A2E), Color(0xFF7A1F3D)],
  [Color(0xFFB8501F), Color(0xFF4A1942)],
  [Color(0xFF3A6073), Color(0xFF16222A)],
  [Color(0xFF7A3E1D), Color(0xFF2B1B17)],
  [Color(0xFF232526), Color(0xFF414345)],
  [Color(0xFF0B3A66), Color(0xFF1B1B3A)],
];

LinearGradient gradientFor(DateTime d) => LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: palettes[d.month - 1],
    );

class Zone {
  final String name;
  final int? minutes; // null = تلقائي من الجهاز
  const Zone(this.name, this.minutes);
}

// فروق ثابتة (بدون توقيت صيفي)، والأول تلقائي من الجهاز
const zones = [
  Zone('تلقائي (الجهاز)', null),
  Zone('ليبيا (+2)', 120),
  Zone('مصر (+2)', 120),
  Zone('السودان (+2)', 120),
  Zone('فلسطين (+2)', 120),
  Zone('تونس (+1)', 60),
  Zone('الجزائر (+1)', 60),
  Zone('المغرب (+1)', 60),
  Zone('السعودية (+3)', 180),
  Zone('العراق (+3)', 180),
  Zone('الأردن (+3)', 180),
  Zone('قطر (+3)', 180),
  Zone('الكويت (+3)', 180),
  Zone('تركيا (+3)', 180),
  Zone('الإمارات (+4)', 240),
  Zone('عُمان (+4)', 240),
  Zone('بريطانيا (0)', 0),
  Zone('فرنسا / ألمانيا / إيطاليا (+1)', 60),
  Zone('روسيا - موسكو (+3)', 180),
  Zone('باكستان (+5)', 300),
  Zone('الهند (+5:30)', 330),
  Zone('بنغلاديش (+6)', 360),
  Zone('إندونيسيا - جاكرتا (+7)', 420),
  Zone('الصين / ماليزيا (+8)', 480),
  Zone('اليابان / كوريا (+9)', 540),
  Zone('أستراليا - سيدني (+10)', 600),
  Zone('البرازيل - برازيليا (-3)', -180),
  Zone('أمريكا - نيويورك (-5)', -300),
  Zone('أمريكا - شيكاغو (-6)', -360),
  Zone('أمريكا - لوس أنجلوس (-8)', -480),
  Zone('UTC (0)', 0),
];

Duration offsetOfZone(int i) {
  final m = zones[i].minutes;
  return m == null ? DateTime.now().timeZoneOffset : Duration(minutes: m);
}

String two(int n) => n.toString().padLeft(2, '0');

String offsetLabel(Duration o) {
  final m = o.inMinutes;
  final sign = m < 0 ? '-' : '+';
  final a = m.abs();
  final h = a ~/ 60;
  final mm = a % 60;
  return 'UTC$sign$h${mm == 0 ? '' : ':${two(mm)}'}';
}

String zoneLabel(int i) {
  if (i != 0) return zones[i].name;
  final n = DateTime.now();
  return 'تلقائي (${n.timeZoneName} ${offsetLabel(n.timeZoneOffset)})';
}

String timeStr(DateTime t, bool is24) {
  if (is24) return '${two(t.hour)}:${two(t.minute)}';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${two(t.minute)} ${t.hour < 12 ? 'ص' : 'م'}';
}

class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double opacity;
  final Color? tint;
  const Glass({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.12,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tint ?? Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class DayApp extends StatelessWidget {
  const DayApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'يوم',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const center = 36500;
  int zoneIndex = 0;
  int page = center;
  bool is24 = true;
  late DateTime now;
  Timer? timer;
  late final PageController pc =
      PageController(initialPage: center, viewportFraction: 0.84);

  Duration get offset => offsetOfZone(zoneIndex);

  DateTime get zoneNow => DateTime.now().toUtc().add(offset);
  DateTime get today {
    final n = zoneNow;
    return DateTime.utc(n.year, n.month, n.day);
  }

  DateTime dateAt(int i) => today.add(Duration(days: i - center));
  DateTime get shown => dateAt(page);

  @override
  void initState() {
    super.initState();
    now = zoneNow;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = zoneNow);
    });
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getBool('is24');
      final z = p.getInt('zone');
      if (!mounted) return;
      setState(() {
        if (v != null) is24 = v;
        if (z != null && z >= 0 && z < zones.length) {
          zoneIndex = z;
          now = zoneNow;
        }
      });
    } catch (_) {}
  }

  Future<void> toggleFormat() async {
    HapticFeedback.selectionClick();
    setState(() => is24 = !is24);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('is24', is24);
    } catch (_) {}
  }

  Future<void> selectZone(int i) async {
    HapticFeedback.selectionClick();
    setState(() {
      zoneIndex = i;
      page = center;
      now = zoneNow;
    });
    if (pc.hasClients) pc.jumpToPage(center);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('zone', i);
    } catch (_) {}
  }

  @override
  void dispose() {
    timer?.cancel();
    pc.dispose();
    super.dispose();
  }

  void goTo(int p, {bool animate = true}) {
    if (!pc.hasClients) return;
    if (animate) {
      pc.animateToPage(p,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic);
    } else {
      pc.jumpToPage(p);
    }
  }

  Future<void> openList() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<DateTime>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) =>
            DayListPage(today: today, selected: shown),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
    if (result != null) {
      goTo(center + result.difference(today).inDays, animate: false);
    }
  }

  Future<void> pickZone() async {
    final i = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => Glass(
          radius: 28,
          opacity: 0.4,
          tint: const Color(0xFF10151F),
          child: ListView.builder(
            controller: sc,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: zones.length,
            itemBuilder: (_, i) {
              final t = DateTime.now().toUtc().add(offsetOfZone(i));
              return ListTile(
                title: Text(zoneLabel(i)),
                subtitle: Text(timeStr(t, is24)),
                trailing:
                    i == zoneIndex ? const Icon(Icons.check_circle) : null,
                onTap: () => Navigator.pop(context, i),
              );
            },
          ),
        ),
      ),
    );
    if (i != null) selectZone(i);
  }

  Widget dayCard(int i) {
    final d = dateAt(i);
    final diff = i - center;
    final rel = diff == 0
        ? 'اليوم'
        : diff > 0
            ? (diff == 1 ? 'غداً' : 'بعد $diff يوم')
            : (diff == -1 ? 'أمس' : 'قبل ${-diff} يوم');
    return AnimatedBuilder(
      animation: pc,
      builder: (_, child) {
        double delta;
        if (pc.hasClients && pc.position.haveDimensions) {
          delta = ((pc.page ?? center.toDouble()) - i).abs().clamp(0.0, 1.0);
        } else {
          delta = (i - center).abs().toDouble().clamp(0.0, 1.0);
        }
        final scale = 1 - 0.1 * delta;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: 1 - 0.45 * delta, child: child),
        );
      },
      child: GestureDetector(
        onTap: openList,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Glass(
            radius: 36,
            opacity: 0.13,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(diff == 0 ? 0.9 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: diff == 0 ? Colors.black87 : Colors.white70,
                    ),
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(dayNames[d.weekday - 1],
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${d.day}',
                      style: const TextStyle(
                          fontSize: 170,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          color: Colors.white)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${monthNames[d.month - 1]} ${d.year}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.unfold_more_rounded,
                        size: 18, color: Colors.white.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Text('اضغط لعرض الشهر',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.55))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget weekStrip() {
    final d = shown;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Glass(
        radius: 24,
        opacity: 0.1,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: List.generate(7, (k) {
            final off = k - 3;
            final day = d.add(Duration(days: off));
            final sel = off == 0;
            final isToday = day == today;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  goTo(page + off);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(dayNames[day.weekday - 1],
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      sel ? Colors.black54 : Colors.white70)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${day.day}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.black87 : Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? (sel ? Colors.teal : Colors.white)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget clock() {
    final h = now.hour;
    final hh = is24 ? two(h) : '${h % 12 == 0 ? 12 : h % 12}';
    return GestureDetector(
      onTap: toggleFormat,
      behavior: HitTestBehavior.opaque,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$hh:${two(now.minute)}',
                style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 2,
                    color: Colors.white)),
            const SizedBox(width: 6),
            Text(two(now.second),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.6))),
            if (!is24) ...[
              const SizedBox(width: 8),
              Text(h < 12 ? 'ص' : 'م',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = shown;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(gradient: gradientFor(d)),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: pickZone,
                        child: Glass(
                          radius: 20,
                          opacity: 0.14,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(zoneLabel(zoneIndex),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: toggleFormat,
                      child: Glass(
                        radius: 20,
                        opacity: 0.14,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 6),
                            Text(is24 ? '24 س' : '12 س',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              clock(),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: pc,
                  itemCount: center * 2 + 1,
                  onPageChanged: (p) {
                    HapticFeedback.selectionClick();
                    setState(() => page = p);
                  },
                  itemBuilder: (_, i) => dayCard(i),
                ),
              ),
              const SizedBox(height: 12),
              weekStrip(),
              const SizedBox(height: 14),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: page == center ? 0 : 1,
                child: IgnorePointer(
                  ignoring: page == center,
                  child: GestureDetector(
                    onTap: () => goTo(center),
                    child: Glass(
                      radius: 24,
                      opacity: 0.2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('العودة لليوم',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class DayListPage extends StatefulWidget {
  final DateTime today;
  final DateTime selected;
  const DayListPage({super.key, required this.today, required this.selected});
  @override
  State<DayListPage> createState() => _DayListPageState();
}

class _DayListPageState extends State<DayListPage> {
  static const center = 36500;
  static const extent = 84.0;
  late final ScrollController controller;
  late final ValueNotifier<DateTime> topDate;

  DateTime dateAt(int i) => widget.today.add(Duration(days: i - center));

  @override
  void initState() {
    super.initState();
    final diff = widget.selected.difference(widget.today).inDays;
    topDate = ValueNotifier(widget.selected);
    controller =
        ScrollController(initialScrollOffset: (center + diff) * extent);
    controller.addListener(() {
      final i = (controller.offset / extent).floor() + 2;
      final d = dateAt(i);
      if (d.month != topDate.value.month || d.year != topDate.value.year) {
        topDate.value = d;
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    topDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: topDate,
      builder: (_, top, __) => Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(gradient: gradientFor(top)),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(monthNames[top.month - 1],
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800)),
                            Text('${top.year}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white60)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.animateTo(
                            center * extent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic),
                        child: const Text('اليوم'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemExtent: extent,
                    itemCount: center * 2 + 1,
                    itemBuilder: (_, i) {
                      final d = dateAt(i);
                      final isToday = d == widget.today;
                      final isSel = d == widget.selected;
                      final first = d.day == 1;
                      final friday = d.weekday == 5;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context, d);
                          },
                          child: Glass(
                            radius: 22,
                            opacity: isToday
                                ? 0.32
                                : isSel
                                    ? 0.22
                                    : 0.09,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  child: Text('${d.day}',
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900)),
                                ),
                                Expanded(
                                  child: Text(dayNames[d.weekday - 1],
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: friday
                                              ? Colors.amberAccent
                                              : Colors.white)),
                                ),
                                if (isToday)
                                  Container(
                                    margin:
                                        const EdgeInsets.only(left: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Text('اليوم',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                if (first)
                                  Text(
                                      '${monthNames[d.month - 1]} ${d.year}',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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