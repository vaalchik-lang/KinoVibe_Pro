// screens/home_screen.dart — Главный экран KinoVibe

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme/app_theme.dart';
import '../widgets/transformer_widget.dart';
import '../widgets/mood_dialog.dart';
import '../widgets/movie_card.dart';
import '../services/api_service.dart';
import '../models/movie_model.dart';
import 'player_screen.dart';
import 'join_room_screen.dart';
import 'local_file_screen.dart'; // Импорт нового экрана

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'movies';
  bool _isLoading = false;
  String? _error;
  SearchResult? _result;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _category = category;
      _result = null;
    });
  }

  void _onMicTap() async {
    if (!_speechAvailable) {
      _showMoodDialog();
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _doSearch(result.recognizedWords);
        }
      },
      localeId: 'ru_RU',
    );
  }

  void _onMicLongPress() => _showMoodDialog();

  void _showMoodDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MoodDialog(
        category: _category,
        onSubmit: (text) {
          Navigator.pop(context);
          _doSearch(text);
        },
      ),
    );
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ApiService.search(query: query, category: _category);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  void _openPlayer(MovieItem movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinoColors.background,
      // Используем Column для размещения нескольких FAB
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'local_files_btn', // Уникальный тег
            backgroundColor: KinoColors.surface,
            foregroundColor: KinoColors.bronze,
            tooltip: 'Локальные файлы',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocalFileScreen()),
            ),
            child: const Icon(Icons.folder_open),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'join_room_btn', // Уникальный тег
            backgroundColor: KinoColors.surface,
            foregroundColor: KinoColors.bronze,
            tooltip: 'Войти в комнату',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
            ),
            child: const Icon(Icons.meeting_room_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Фоновое свечение
          Container(decoration: const BoxDecoration(gradient: KinoGradients.bronzeGlow)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Заголовок
                Text(
                  'KinoVibe',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  _categoryLabel(_category),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Трансформер
                TransformerWidget(
                  onCategorySelected: _onCategorySelected,
                  onMicTap: _onMicTap,
                  onMicLongPress: _onMicLongPress,
                ),

                const SizedBox(height: 16),

                // Стрелка вниз (диалог настроения)
                _ArrowButton(
                  onTap: _showMoodDialog,
                  pulsing: true,
                ),

                const SizedBox(height: 24),

                // Результаты
                Expanded(
                  child: _buildResults(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KinoColors.bronze),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (_result == null) {
      return const Center(
        child: Text(
          'Открой трансформер и опиши настроение',
          style: TextStyle(color: KinoColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_result!.results.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено. Попробуй другой запрос.',
          style: TextStyle(color: KinoColors.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.search, color: KinoColors.bronze, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"${_result!.query}"',
                  style: const TextStyle(color: KinoColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_result!.results.length} фильмов',
                style: const TextStyle(color: KinoColors.bronze, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _result!.results.length,
            itemBuilder: (_, i) => MovieCard(
              movie: _result!.results[i],
              onTap: () => _openPlayer(_result!.results[i]),
            ),
          ),
        ),
      ],
    );
  }

  String _categoryLabel(String cat) => const {
    'movies':  'Фильмы',
    'series':  'Сериалы',
    'shorts':  'Короткометражки',
    'anime':   'Аниме',
  }[cat] ?? 'Фильмы';
}

// ─── Стрелка вниз ─────────────────────────────────────────────────────────────
class _ArrowButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool pulsing;
  const _ArrowButton({required this.onTap, this.pulsing = false});

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, widget.pulsing ? _anim.value : 0),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KinoColors.surface,
            border: Border.all(color: KinoColors.bronze.withOpacity(0.6)),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: KinoColors.bronze,
            size: 28,
          ),
        ),
      ),
    );
  }
}
