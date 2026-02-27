import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SmartNoteApp());
}

class SmartNoteApp extends StatelessWidget {
  const SmartNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Smart Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NoteStorage {
  static const String _key = 'smart_note_items';

  static Future<List<Note>> loadNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_key);

    if (rawJson == null || rawJson.isEmpty) {
      return <Note>[];
    }

    final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((dynamic item) => Note.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((Note a, Note b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String rawJson =
        jsonEncode(notes.map((Note note) => note.toJson()).toList());
    await prefs.setString(_key, rawJson);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<Note> _notes = <Note>[];
  String _searchKeyword = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final List<Note> loadedNotes = await NoteStorage.loadNotes();
    if (!mounted) {
      return;
    }

    setState(() {
      _notes = loadedNotes;
      _isLoading = false;
    });
  }

  Future<void> _openEditor({Note? note}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteDetailScreen(initialNote: note),
      ),
    );
    await _loadNotes();
  }

  List<Note> get _filteredNotes {
    if (_searchKeyword.trim().isEmpty) {
      return _notes;
    }

    final String keyword = _searchKeyword.toLowerCase().trim();
    return _notes
        .where((Note note) => note.title.toLowerCase().contains(keyword))
        .toList();
  }

  Future<bool?> _confirmDelete() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content:
              const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(Note note) async {
    setState(() {
      _notes.removeWhere((Note item) => item.id == note.id);
    });
    await NoteStorage.saveNotes(_notes);
  }

  List<Color> _cardPalette(ColorScheme colorScheme) {
    return <Color>[
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceContainerHigh,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<Color> palette = _cardPalette(colorScheme);
    final List<Note> filteredNotes = _filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Note - Phan Văn Tâm - 2351160549'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) {
                  setState(() {
                    _searchKeyword = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm theo tiêu đề...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Opacity(
                              opacity: 0.32,
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  Container(
                                    width: 128,
                                    height: 128,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Icon(
                                    Icons.sticky_note_2_rounded,
                                    size: 74,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bạn chưa có ghi chú nào, hãy tạo mới nhé!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : MasonryGridView.count(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: filteredNotes.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Note note = filteredNotes[index];
                          final Color cardColor =
                              palette[index % palette.length];
                          final Brightness cardBrightness =
                              ThemeData.estimateBrightnessForColor(cardColor);
                          final Color titleColor = cardBrightness ==
                                  Brightness.dark
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface;
                          final Color subtitleColor = titleColor.withValues(
                            alpha: 0.72,
                          );

                          return Dismissible(
                            key: ValueKey<String>(note.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Icon(
                                Icons.delete_rounded,
                                color: colorScheme.onError,
                              ),
                            ),
                            confirmDismiss: (DismissDirection direction) async {
                              final bool shouldDelete =
                                  await _confirmDelete() ?? false;
                              return shouldDelete;
                            },
                            onDismissed: (DismissDirection direction) {
                              _deleteNote(note);
                            },
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openEditor(note: note),
                              child: Card(
                                color: cardColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        note.title.trim().isEmpty
                                            ? '(Không tiêu đề)'
                                            : note.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content.trim().isEmpty
                                            ? '...'
                                            : note.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: subtitleColor,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          const SizedBox.shrink(),
                                          Text(
                                            _dateFormat.format(note.updatedAt),
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                theme.textTheme.bodySmall?.copyWith(
                                              color: subtitleColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, this.initialNote});

  final Note? initialNote;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _saved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController =
        TextEditingController(text: widget.initialNote?.title ?? '');
    _contentController =
        TextEditingController(text: widget.initialNote?.content ?? '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveIfNeeded();
    }
  }

  Future<void> _saveIfNeeded() async {
    if (_saved || _isSaving) {
      return;
    }

    _isSaving = true;
    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();

    if (widget.initialNote == null && title.isEmpty && content.isEmpty) {
      _saved = true;
      _isSaving = false;
      return;
    }

    try {
      final List<Note> notes = await NoteStorage.loadNotes();
      final DateTime now = DateTime.now();

      if (widget.initialNote == null) {
        notes.insert(
          0,
          Note(
            id: now.microsecondsSinceEpoch.toString(),
            title: title,
            content: content,
            updatedAt: now,
          ),
        );
      } else {
        final int index = notes.indexWhere(
          (Note item) => item.id == widget.initialNote!.id,
        );

        final Note updated = widget.initialNote!.copyWith(
          title: title,
          content: content,
          updatedAt: now,
        );

        if (index == -1) {
          notes.insert(0, updated);
        } else {
          notes[index] = updated;
        }
      }

      await NoteStorage.saveNotes(notes);
      _saved = true;
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _saveAndExit() async {
    final NavigatorState navigator = Navigator.of(context);
    await _saveIfNeeded();
    if (navigator.mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        await _saveAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saveAndExit,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            color: colorScheme.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _titleController,
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tiêu đề',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                      decoration: const InputDecoration(
                        hintText: 'Nội dung ghi chú...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
