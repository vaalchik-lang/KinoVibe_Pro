// screens/local_file_screen.dart — Выбор и воспроизведение локальных файлов
// Раздаёт файл через встроенный HTTP-сервер → другие участники комнаты
// могут подключиться по адресу http://<твой_ip>:8765/video

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/movie_model.dart';
import '../services/webrtc_service.dart';
import '../theme/app_theme.dart';

// ─── Встроенный HTTP-сервер для раздачи локального файла ──────────────────────

class LocalFileServer {
  static HttpServer? _server;
  static String? _filePath;
  static const int _port = 8765;

  static Future<String?> start(String filePath) async {
    await stop();
    _filePath = filePath;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _server!.listen(_handleRequest);
      final ip = await _getLocalIp();
      return 'http://$ip:$_port/video';
    } catch (e) {
      return null;
    }
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _filePath = null;
  }

  static void _handleRequest(HttpRequest req) async {
    if (_filePath == null) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    final file = File(_filePath!);
    if (!await file.exists()) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }

    final fileSize = await file.length();
    final rangeHeader = req.headers.value('range');

    // Поддержка Range requests (нужна для перемотки)
    if (rangeHeader != null) {
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
      if (match != null) {
        final start = int.parse(match.group(1)!);
        final end = match.group(2)!.isNotEmpty
            ? int.parse(match.group(2)!)
            : fileSize - 1;
        final length = end - start + 1;

        req.response.statusCode = 206;
        req.response.headers
          ..set('Content-Type', _mimeType(_filePath!))
          ..set('Content-Range', 'bytes $start-$end/$fileSize')
          ..set('Accept-Ranges', 'bytes')
          ..set('Content-Length', '$length');

        final stream = file.openRead(start, end + 1);
        await req.response.addStream(stream);
        await req.response.close();
        return;
      }
    }

    req.response.statusCode = 200;
    req.response.headers
      ..set('Content-Type', _mimeType(_filePath!))
      ..set('Content-Length', '$fileSize')
      ..set('Accept-Ranges', 'bytes');
    await req.response.addStream(file.openRead());
    await req.response.close();
  }

  static String _mimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return const {
      'mp4': 'video/mp4',
      'mkv': 'video/x-matroska',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
    }[ext] ?? 'video/mp4';
  }

  static Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }
}

// ─── Экран выбора и воспроизведения локального файла ─────────────────────────

class LocalFileScreen extends StatefulWidget {
  const LocalFileScreen({super.key});

  @override
  State<LocalFileScreen> createState() => _LocalFileScreenState();
}

class _LocalFileScreenState extends State<LocalFileScreen> {
  VideoPlayerController? _ctrl;
  String? _filePath;
  String? _streamUrl; // URL для раздачи друзьям
  bool _loading = false;
  bool _ready = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  String? _error;

  @override
  void dispose() {
    _ctrl?.dispose();
    LocalFileServer.stop();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    setState(() { _loading = true; _error = null; _ready = false; });

    // Остановить предыдущее
    _ctrl?.dispose();
    _ctrl = null;
    await LocalFileServer.stop();

    _filePath = path;

    // Запустить HTTP-сервер для раздачи файла
    final url = await LocalFileServer.start(path);
    _streamUrl = url;

    // Инициализировать плеер с локального файла напрямую
    try {
      _ctrl = VideoPlayerController.file(File(path));
      await _ctrl!.initialize();
      _ctrl!.addListener(() { if (mounted) setState(() {}); });
      await _ctrl!.play();
      setState(() { _loading = false; _ready = true; });
    } catch (e) {
      setState(() { _loading = false; _error = 'Ошибка плеера: $e'; });
    }
  }

  void _openRoom() {
    if (_filePath == null || _streamUrl == null) return;
    final fileName = _filePath!.split('/').last;
    // Создаём MovieItem из локального файла
    // url = streamUrl (http://ip:8765/video) — именно его увидят участники комнаты
    final movie = MovieItem(
      title: fileName,
      url: _streamUrl!,
      thumbnail: '',
      duration: _ctrl?.value.duration.inSeconds ?? 0,
      viewCount: 0,
      channel: 'Локальный файл',
      uploadDate: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LocalRoomScreen(movie: movie, localUrl: _streamUrl!),
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : AppBar(
        backgroundColor: KinoColors.surface,
        foregroundColor: KinoColors.textPrimary,
        title: const Text('Локальный файл', style: TextStyle(fontSize: 16)),
        actions: [
          if (_streamUrl != null)
            IconButton(
              icon: const Icon(Icons.group, color: KinoColors.bronze),
              tooltip: 'Смотреть вместе',
              onPressed: _openRoom,
            ),
        ],
      ),
      body: Column(children: [
        // ── Видео-область ──────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: AspectRatio(
            aspectRatio: (_ready && _ctrl != null) ? _ctrl!.value.aspectRatio : 16 / 9,
            child: Stack(alignment: Alignment.center, children: [
              if (_ready && _ctrl != null) VideoPlayer(_ctrl!),
              if (!_ready && _error == null) Container(color: Colors.black),
              if (_loading)
                const CircularProgressIndicator(color: KinoColors.bronze, strokeWidth: 2),
              if (_error != null) _buildError(),
              if (!_ready && !_loading && _error == null) _buildPickButton(),
              if (_ready && _showControls && _ctrl != null) _buildControls(),
            ]),
          ),
        ),

        // ── Нижняя панель ──────────────────────────────────────
        if (!_isFullscreen)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_filePath != null) ...[
                  Text(
                    _filePath!.split('/').last,
                    style: const TextStyle(color: KinoColors.textPrimary,
                        fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(_filePath == null ? 'Выбрать файл' : 'Сменить файл'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KinoColors.surface,
                    foregroundColor: KinoColors.textPrimary,
                  ),
                ),
                if (_streamUrl != null && _ready) ...[
                  const SizedBox(height: 16),
                  const Divider(color: KinoColors.surface),
                  const SizedBox(height: 8),
                  const Text('Смотреть вместе',
                      style: TextStyle(color: KinoColors.bronze, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Файл раздаётся по локальной сети. Друзья должны быть в той же Wi-Fi сети.',
                    style: TextStyle(color: KinoColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: KinoColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(_streamUrl!,
                            style: const TextStyle(color: KinoColors.muted, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: KinoColors.bronze),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _streamUrl!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL скопирован')),
                          );
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openRoom,
                    icon: const Icon(Icons.group, size: 18),
                    label: const Text('Открыть комнату'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KinoColors.bronze,
                      foregroundColor: KinoColors.background,
                    ),
                  ),
                ],
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildPickButton() => GestureDetector(
    onTap: _pickFile,
    child: Container(
      color: Colors.black87,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.video_file, color: KinoColors.bronze.withOpacity(0.6), size: 64),
        const SizedBox(height: 16),
        const Text('Нажмите чтобы выбрать видеофайл',
            style: TextStyle(color: KinoColors.textSecondary, fontSize: 14)),
      ]),
    ),
  );

  Widget _buildError() => Container(
    color: Colors.black87,
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _pickFile,
        style: ElevatedButton.styleFrom(backgroundColor: KinoColors.bronze),
        child: const Text('Выбрать другой файл',
            style: TextStyle(color: KinoColors.background)),
      ),
    ]),
  );

  Widget _buildControls() {
    final isPlaying = _ctrl!.value.isPlaying;
    final pos = _ctrl!.value.position;
    final dur = _ctrl!.value.duration;
    final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return Container(
      color: Colors.black45,
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
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
                    _ctrl!.seekTo(Duration(milliseconds: (v * dur.inMilliseconds).toInt()));
                  },
                ),
              ),
            ),
            Text(_fmt(dur), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn(Icons.replay_10, () => _ctrl!.seekTo(pos - const Duration(seconds: 10))),
          _btn(isPlaying ? Icons.pause : Icons.play_arrow,
              () => isPlaying ? _ctrl!.pause() : _ctrl!.play(), size: 40),
          _btn(Icons.forward_10, () => _ctrl!.seekTo(pos + const Duration(seconds: 10))),
          _btn(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, _toggleFullscreen),
        ]),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {double size = 28}) =>
      IconButton(icon: Icon(icon, color: Colors.white, size: size), onPressed: onTap);

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Комната для локального файла ─────────────────────────────────────────────
// Работает как обычный RoomScreen но с URL локального HTTP-сервера

class _LocalRoomScreen extends StatefulWidget {
  final MovieItem movie;
  final String localUrl;
  const _LocalRoomScreen({required this.movie, required this.localUrl});

  @override
  State<_LocalRoomScreen> createState() => _LocalRoomScreenState();
}

class _LocalRoomScreenState extends State<_LocalRoomScreen> {
  late final WebRTCService _rtc;
  VideoPlayerController? _video;

  bool _connected = false;
  bool _videoReady = false;
  String? _roomId;
  int _peersCount = 0;
  bool _isSyncing = false;

  final List<String> _chat = [];
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  StreamSubscription? _syncSub, _peerSub, _chatSub, _errSub;

  @override
  void initState() {
    super.initState();
    _rtc = WebRTCService();
    _init();
  }

  Future<void> _init() async {
    await _rtc.connect();
    _syncSub = _rtc.onSync.listen(_onSync);
    _peerSub = _rtc.onPeer.listen(_onPeer);
    _chatSub = _rtc.onChat.listen(_onChat);
    _errSub  = _rtc.onError.listen(_onError);

    final id = await _rtc.createRoom(
      mUrl: widget.localUrl,   // ← участники получат этот URL и откроют напрямую
      mTitle: widget.movie.title,
    );
    setState(() { _roomId = id; _connected = true; _peersCount = 1; });
    await _initVideo(widget.localUrl);
  }

  Future<void> _initVideo(String url) async {
    // Если это локальный HTTP-сервер на том же устройстве — играем напрямую через File
    // Если это чужой HTTP-сервер — играем через networkUrl
    VideoPlayerController ctrl;
    if (url.contains('127.0.0.1') || url.contains('localhost')) {
      final path = LocalFileServer._filePath;
      if (path != null) {
        ctrl = VideoPlayerController.file(File(path));
      } else {
        ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      }
    } else {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    try {
      await ctrl.initialize();
      ctrl.addListener(() { if (mounted) setState(() {}); });
      _video = ctrl;
      setState(() => _videoReady = true);
    } catch (e) {
      _onError('Ошибка плеера: $e');
    }
  }

  void _onSync(SyncEvent event) {
    if (_video == null || !_videoReady) return;
    _isSyncing = true;
    final pos = Duration(milliseconds: (event.positionSec * 1000).toInt());
    _video!.seekTo(pos).then((_) {
      if (event.action == SyncAction.play) _video!.play();
      else if (event.action == SyncAction.pause) _video!.pause();
      Future.delayed(const Duration(milliseconds: 300), () => _isSyncing = false);
      if (mounted) setState(() {});
    });
  }

  void _onPeer(PeerEvent e) {
    setState(() { _peersCount = _rtc.peersCount; _chat.add(e.joined ? '👤 Присоединился' : '👤 Вышел'); });
    _scrollToBottom();
  }

  void _onChat(String msg) { setState(() => _chat.add(msg)); _scrollToBottom(); }
  void _onError(String e) { setState(() => _chat.add('⚠️ $e')); }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  void _sendSync(String action) {
    if (_video == null || _isSyncing) return;
    final pos = _video!.value.position.inMilliseconds / 1000.0;
    if (action == 'play') _rtc.sendPlay(pos);
    else if (action == 'pause') _rtc.sendPause(pos);
  }

  @override
  void dispose() {
    _syncSub?.cancel(); _peerSub?.cancel();
    _chatSub?.cancel(); _errSub?.cancel();
    _video?.dispose();
    _rtc.dispose();
    _chatCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinoColors.background,
      appBar: AppBar(
        backgroundColor: KinoColors.surface,
        foregroundColor: KinoColors.textPrimary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.movie.title, style: const TextStyle(fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('$_peersCount участников · Комната $_roomId',
              style: const TextStyle(fontSize: 11, color: KinoColors.bronze)),
        ]),
        actions: [
          if (_roomId != null)
            IconButton(
              icon: const Icon(Icons.share, color: KinoColors.bronze),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _roomId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Код комнаты скопирован: $_roomId')),
                );
              },
            ),
        ],
      ),
      body: Column(children: [
        // Видео
        if (_videoReady && _video != null)
          AspectRatio(
            aspectRatio: _video!.value.aspectRatio,
            child: GestureDetector(
              onTap: () {
                if (_video!.value.isPlaying) {
                  _video!.pause(); _sendSync('pause');
                } else {
                  _video!.play(); _sendSync('play');
                }
              },
              child: VideoPlayer(_video!),
            ),
          )
        else
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator(color: KinoColors.bronze)),
          ),

        // Код комнаты + инструкция
        if (_roomId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: KinoColors.surface,
            child: Row(children: [
              const Icon(Icons.people, color: KinoColors.bronze, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Код: $_roomId  ·  Друзья должны быть в той же сети',
                  style: const TextStyle(color: KinoColors.textSecondary, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: KinoColors.bronze),
                onPressed: () => Clipboard.setData(ClipboardData(text: _roomId!)),
              ),
            ]),
          ),

        // Чат
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _chat.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(_chat[i],
                  style: const TextStyle(color: KinoColors.textSecondary, fontSize: 13)),
            ),
          ),
        ),

        // Поле ввода чата
        SafeArea(
          child: Container(
            color: KinoColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  style: const TextStyle(color: KinoColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Сообщение...',
                    hintStyle: TextStyle(color: KinoColors.muted),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _rtc.sendChat(text.trim());
                      _chatCtrl.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: KinoColors.bronze, size: 20),
                onPressed: () {
                  final text = _chatCtrl.text.trim();
                  if (text.isNotEmpty) { _rtc.sendChat(text); _chatCtrl.clear(); }
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
