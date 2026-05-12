import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/custom_drawer.dart'; // 🛑 Added Import
import '../services/firestore_service.dart';
import '../models/journal_entry.dart';

class MoodInsightsScreen extends StatefulWidget {
  const MoodInsightsScreen({super.key});

  @override
  State<MoodInsightsScreen> createState() => _MoodInsightsScreenState();
}

class _MoodInsightsScreenState extends State<MoodInsightsScreen> {
  final _service = FirestoreService();
  List<JournalEntry> _entries = [];

  final Map<String, double> _moodValues = {
    'Radiant': 5, 'Happy': 4, 'Calm': 3,
    'Neutral': 2.5, 'Pensive': 2, 'Sad': 1, 'Anxious': 1,
  };
  final Map<String, String> _moodEmojis = {
    'Radiant': '☀️', 'Happy': '😊', 'Calm': '🧘',
    'Neutral': '😐', 'Pensive': '💧', 'Sad': '😢', 'Anxious': '😰',
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await _service.getEntries();
    if (mounted) setState(() => _entries = entries);
  }

  String _dominantMood() {
    if (_entries.isEmpty) return 'Calm';
    final counts = <String, int>{};
    for (final e in _entries) counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _dominantPercent() {
    if (_entries.isEmpty) return 0;
    final dominant = _dominantMood();
    final count = _entries.where((e) => e.mood == dominant).length;
    return (count / _entries.length * 100).roundToDouble();
  }

  List<FlSpot> _weekSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = _entries.where((e) =>
      e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day);
      final avg = dayEntries.isEmpty
          ? 2.5
          : dayEntries
          .map((e) => _moodValues[e.mood] ?? 2.5)
          .reduce((a, b) => a + b) /
          dayEntries.length;
      spots.add(FlSpot((6 - i).toDouble(), avg));
    }
    return spots;
  }

  Map<String, double> _moodBreakdown() {
    if (_entries.isEmpty) return {};
    final counts = <String, int>{};
    for (final e in _entries) counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    return counts.map((k, v) => MapEntry(k, v / _entries.length));
  }

  // returns a 5x7 grid of mood values for the heatmap
  List<List<String?>> _calendarData() {
    final now = DateTime.now();
    final grid = List.generate(5, (_) => List<String?>.filled(7, null));
    for (int w = 0; w < 5; w++) {
      for (int d = 0; d < 7; d++) {
        final day = now.subtract(Duration(days: (4 - w) * 7 + (6 - d)));
        final match = _entries.where((e) =>
        e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day);
        grid[w][d] = match.isNotEmpty ? match.first.mood : null;
      }
    }
    return grid;
  }

  Color _moodColor(String? mood) {
    switch (mood) {
      case 'Radiant': return AppTheme.primary;
      case 'Happy':   return AppTheme.primary.withValues(alpha: 0.8);
      case 'Calm':    return AppTheme.secondary;
      case 'Neutral': return AppTheme.secondary.withValues(alpha: 0.5);
      case 'Pensive': return AppTheme.tertiary;
      case 'Sad':     return Colors.blueGrey.shade300;
      case 'Anxious': return Colors.redAccent.withValues(alpha: 0.5);
      default:        return AppTheme.neutralDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dominant = _dominantMood();
    final percent = _dominantPercent();
    final spots = _weekSpots();
    final breakdown = _moodBreakdown();
    final calendar = _calendarData();
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Scaffold(
      drawer: const CustomDrawer(), // 🛑 Added Drawer
      appBar: QuietRoomAppBar(
        trailing: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.tertiary,
          child: const Icon(Icons.person, size: 18, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Text('WEEKLY RETROSPECTIVE',
                style: GoogleFonts.manrope(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppTheme.textLight, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('Emotional\nLandscapes',
                style: GoogleFonts.notoSerif(
                    fontSize: 34, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 24),

            // ── LINE CHART
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neutralDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('The Past Seven\nSunsets',
                              style: GoogleFonts.notoSerif(
                                  fontSize: 16, fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text('Tracing the ebb and flow of your spirit.',
                              style: GoogleFonts.manrope(
                                  fontSize: 11, color: AppTheme.textLight)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.greenChip,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 6)))} – ${DateFormat('MMM d').format(DateTime.now())}',
                          style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 140,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 5.5,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) => Text(
                                days[v.toInt() % 7],
                                style: GoogleFonts.manrope(
                                    fontSize: 9, color: AppTheme.textLight),
                              ),
                              reservedSize: 22,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                radius: 3,
                                color: AppTheme.primary,
                                strokeWidth: 0,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0.25),
                                  AppTheme.primary.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── AI QUOTE
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neutralDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    '"You are finding your center again, like mist clearing from a valley at dawn."',
                    style: GoogleFonts.notoSerif(
                        fontSize: 16, fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your consistency in tracking has increased. Each entry is a gift to your future self.',
                    style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textLight, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── DOMINANT STATE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.greenChip,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DOMINANT STATE',
                      style: GoogleFonts.manrope(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${percent.toInt()}%',
                          style: GoogleFonts.notoSerif(
                              fontSize: 44, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(dominant,
                            style: GoogleFonts.manrope(
                                fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── MOOD BREAKDOWN
            ...breakdown.entries.map((entry) => _MoodBar(
              mood: entry.key,
              emoji: _moodEmojis[entry.key] ?? '📝',
              percent: entry.value,
              color: _moodColor(entry.key),
            )),

            const SizedBox(height: 16),

            // ── CALENDAR HEATMAP
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neutralDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rhythms of ${DateFormat('MMMM').format(DateTime.now())}',
                      style: GoogleFonts.notoSerif(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: days.map((d) => Text(d,
                        style: GoogleFonts.manrope(
                            fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.w600)))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  ...calendar.map((week) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: week.map((mood) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _moodColor(mood),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )).toList(),
                    ),
                  )),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('LOWER FOCUS',
                          style: GoogleFonts.manrope(fontSize: 9, color: AppTheme.textLight)),
                      const SizedBox(width: 8),
                      ...List.generate(
                          5,
                              (i) => Container(
                            width: 18,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.2 + i * 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )),
                      const SizedBox(width: 8),
                      Text('HIGHER FOCUS',
                          style: GoogleFonts.manrope(fontSize: 9, color: AppTheme.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  final String mood;
  final String emoji;
  final double percent;
  final Color color;

  const _MoodBar({
    required this.mood,
    required this.emoji,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutralDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(mood,
                  style: GoogleFonts.notoSerif(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              const Spacer(),
              Text('${(percent * 100).toInt()}%',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMid)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.neutralDark,
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}