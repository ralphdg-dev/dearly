import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = FirestoreService();
  bool _passcode = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Log Out', style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.manrope()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: GoogleFonts.manrope(color: AppTheme.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst); // Go back to Auth Screen
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool isSaving = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Change Password', style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: GoogleFonts.manrope(color: AppTheme.danger, fontSize: 12)),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    style: GoogleFonts.manrope(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: GoogleFonts.manrope(color: AppTheme.textLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    style: GoogleFonts.manrope(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: GoogleFonts.manrope(color: AppTheme.textLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textMid)),
                ),
                TextButton(
                  onPressed: isSaving ? null : () async {
                    if (currentPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                      setStateDialog(() => errorMessage = "Please fill in all fields.");
                      return;
                    }
                    if (newPassCtrl.text.length < 6) {
                      setStateDialog(() => errorMessage = "New password must be at least 6 characters.");
                      return;
                    }

                    setStateDialog(() {
                      isSaving = true;
                      errorMessage = null;
                    });

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.email != null) {
                        // 1. Re-authenticate user to prove their identity
                        AuthCredential credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPassCtrl.text
                        );
                        await user.reauthenticateWithCredential(credential);

                        // 2. Update to new password
                        await user.updatePassword(newPassCtrl.text);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully!')),
                          );
                        }
                      }
                    } on FirebaseAuthException catch (e) {
                      setStateDialog(() {
                        isSaving = false;
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          errorMessage = "Incorrect current password.";
                        } else {
                          errorMessage = e.message ?? "An error occurred.";
                        }
                      });
                    } catch (e) {
                      setStateDialog(() {
                        isSaving = false;
                        errorMessage = e.toString();
                      });
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : Text('Update', style: GoogleFonts.manrope(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.notoSerif(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('Journal Settings',
              style: GoogleFonts.notoSerif(
                  fontSize: 18, fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600, color: AppTheme.primary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neutralDark),
            ),
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: 'Daily Reminder',
                  subtitle: 'A gentle nudge to write',
                  trailing: GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _reminderTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.greenChip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _reminderTime.format(context),
                        style: GoogleFonts.manrope(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: AppTheme.neutralDark),
                SettingsRow(
                  icon: Icons.lock_outline,
                  title: 'Secure with Passcode',
                  subtitle: 'Keep your inner world private',
                  trailing: Switch(
                    value: _passcode,
                    onChanged: (v) => setState(() => _passcode = v),
                    activeTrackColor: AppTheme.primary,
                    activeColor: Colors.white,
                  ),
                ),
                Divider(height: 1, color: AppTheme.neutralDark),
                SettingsRow(
                  icon: Icons.key_outlined,
                  title: 'Change Password',
                  subtitle: 'Update your account security',
                  trailing: const Icon(Icons.chevron_right, size: 16, color: AppTheme.textLight),
                  onTap: _showChangePasswordDialog,
                ),
                Divider(height: 1, color: AppTheme.neutralDark),
                SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'App Appearance',
                  subtitle: 'The visual tone of your desk',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mist Theme',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMid)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.textLight),
                    ],
                  ),
                  onTap: () {},
                ),
                Divider(height: 1, color: AppTheme.neutralDark),
                SettingsRow(
                  icon: Icons.upload_outlined,
                  title: 'Export Data',
                  subtitle: 'Download your digital vellum as PDF/JSON',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preparing your entries for export...')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ── LOG OUT
          Center(
            child: TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, size: 16, color: AppTheme.danger),
              label: Text('Log Out',
                  style: GoogleFonts.manrope(
                      color: AppTheme.danger, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}