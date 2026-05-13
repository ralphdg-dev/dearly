import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/custom_drawer.dart';
import '../services/firestore_service.dart';
import '../models/journal_entry.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = FirestoreService();
  final _picker = ImagePicker();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_uid != null) {
      try {
        final entries = await _service.getEntries(_uid);
        if (mounted) {
          setState(() {
            _entries = entries;
          });
        }
      } catch (e) {
        print("🚨 Ignored entries error: $e");
      }
    }
  }

  Future<void> _showImagePickerOptions(AppUser user) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutralDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
                title: Text('Take a Photo', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(user, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: Text('Choose from Gallery', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(user, ImageSource.gallery);
                },
              ),
              if (user.profilePicture.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  title: Text('Remove Profile Picture', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppTheme.danger)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture(user);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(AppUser user, ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source);
      if (xfile == null) return;

      final updatedUser = AppUser(
        userId: user.userId,
        name: user.name,
        memberSince: user.memberSince,
        profilePicture: xfile.path,
      );

      await _service.setUser(updatedUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: $e')),
        );
      }
    }
  }

  Future<void> _removeProfilePicture(AppUser user) async {
    try {
      final updatedUser = AppUser(
        userId: user.userId,
        name: user.name,
        memberSince: user.memberSince,
        profilePicture: '',
      );

      await _service.setUser(updatedUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove picture: $e')),
        );
      }
    }
  }

  Future<void> _editProfile(AppUser user) async {
    final nameCtrl = TextEditingController(text: user.name);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Name', style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
              content: TextField(
                controller: nameCtrl,
                autofocus: true,
                style: GoogleFonts.manrope(color: AppTheme.textDark),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: GoogleFonts.manrope(color: AppTheme.textLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textMid)),
                ),
                TextButton(
                  onPressed: isSaving ? null : () async {
                    final newName = nameCtrl.text.trim();
                    if (newName.isEmpty || newName == user.name) {
                      Navigator.pop(context);
                      return;
                    }

                    setStateDialog(() => isSaving = true);

                    try {
                      final updatedUser = AppUser(
                        userId: user.userId,
                        name: newName,
                        memberSince: user.memberSince,
                        profilePicture: user.profilePicture,
                      );

                      await _service.setUser(updatedUser);
                      FirestoreService.pendingName = newName;

                      try {
                        await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
                      } catch (_) {}

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setStateDialog(() => isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : Text('Save', style: GoogleFonts.manrope(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          }
      ),
    );
  }

  String _dominantMood() {
    if (_entries.isEmpty) return 'Calm';
    final counts = <String, int>{};
    for (final e in _entries) counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _currentStreak() {
    if (_entries.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    final sorted = [..._entries]..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sorted) {
      final diff = check.difference(DateTime(e.date.year, e.date.month, e.date.day)).inDays;
      if (diff <= 1) {
        streak++;
        check = DateTime(e.date.year, e.date.month, e.date.day)
            .subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return StreamBuilder<AppUser?>(
        stream: _service.userStream(_uid!),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user?.name ?? 'Loading...';
          final memberSince = user?.memberSince ?? DateTime.now();
          final streak = _currentStreak();
          final dominant = _dominantMood();

          return Scaffold(
            drawer: const CustomDrawer(),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, size: 20, color: AppTheme.textDark),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text('The Quiet Room',
                  style: GoogleFonts.notoSerif(
                      color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textDark),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: user != null ? () => _showImagePickerOptions(user) : null,
                    child: Stack(
                      children: [
                        UserAvatar(
                          profilePicture: user?.profilePicture,
                          name: name,
                          radius: 52,
                          backgroundColor: AppTheme.primaryDark,
                          textStyle: GoogleFonts.notoSerif(
                              fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: user != null ? () => _editProfile(user) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name,
                            style: GoogleFonts.notoSerif(
                                fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 14, color: AppTheme.textLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'MEMBER SINCE ${DateFormat('MMMM yyyy').format(memberSince).toUpperCase()}',
                    style: GoogleFonts.manrope(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppTheme.textLight, letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(height: 28),

                Text('Reflective Journey',
                    style: GoogleFonts.notoSerif(
                        fontSize: 18, fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600, color: AppTheme.primary)),
                const SizedBox(height: 14),

                StatCard(
                  value: _entries.length.toString(),
                  label: 'Total Entries written',
                  icon: Icons.trending_up_outlined,
                ),
                const SizedBox(height: 10),
                StatCard(
                  value: '$streak days',
                  label: 'Current Streak',
                  icon: Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: 10),
                StatCard(
                  value: dominant,
                  label: 'Most Frequent Mood',
                  icon: Icons.sentiment_satisfied_outlined,
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, size: 20, color: AppTheme.textLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"Your journal is the quietest room in the world, where your thoughts can finally breathe."',
                          style: GoogleFonts.notoSerif(
                              fontSize: 13, fontStyle: FontStyle.italic,
                              color: AppTheme.textMid, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
    );
  }
}
