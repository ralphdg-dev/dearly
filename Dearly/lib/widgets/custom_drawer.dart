import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../screens/settings_screen.dart';
import '../models/journal_entry.dart';
import '../main.dart'; // To access NavigationProvider
import 'shared_widgets.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Drawer(
      backgroundColor: AppTheme.neutral,
      child: Column(
        children: [
          // ── DRAWER HEADER ──
          StreamBuilder<AppUser?>(
            stream: uid != null ? service.userStream(uid) : null,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final name = user?.name ?? 'The Quiet Room';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      profilePicture: user?.profilePicture,
                      name: name,
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null ? 'Your space for reflection' : 'Sign in to sync your journey',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                  onTap: () {
                    nav.setTab(0);
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Journal History',
                  onTap: () {
                    nav.setTab(1);
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.auto_graph_outlined,
                  label: 'Mood Insights',
                  onTap: () {
                    nav.setTab(2);
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    nav.setTab(3);
                    Navigator.pop(context);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
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
                Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                await service.signOut();
              },
            ),
          ),
        ],
      ),
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
    );
  }
}
