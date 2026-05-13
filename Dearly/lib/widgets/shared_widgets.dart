import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── USER AVATAR ───────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? profilePicture;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    this.profilePicture,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textStyle,
  });

  ImageProvider? _getAvatar() {
    if (profilePicture == null || profilePicture!.isEmpty) return null;
    if (profilePicture!.startsWith('http')) return NetworkImage(profilePicture!);
    final file = File(profilePicture!);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImg = _getAvatar();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppTheme.secondary,
      backgroundImage: avatarImg,
      child: avatarImg == null
          ? Text(
              initial,
              style: textStyle ??
                  GoogleFonts.notoSerif(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: radius * 0.8,
                  ),
            )
          : null,
    );
  }
}

// ── APP BAR ────────────────────────────────────────────────────────────────
class QuietRoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDrawerIcon;
  final Widget? trailing;
  const QuietRoomAppBar({super.key, this.showDrawerIcon = true, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showDrawerIcon
          ? IconButton(
              icon: const Icon(Icons.menu, size: 20),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          : null,
      title: Text('The Quiet Room',
          style: GoogleFonts.notoSerif(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
      actions: [if (trailing != null) Padding(padding: const EdgeInsets.only(right: 12), child: trailing!)],
    );
  }
}

// ── MOOD CHIP ──────────────────────────────────────────────────────────────
class MoodChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const MoodChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.greenChip : AppTheme.neutralDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppTheme.primaryDark : AppTheme.textMid,
                )),
          ],
        ),
      ),
    );
  }
}

// ── ENTRY CARD ─────────────────────────────────────────────────────────────
class EntryCard extends StatelessWidget {
  final String day;
  final String weekday;
  final String title;
  final String excerpt;
  final String mood;
  final String moodEmoji;
  final VoidCallback onTap;

  const EntryCard({
    super.key,
    required this.day,
    required this.weekday,
    required this.title,
    required this.excerpt,
    required this.mood,
    required this.moodEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neutralDark, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(day,
                      style: GoogleFonts.notoSerif(
                          fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  Text(weekday,
                      style: GoogleFonts.manrope(
                          fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textLight)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title,
                            style: GoogleFonts.notoSerif(
                                fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.greenChip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(moodEmoji, style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(mood,
                                style: GoogleFonts.manrope(
                                    fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppTheme.textMid, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STAT CARD ──────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const StatCard({super.key, required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.notoSerif(
                  fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMid)),
        ],
      ),
    );
  }
}

// ── SETTINGS ROW ──────────────────────────────────────────────────────────
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textMid),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  Text(subtitle,
                      style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textLight)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

// ── REFLECTION PROMPT CARD ────────────────────────────────────────────────
class ReflectionPromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback? onStartWriting;
  const ReflectionPromptCard({super.key, required this.prompt, this.onStartWriting});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.neutralDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Reflection Prompt",
              style: GoogleFonts.manrope(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppTheme.textLight, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(prompt,
              style: GoogleFonts.notoSerif(
                  fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.4)),
          const SizedBox(height: 14),
          if (onStartWriting != null)
            GestureDetector(
              onTap: onStartWriting,
              child: Row(
                children: [
                  Text('Start writing',
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
