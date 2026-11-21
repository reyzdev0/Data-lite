import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ModernNotesApp());
}

// ============================================================================
// 1. MODEL DATA NOTE
// ============================================================================
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int colorIndex;
  final bool isPinned;
  final bool isFavorite;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.colorIndex = 0,
    this.isPinned = false,
    this.isFavorite = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    int? colorIndex,
    bool? isPinned,
    bool? isFavorite,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      colorIndex: colorIndex ?? this.colorIndex,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'colorIndex': colorIndex,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      colorIndex: map['colorIndex'] ?? 0,
      isPinned: map['isPinned'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}

// ============================================================================
// 2. KONSTANTA WARNA & HELPER TANGGAL
// ============================================================================
class NoteThemeHelper {
  static const Color primaryAccent = Color(0xFF6C5CE7);
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color darkBackground = Color(0xFF121216);
  static const Color darkSurface = Color(0xFF1E1E24);

  static const List<Color> lightNoteColors = [
    Color(0xFFFFFFFF),
    Color(0xFFF3E8FF),
    Color(0xFFE0F2FE),
    Color(0xFFDCFCE7),
    Color(0xFFFEF3C7),
    Color(0xFFFFE4E6),
    Color(0xFFFFEDD5),
  ];

  static const List<Color> darkNoteColors = [
    Color(0xFF1E1E24),
    Color(0xFF2B223C),
    Color(0xFF1C2D3D),
    Color(0xFF1B3326),
    Color(0xFF382E1C),
    Color(0xFF3B2027),
    Color(0xFF38261B),
  ];

  static Color getNoteColor(int index, bool isDark) {
    final safeIndex = index.clamp(0, lightNoteColors.length - 1);
    return isDark ? darkNoteColors[safeIndex] : lightNoteColors[safeIndex];
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$minute';
  }
}

// ============================================================================
// 3. ROOT APPLICATION (MANAJEMEN TEMA DARK / LIGHT)
// ============================================================================
class ModernNotesApp extends StatefulWidget {
  const ModernNotesApp({super.key});

  @override
  State<ModernNotesApp> createState() => _ModernNotesAppState();
}

class _ModernNotesAppState extends State<ModernNotesApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
    await prefs.setBool('is_dark_mode', !isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Premium',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NoteThemeHelper.primaryAccent,
          brightness: Brightness.light,
          surface: NoteThemeHelper.lightBackground,
        ),
        scaffoldBackgroundColor: NoteThemeHelper.lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: NoteThemeHelper.lightBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NoteThemeHelper.primaryAccent,
          brightness: Brightness.dark,
          surface: NoteThemeHelper.darkBackground,
        ),
        scaffoldBackgroundColor: NoteThemeHelper.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: NoteThemeHelper.darkBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
      ),
      home: HomePage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ============================================================================
// 4. HALAMAN UTAMA (HOME PAGE)
// ============================================================================
class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _storageKey = 'saved_notes_v1';
  static const String _gridPrefKey = 'is_grid_view';

  List<Note> _notes = [];
  String _searchQuery = '';
  bool _isGridView = true;
  bool _onlyFavorites = false;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final isGrid = prefs.getBool(_gridPrefKey) ?? true;
    final rawJson = prefs.getString(_storageKey);

    List<Note> loadedNotes = [];
    if (rawJson != null && rawJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawJson);
      loadedNotes = decoded.map((item) => Note.fromMap(item)).toList();
    }

    setState(() {
      _isGridView = isGrid;
      _notes = loadedNotes;
      _isLoading = false;
    });
  }

  Future<void> _saveNotesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notes.map((n) => n.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool(_gridPrefKey, _isGridView);
  }

  Future<void> _upsertNote(Note note) async {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
      } else {
        _notes.insert(0, note);
      }
    });
    await _saveNotesToStorage();
  }

  Future<void> _deleteNote(Note note) async {
    final deletedIndex = _notes.indexWhere((n) => n.id == note.id);
    if (deletedIndex == -1) return;

    setState(() {
      _notes.removeAt(deletedIndex);
    });
    await _saveNotesToStorage();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Catatan dihapus'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: const Color(0xFFA29BFE),
          onPressed: () async {
            setState(() {
              _notes.insert(
                deletedIndex.clamp(0, _notes.length),
                note,
              );
            });
            await _saveNotesToStorage();
          },
        ),
      ),
    );
  }

  Future<void> _togglePin(Note note) async {
    await _upsertNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> _toggleFavorite(Note note) async {
    await _upsertNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  List<Note> get _filteredNotes {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _notes.where((note) {
      if (_onlyFavorites && !note.isFavorite) return false;
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  Future<void> _openNoteDetail([Note? existingNote]) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteDetailPage(
          note: existingNote,
          isDarkMode: widget.isDarkMode,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );

    if (result == null) return;

    if (result['action'] == 'save' && result['note'] is Note) {
      await _upsertNote(result['note'] as Note);
    } else if (result['action'] == 'delete' && result['note'] is Note) {
      await _deleteNote(result['note'] as Note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesList = _filteredNotes;
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NoteThemeHelper.primaryAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: NoteThemeHelper.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notes',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _onlyFavorites ? 'Tampilkan Semua' : 'Filter Favorit',
            onPressed: () {
              setState(() {
                _onlyFavorites = !_onlyFavorites;
              });
            },
            icon: Icon(
              _onlyFavorites
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _onlyFavorites ? NoteThemeHelper.primaryAccent : null,
            ),
          ),
          IconButton(
            tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
            onPressed: _toggleViewMode,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
                key: ValueKey(_isGridView),
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: widget.onToggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? Colors.amberAccent : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? NoteThemeHelper.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari judul atau isi catatan...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : notesList.isEmpty
                    ? _buildEmptyState(isDark)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isGridView
                            ? _buildGridView(notesList)
                            : _buildListView(notesList),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteDetail(),
        backgroundColor: NoteThemeHelper.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Catatan',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
    );
  }

  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      key: const ValueKey('grid_view'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.84,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildDismissibleNote(note, isGrid: true);
      },
    );
  }

  Widget _buildListView(List<Note> notes) {
    return ListView.separated(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildDismissibleNote(note, isGrid: false);
      },
    );
  }

  Widget _buildDismissibleNote(Note note, {required bool isGrid}) {
    return Dismissible(
      key: ValueKey('dismiss_${note.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNote(note),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: NoteCard(
        note: note,
        isDarkMode: widget.isDarkMode,
        isGrid: isGrid,
        onTap: () => _openNoteDetail(note),
        onTogglePin: () => _togglePin(note),
        onToggleFavorite: () => _toggleFavorite(note),
        onDelete: () => _deleteNote(note),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isFiltering = _searchQuery.isNotEmpty || _onlyFavorites;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: NoteThemeHelper.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltering
                    ? Icons.search_off_rounded
                    : Icons.note_alt_outlined,
                size: 44,
                color: NoteThemeHelper.primaryAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltering ? 'Catatan tidak ditemukan' : 'Belum ada catatan',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? 'Coba gunakan kata kunci lain atau matikan filter favorit.'
                  : 'Ketuk tombol + Catatan di bawah untuk mulai menulis ide Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. KOMPONEN KARTU CATATAN (NOTE CARD WIDGET)
// ============================================================================
class NoteCard extends StatelessWidget {
  final Note note;
  final bool isDarkMode;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.isDarkMode,
    required this.isGrid,
    required this.onTap,
    required this.onTogglePin,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = NoteThemeHelper.getNoteColor(note.colorIndex, isDarkMode);
    final borderColor = note.isPinned
        ? NoteThemeHelper.primaryAccent.withValues(alpha: 0.5)
        : (isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: note.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.22 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Tanpa Judul' : note.title,
                    maxLines: isGrid ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: note.title.isEmpty
                          ? (isDarkMode ? Colors.grey[500] : Colors.grey[400])
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _MiniIconButton(
                  icon: note.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: note.isPinned
                      ? NoteThemeHelper.primaryAccent
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                  tooltip: note.isPinned ? 'Lepas Pin' : 'Sematkan',
                  onTap: onTogglePin,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isGrid)
              Expanded(
                child: Text(
                  note.content.isEmpty ? 'Tidak ada isi catatan' : note.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              )
            else
              Text(
                note.content.isEmpty ? 'Tidak ada isi catatan' : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    NoteThemeHelper.formatDate(note.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                _MiniIconButton(
                  icon: note.isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: note.isFavorite
                      ? Colors.amber[700]
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                  tooltip: 'Favorit',
                  onTap: onToggleFavorite,
                ),
                const SizedBox(width: 4),
                _MiniIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  tooltip: 'Hapus',
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ============================================================================
// 6. HALAMAN TAMBAH / EDIT CATATAN (NOTE DETAIL PAGE)
// ============================================================================
class NoteDetailPage extends StatefulWidget {
  final Note? note;
  final bool isDarkMode;

  const NoteDetailPage({
    super.key,
    this.note,
    required this.isDarkMode,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late int _selectedColorIndex;
  late bool _isPinned;
  late bool _isFavorite;
  late DateTime _noteDate;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedColorIndex = widget.note?.colorIndex ?? 0;
    _isPinned = widget.note?.isPinned ?? false;
    _isFavorite = widget.note?.isFavorite ?? false;
    _noteDate = widget.note?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Judul atau isi catatan tidak boleh kosong'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final savedNote = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      colorIndex: _selectedColorIndex,
      isPinned: _isPinned,
      isFavorite: _isFavorite,
    );

    Navigator.of(context).pop({'action': 'save', 'note': savedNote});
  }

  void _handleDelete() {
    if (widget.note == null) return;
    Navigator.of(context).pop({'action': 'delete', 'note': widget.note});
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NoteThemeHelper.getNoteColor(
      _selectedColorIndex,
      widget.isDarkMode,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              tooltip: _isPinned ? 'Lepas Pin' : 'Sematkan',
              onPressed: () => setState(() => _isPinned = !_isPinned),
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned ? NoteThemeHelper.primaryAccent : null,
              ),
            ),
            IconButton(
              tooltip: _isFavorite ? 'Hapus Favorit' : 'Tandai Favorit',
              onPressed: () => setState(() => _isFavorite = !_isFavorite),
              icon: Icon(
                _isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: _isFavorite ? Colors.amber[700] : null,
              ),
            ),
            if (_isEditing)
              IconButton(
                tooltip: 'Hapus Catatan',
                onPressed: _handleDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: NoteThemeHelper.primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    NoteThemeHelper.formatDate(_noteDate),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: widget.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        autofocus: !_isEditing,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Judul Catatan...',
                          hintStyle: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentController,
                        autofocus: _isEditing,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: widget.isDarkMode
                              ? Colors.grey[200]
                              : Colors.grey[850],
                        ),
                        decoration: InputDecoration(
                          hintText: 'Mulai ketik catatan Anda di sini...',
                          hintStyle: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.75),
                  border: Border(
                    top: BorderSide(
                      color: widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    NoteThemeHelper.lightNoteColors.length,
                    (index) {
                      final color = NoteThemeHelper.getNoteColor(
                        index,
                        widget.isDarkMode,
                      );
                      final isSelected = _selectedColorIndex == index;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? NoteThemeHelper.primaryAccent
                                  : (widget.isDarkMode
                                      ? Colors.white24
                                      : Colors.black12),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: NoteThemeHelper.primaryAccent
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: NoteThemeHelper.primaryAccent,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
