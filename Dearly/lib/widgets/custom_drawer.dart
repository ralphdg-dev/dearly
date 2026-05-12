import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../screens/home_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/mood_insights_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.neutral,
      child: Column(
        children: [
          // ── DRAWER HEADER ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'The Quiet Room',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your space for reflection',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── NAVIGATION LINKS ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () => _navigateReplace(context, const HomeScreen()),
                ),
                _DrawerItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Journal History',
                  onTap: () => _navigateReplace(context, const JournalScreen()),
                ),
                _DrawerItem(
                  icon: Icons.auto_graph_outlined,
                  label: 'Mood Insights',
                  onTap: () => _navigateReplace(context, const MoodInsightsScreen()),
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () => _navigateReplace(context, const ProfileScreen()),
                ),
                Divider(color: AppTheme.neutralDark, height: 32),

                // 🛑 THE FIX: Settings uses standard push so you can hit "Back" safely!
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context); // Close the drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── LOG OUT BUTTON ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: _DrawerItem(
              icon: Icons.logout,
              label: 'Log Out',
              color: AppTheme.danger,
              onTap: () async {
                final service = FirestoreService();
                await service.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Top-Level screens so they don't build up a massive back-stack
  void _navigateReplace(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer first
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppTheme.textDark;

    return ListTile(
      leading: Icon(icon, color: textColor, size: 22),
      title: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      hoverColor: AppTheme.greenChip,
      splashColor: AppTheme.greenChip,
    );
  }
}