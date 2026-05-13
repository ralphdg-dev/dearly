import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/firestore_service.dart';
import '../models/journal_entry.dart';

class NewEntryScreen extends StatefulWidget {
  final JournalEntry? existing;
  const NewEntryScreen({super.key, this.existing});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _service = FirestoreService();
  final _picker = ImagePicker();

  String _selectedMood = 'Radiant';
  File? _imageFile;
  String? _remoteImageUrl;
  List<String> _tags = [];
  bool _saving = false;

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
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _contentCtrl.text = widget.existing!.content;
      _locationCtrl.text = widget.existing!.location;
      _selectedMood = widget.existing!.mood;
      _tags = List.from(widget.existing!.tags);
      _remoteImageUrl = widget.existing!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _locationCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xfile != null) {
      setState(() {
        _imageFile = File(xfile.path);
        _remoteImageUrl = null; // New image overrides the old one
      });
    }
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() => _tags.add(tag.trim()));
      _tagCtrl.clear();
    }
  }

  Future<void> _saveEntry() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = _service.currentUser?.uid ?? '';
      final entryId = widget.existing?.entryId ?? const Uuid().v4();
      
      String? finalImageUrl = _remoteImageUrl;

      // If a new image was picked, upload it first
      if (_imageFile != null) {
        finalImageUrl = await _service.uploadEntryImage(entryId, _imageFile!);
      }

      final words = _contentCtrl.text.trim().split(RegExp(r'\s+')).length;
      
      final entry = JournalEntry(
        entryId: entryId,
        userId: uid,
        date: widget.existing?.date ?? DateTime.now(),
        content: _contentCtrl.text.trim(),
        mood: _selectedMood,
        location: _locationCtrl.text.trim(),
        title: _titleCtrl.text.trim().isEmpty
            ? _contentCtrl.text.trim().split(' ').take(4).join(' ')
            : _titleCtrl.text.trim(),
        tags: _tags,
        wordCount: words,
        imageUrl: finalImageUrl,
      );

      if (widget.existing != null) {
        await _service.updateEntry(entry);
      } else {
        await _service.addEntry(entry);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Current Haven',
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: _locationCtrl,
          decoration: InputDecoration(
            hintText: 'Where are you?',
            hintStyle: GoogleFonts.manrope(color: AppTheme.textLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done', style: GoogleFonts.manrope(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showTagDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Tag', style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: _tagCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. gratitude, nature...',
            hintStyle: GoogleFonts.manrope(color: AppTheme.textLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: (v) {
            _addTag(v);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addTag(_tagCtrl.text);
              Navigator.pop(context);
            },
            child: Text('Add', style: GoogleFonts.manrope(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Edit Entry' : 'New Entry',
            style: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryDark,
              child: Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ── DATE
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textLight),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEEE, MMMM d').format(widget.existing?.date ?? DateTime.now()).toUpperCase(),
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppTheme.textLight, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── TITLE
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.notoSerif(
                fontSize: 30, fontWeight: FontWeight.w700, color: AppTheme.textDark, height: 1.2),
            decoration: InputDecoration(
              hintText: 'A moment of pause.',
              hintStyle: GoogleFonts.notoSerif(
                  fontSize: 30, fontWeight: FontWeight.w700, color: AppTheme.textLight),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
          ),
          const SizedBox(height: 20),

          // ── MOOD LABEL
          Text('CURRENT MOOD',
              style: GoogleFonts.manrope(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppTheme.textLight, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _moods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => MoodChip(
                label: _moods[i]['label']!,
                emoji: _moods[i]['emoji']!,
                selected: _selectedMood == _moods[i]['label'],
                onTap: () => setState(() => _selectedMood = _moods[i]['label']!),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── CONTENT
          TextField(
            controller: _contentCtrl,
            style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.textDark, height: 1.7),
            decoration: InputDecoration(
              hintText: 'Start writing...',
              hintStyle: GoogleFonts.manrope(fontSize: 15, color: AppTheme.textLight),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            minLines: 6,
          ),
          const SizedBox(height: 24),

          // ── ACTION CHIPS
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.photo_camera_outlined,
                label: (_imageFile != null || _remoteImageUrl != null) ? 'Change Memory' : 'Add Memory',
                onTap: _pickImage,
              ),
              _ActionChip(
                icon: Icons.location_on_outlined,
                label: _locationCtrl.text.isEmpty ? 'Current Haven' : _locationCtrl.text,
                onTap: _showLocationDialog,
              ),
              _ActionChip(
                icon: Icons.label_outline,
                label: 'Tag',
                onTap: _showTagDialog,
              ),
              ..._tags.map((t) => _ActionChip(
                    icon: Icons.tag,
                    label: t,
                    onTap: () => setState(() => _tags.remove(t)),
                    color: AppTheme.greenChip,
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // ── IMAGE PREVIEW
          if (_imageFile != null || _remoteImageUrl != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageFile != null 
                    ? Image.file(_imageFile!, height: 220, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(_remoteImageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _imageFile = null;
                      _remoteImageUrl = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── REFLECTION PROMPT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutralDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 20),
                const SizedBox(height: 8),
                Text('Reflection Prompt',
                    style: GoogleFonts.notoSerif(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                const SizedBox(height: 6),
                Text(
                  'What is one thing that felt lighter today than it did yesterday?',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMid, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        color: AppTheme.neutral,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _saveEntry,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome, size: 16),
          label: Text(_saving ? 'SAVING...' : 'PRESERVE ENTRY',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? AppTheme.neutralDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.neutralDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textMid),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMid)),
          ],
        ),
      ),
    );
  }
}
