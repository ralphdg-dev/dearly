import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/custom_drawer.dart'; // 🛑 Added Import
import '../services/firestore_service.dart';
import '../models/journal_entry.dart';
import 'new_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _service = FirestoreService();
  final _searchCtrl = TextEditingController();
  List<JournalEntry> _all = [];
  List<JournalEntry> _filtered = [];

  final List<Map<String, String>> _moods = [
    {'label': 'Radiant', 'emoji': '☀️'},
    {'label': 'Calm',    'emoji': '🧘'},
    {'label': 'Pensive', 'emoji': '💧'},
    {'label': 'Happy',   'emoji': '😊'},
    {'label': 'Neutral', 'emoji': '😐'},
    {'label': 'Sad',     'emoji': '😢'},
    {'label': 'Anxious', 'emoji': '😰'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final entries = await _service.getEntries();
    if (mounted) setState(() { _all = entries; _filtered = entries; });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((e) =>
      e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q)).toList();
    });
  }

  Map<String, List<JournalEntry>> _groupByMonth(List<JournalEntry> entries) {
    final Map<String, List<JournalEntry>> grouped = {};
    for (final e in entries) {
      final key = DateFormat('MMMM yyyy').format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  String _moodEmoji(String mood) {
    return _moods.firstWhere(
          (m) => m['label'] == mood,
      orElse: () => {'emoji': '📝'},
    )['emoji']!;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonth(_filtered);
    final months = grouped.keys.toList();

    return Scaffold(
      drawer: const CustomDrawer(), // 🛑 Added Drawer
      appBar: QuietRoomAppBar(
        trailing: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewEntryScreen()),
          ).then((_) => _loadEntries()),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryDark,
            child: Icon(Icons.add, size: 18, color: Colors.white),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Text('Journal history',
                style: GoogleFonts.notoSerif(
                    fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 16),

            // ── SEARCH
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.neutralDark),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Search through your thoughts...',
                  hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textLight),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome, size: 36, color: AppTheme.textLight),
                      const SizedBox(height: 16),
                      Text('That is all for now.',
                          style: GoogleFonts.notoSerif(
                              fontSize: 16, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              )
            else
              ...months.map((month) {
                final parts = month.split(' ');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(parts[0],
                            style: GoogleFonts.notoSerif(
                                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        Text(parts[1],
                            style: GoogleFonts.manrope(
                                fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textLight)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...grouped[month]!.map((e) => EntryCard(
                      day: DateFormat('dd').format(e.date),
                      weekday: DateFormat('EEE').format(e.date).toUpperCase(),
                      title: e.title.isNotEmpty ? e.title : 'Untitled Entry',
                      excerpt: e.content,
                      mood: e.mood,
                      moodEmoji: _moodEmoji(e.mood),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewEntryScreen(existing: e),
                        ),
                      ).then((_) => _loadEntries()),
                    )),
                    const SizedBox(height: 8),
                  ],
                );
              }),

            // ── FOOTER IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.neutralDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 32, color: AppTheme.textLight),
                      const SizedBox(height: 8),
                      Text('"Writing is the geometry of the soul."',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerif(
                              fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.textMid)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 20, color: AppTheme.textLight),
                  const SizedBox(height: 8),
                  Text('That is all for now.',
                      style: GoogleFonts.notoSerif(
                          fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.textLight)),
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