import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/custom_drawer.dart';
import '../services/firestore_service.dart';
import '../models/journal_entry.dart';
import '../main.dart'; // To access NavigationProvider
import 'new_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  String _selectedMood = '';

  final List<Map<String, String>> _moods = [
    {'label': 'Happy',   'emoji': '😊'},
    {'label': 'Calm',    'emoji': '🧘'},
    {'label': 'Neutral', 'emoji': '😐'},
    {'label': 'Sad',     'emoji': '😢'},
    {'label': 'Anxious', 'emoji': '😰'},
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  int _calculateStreak(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    final sorted = List.from(entries)..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);
    Set<String> entryDates = sorted.map((e) => DateFormat('yyyy-MM-dd').format(e.date)).toSet();

    while(true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      if (entryDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (streak == 0 && checkDate.difference(DateTime(today.year, today.month, today.day)).inDays == 0) {
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
    return streak;
  }

  String _calculateTopMood(List<JournalEntry> entries) {
    if (entries.isEmpty) return 'Neutral';
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final recent = entries.where((e) => e.date.isAfter(lastWeek)).toList();
    if (recent.isEmpty) return entries.first.mood;
    Map<String, int> moodCounts = {};
    for (var e in recent) {
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
    }
    return moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return StreamBuilder<AppUser?>(
      stream: _service.userStream(_uid!),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final firstName = (user?.name ?? 'Friend').split(' ').first;

        return Scaffold(
          drawer: const CustomDrawer(),
          appBar: QuietRoomAppBar(
            trailing: UserAvatar(
              profilePicture: user?.profilePicture,
              name: user?.name ?? 'Friend',
              radius: 18,
            ),
          ),
          body: StreamBuilder<List<JournalEntry>>(
              stream: _service.getUserEntries(_uid!),
              builder: (context, snapshot) {
                final entries = snapshot.data ?? [];
                final sortedEntries = List<JournalEntry>.from(entries)
                  ..sort((a, b) => b.date.compareTo(a.date));

                final recentEntries = sortedEntries.take(3).toList();
                final int streak = _calculateStreak(sortedEntries);
                final String topMood = _calculateTopMood(sortedEntries);

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async => await _service.getUser(_uid!),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      Text(_greeting(),
                          style: GoogleFonts.notoSerif(
                              fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                      Text(firstName,
                          style: GoogleFonts.notoSerif(
                              fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      Text(
                        'The sun is filtering through the mist today.\nTake a moment to settle into your thoughts.',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textMid, height: 1.5),
                      ),
                      const SizedBox(height: 24),

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
                            Text('How are you feeling?',
                                style: GoogleFonts.notoSerif(
                                    fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.8,
                              children: _moods.map((m) {
                                final selected = _selectedMood == m['label'];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedMood = m['label']!),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.greenChip : AppTheme.neutral,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected ? AppTheme.primary : AppTheme.neutralDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(m['emoji']!, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(height: 4),
                                        Text(m['label']!,
                                            style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: selected ? AppTheme.primaryDark : AppTheme.textMid)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      ReflectionPromptCard(
                        prompt: 'What is one small thing that brought you peace in the last 24 hours?',
                        onStartWriting: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NewEntryScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.greenChip,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primaryDark),
                                const SizedBox(width: 6),
                                Text('Weekly Rhythm',
                                    style: GoogleFonts.notoSerif(
                                        fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entries.isEmpty
                                  ? "Begin your journey today by writing your first reflection."
                                  : "You've maintained a $streak-day streak of mindful reflection. Your most frequent mood this week is $topMood.",
                              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.primaryDark, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: List.generate(
                                7,
                                    (i) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: i < streak.clamp(0, 7) ? AppTheme.primary : AppTheme.secondary.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your recent\nmemories',
                              style: GoogleFonts.notoSerif(
                                  fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                          GestureDetector(
                            onTap: () {
                              // FIX: Use TabProvider to switch to Journal tab instead of pushReplacement
                              Provider.of<NavigationProvider>(context, listen: false).setTab(1);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('View all',
                                    style: GoogleFonts.manrope(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                Text('entries',
                                    style: GoogleFonts.manrope(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (snapshot.connectionState == ConnectionState.waiting && recentEntries.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (recentEntries.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.auto_awesome, size: 32, color: AppTheme.textLight),
                                const SizedBox(height: 12),
                                Text('No entries yet.\nStart your first reflection.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(color: AppTheme.textLight, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...recentEntries.map((e) {
                          final moodData = _moods.firstWhere(
                                (m) => m['label'] == e.mood,
                            orElse: () => {'label': e.mood, 'emoji': '📝'},
                          );
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NewEntryScreen(existing: e)),
                            ),
                            child: _RecentEntryCard(entry: e, moodEmoji: moodData['emoji']!),
                          );
                        }),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
          ),
        );
      }
    );
  }
}

class _RecentEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final String moodEmoji;
  const _RecentEntryCard({required this.entry, required this.moodEmoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(entry.date).toUpperCase(),
                style: GoogleFonts.manrope(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppTheme.textLight, letterSpacing: 0.8),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.greenChip,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(moodEmoji, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(entry.mood,
                        style: GoogleFonts.manrope(
                            fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.title.isNotEmpty ? entry.title : 'Untitled Entry',
              style: GoogleFonts.notoSerif(
                  fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text(entry.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMid, height: 1.5)),
          const SizedBox(height: 12),
          if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(entry.imageUrl!,
                  height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          Text('${entry.wordCount} words · ${DateFormat('h:mm a').format(entry.date)}',
              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}
