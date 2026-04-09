// screens/player_screen.dart — Плеер KinoVibe
// Двухэтапная загрузка: webpage_url → /stream → прямой mp4

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'room_screen.dart';

class PlayerScreen extends StatefulWidget {
  final MovieItem movie;
  const PlayerScreen({super.key, required this.movie});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _ctrl;

  // Три состояния загрузки
  bool _resolving = false;   // резолвим stream URL через сервер
  bool _buffering = false;   // плеер инициализируется
  bool _ready     = false;   // готов к воспроизведению
  String? _error;

  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _resolveAndPlay();
  }

  Future<void> _resolveAndPlay() async {
    setState(() { _resolving = true; _error = null; });

    String streamUrl;
    try {
      // Шаг 1: получить прямую ссылку на поток
      streamUrl = await ApiService.getStreamUrl(widget.movie.url);
    } catch (e) {
      if (mounted) setState(() { _resolving = false; _error = 'Не удалось получить поток:\n$e'; });
      return;
    }

    if (!mounted) return;
    setState(() { _resolving = false; _buffering = true; });

    // Шаг 2: инициализировать VideoPlayer с прямым URL
    try {
      _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: {
          // YouTube требует эти заголовки иначе 403
          'User-Agent': 'Mozilla/5.0 (Android; Mobile) AppleWebKit/537.36',
          'Referer': 'https://www.youtube.com/',
        },
      );
      await _ctrl!.initialize();
      _ctrl!.addListener(_onTick);
      await _ctrl!.play();
      if (mounted) setState(() { _buffering = false; _ready = true; });
    } catch (e) {
      if (mounted) setState(() { _buffering = false; _error = 'Ошибка плеера:\n$e'; });
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _openRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomScreen(movie: widget.movie)),
    );
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onTick);
    _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── Видео-область ──────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: AspectRatio(
              aspectRatio: (_ready && _ctrl != null)
                  ? _ctrl!.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Видео (когда готов)
                  if (_ready && _ctrl != null) VideoPlayer(_ctrl!),

                  // Плейсхолдер (пока грузимся)
                  if (!_ready && _error == null)
                    Container(color: Colors.black),

                  // Индикатор состояния
                  if (!_ready && _error == null)
                    _buildLoadingOverlay(),

                  // Ошибка
                  if (_error != null)
                    _buildErrorOverlay(),

                  // Управление (поверх видео)
                  if (_ready && _showControls && _ctrl != null)
                    _buildControls(),
                ],
              ),
            ),
          ),

          // ── Инфо и кнопки ─────────────────────────────────
          if (!_isFullscreen)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      style: const TextStyle(
                        color: KinoColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.movie.channel,
                      style: const TextStyle(color: KinoColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openRoom,
                      icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                      label: const Text('Смотреть вместе'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KinoColors.bronze,
                        foregroundColor: KinoColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Оверлей загрузки ──────────────────────────────────────
  Widget _buildLoadingOverlay() {
    final msg = _resolving ? 'Получаем ссылку...' : 'Загрузка видео...';
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: KinoColors.bronze,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: const TextStyle(color: KinoColors.textSecondary, fontSize: 13),
          ),
          if (!_resolving) ...[
            const SizedBox(height: 8),
            Text(
              widget.movie.title,
              style: const TextStyle(color: KinoColors.muted, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Оверлей ошибки ────────────────────────────────────────
  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resolveAndPlay,
            style: ElevatedButton.styleFrom(backgroundColor: KinoColors.bronze),
            child: const Text('Попробовать снова',
                style: TextStyle(color: KinoColors.background)),
          ),
        ],
      ),
    );
  }

  // ── Кнопки управления ─────────────────────────────────────
  Widget _buildControls() {
    final isPlaying = _ctrl!.value.isPlaying;
    final pos = _ctrl!.value.position;
    final dur = _ctrl!.value.duration;
    final progress = dur.inMilliseconds > 0
        ? pos.inMilliseconds / dur.inMilliseconds
        : 0.0;

    return Container(
      color: Colors.black45,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Прогресс-бар
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: KinoColors.bronze,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: KinoColors.gold,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      trackHeight: 2,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) {
                        final ms = (v * dur.inMilliseconds).toInt();
                        _ctrl!.seekTo(Duration(milliseconds: ms));
                      },
                    ),
                  ),
                ),
                Text(_fmt(dur), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),

          // Кнопки
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ctrlBtn(Icons.replay_10, () {
                _ctrl!.seekTo(pos - const Duration(seconds: 10));
              }),
              _ctrlBtn(
                isPlaying ? Icons.pause : Icons.play_arrow,
                () => isPlaying ? _ctrl!.pause() : _ctrl!.play(),
                size: 40,
              ),
              _ctrlBtn(Icons.forward_10, () {
                _ctrl!.seekTo(pos + const Duration(seconds: 10));
              }),
              _ctrlBtn(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                _toggleFullscreen,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, {double size = 28}) =>
      IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onTap,
        splashRadius: 20,
      );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
