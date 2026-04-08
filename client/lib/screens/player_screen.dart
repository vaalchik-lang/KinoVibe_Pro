// screens/player_screen.dart — Плеер KinoVibe

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/movie_model.dart';
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
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.movie.url));
      await _ctrl!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Player init error: $e');
    }
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
      MaterialPageRoute(
        builder: (_) => RoomScreen(movie: widget.movie),
      ),
    );
  }

  @override
  void dispose() {
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
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: AspectRatio(
              aspectRatio: _isInitialized ? _ctrl!.value.aspectRatio : 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _isInitialized
                      ? VideoPlayer(_ctrl!)
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: KinoColors.bronze,
                            ),
                          ),
                        ),
                  if (_showControls && _isInitialized) _buildControls(),
                ],
              ),
            ),
          ),
          if (!_isFullscreen) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.movie.channel,
                    style: Theme.of(context).textTheme.bodyMedium,
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
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white),
            onPressed: () {
              final pos = _ctrl!.value.position - const Duration(seconds: 10);
              _ctrl!.seekTo(pos);
            },
          ),
          IconButton(
            iconSize: 52,
            icon: Icon(
              _ctrl!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () => setState(() {
              _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: () {
              final pos = _ctrl!.value.position + const Duration(seconds: 10);
              _ctrl!.seekTo(pos);
            },
          ),
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
    );
  }
}
