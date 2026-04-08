// screens/room_screen.dart — Экран совместного просмотра

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/movie_model.dart';
import '../services/webrtc_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

class RoomScreen extends StatefulWidget {
  final MovieItem movie;
  final String? joinRoomId; // null = создать, строка = присоединиться

  const RoomScreen({
    super.key,
    required this.movie,
    this.joinRoomId,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final WebRTCService _rtc;
  VideoPlayerController? _video;

  bool _connected = false;
  bool _videoReady = false;
  String? _roomId;
  int _peersCount = 0;
  bool _isSyncing = false; // блокирует рекурсивные sync-события

  final List<String> _chat = [];
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  StreamSubscription? _syncSub;
  StreamSubscription? _peerSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _errSub;

  @override
  void initState() {
    super.initState();
    _rtc = WebRTCService();
    _initConnection();
  }

  Future<void> _initConnection() async {
    await _rtc.connect();

    _syncSub = _rtc.onSync.listen(_onSync);
    _peerSub = _rtc.onPeer.listen(_onPeer);
    _chatSub = _rtc.onChat.listen(_onChat);
    _errSub  = _rtc.onError.listen(_onError);

    if (widget.joinRoomId != null) {
      // Присоединяемся к существующей комнате
      await _rtc.joinRoom(widget.joinRoomId!);
      setState(() {
        _roomId = widget.joinRoomId;
        _connected = true;
      });
      // Видео получим из room_joined → movieUrl
    } else {
      // Создаём новую комнату
      final id = await _rtc.createRoom(
        mUrl: widget.movie.url,
        mTitle: widget.movie.title,
      );
      setState(() {
        _roomId = id;
        _connected = true;
        _peersCount = 1;
      });
      await _initVideo(widget.movie.url);
    }
  }

  Future<void> _initVideo(String url) async {
    _video = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _video!.initialize();
      _video!.addListener(_onVideoTick);
      setState(() => _videoReady = true);
    } catch (e) {
      _onError('Не удалось загрузить видео: $e');
    }
  }

  // Отправляем sync при изменении состояния плеера
  void _onVideoTick() {
    if (_isSyncing) return;
    // Отправляем только значимые изменения
  }

  void _onSync(SyncEvent event) {
    if (_video == null || !_videoReady) {
      // Ждём инициализации видео, потом применяем
      if (event.action == SyncAction.play ||
          event.action == SyncAction.pause) {
        // Сохраняем и применим после init
      }
      // Для join: получаем movieUrl из room_joined, тогда инициализируем
      if (_rtc.movieUrl != null && _video == null) {
        _initVideo(_rtc.movieUrl!);
      }
      return;
    }
    _isSyncing = true;
    final pos = Duration(milliseconds: (event.positionSec * 1000).toInt());
    _video!.seekTo(pos).then((_) {
      if (event.action == SyncAction.play) {
        _video!.play();
      } else if (event.action == SyncAction.pause) {
        _video!.pause();
      }
      Future.delayed(const Duration(milliseconds: 300), () => _isSyncing = false);
      if (mounted) setState(() {});
    });
  }

  void _onPeer(PeerEvent event) {
    setState(() => _peersCount = _rtc.peersCount);
    final msg = event.joined
        ? '👤 Участник присоединился'
        : '👤 Участник вышел';
    setState(() => _chat.add(msg));
    _scrollToBottom();
  }

  void _onChat(String msg) {
    setState(() => _chat.add(msg));
    _scrollToBottom();
  }

  void _onError(String e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Управление плеером (с отправкой sync) ──────────────────────────────────

  void _play() {
    if (_video == null) return;
    _video!.play();
    final pos = _video!.value.position.inMilliseconds / 1000.0;
    _rtc.sendPlay(pos);
    setState(() {});
  }

  void _pause() {
    if (_video == null) return;
    _video!.pause();
    final pos = _video!.value.position.inMilliseconds / 1000.0;
    _rtc.sendPause(pos);
    setState(() {});
  }

  void _seek(double pos) {
    if (_video == null) return;
    final dur = Duration(milliseconds: (pos * 1000).toInt());
    _video!.seekTo(dur);
    _rtc.sendSeek(pos);
    setState(() {});
  }

  String get _inviteLink {
    final base = ApiConfig.baseUrl;
    return '$base/room/$_roomId';
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка скопирована'),
        backgroundColor: KinoColors.bronze,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _rtc.sendChat(text);
    setState(() => _chat.add('Ты: $text'));
    _chatCtrl.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _peerSub?.cancel();
    _chatSub?.cancel();
    _errSub?.cancel();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _rtc.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinoColors.background,
      appBar: AppBar(
        backgroundColor: KinoColors.surface,
        title: Row(
          children: [
            const Icon(Icons.people, color: KinoColors.bronze, size: 18),
            const SizedBox(width: 6),
            Text(
              'Комната: ${_roomId ?? '...'}',
              style: const TextStyle(color: KinoColors.gold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: KinoColors.bronze.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_peersCount участн.',
                style: const TextStyle(color: KinoColors.bronze, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: KinoColors.gold),
            tooltip: 'Скопировать ссылку-приглашение',
            onPressed: _roomId != null ? _copyLink : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Видеоплеер
          _buildPlayer(),

          // Прогресс-бар
          if (_videoReady && _video != null) _buildSeekBar(),

          // Ссылка-приглашение
          if (_roomId != null) _buildInviteBanner(),

          // Чат
          Expanded(child: _buildChat()),

          // Поле ввода чата
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: !_videoReady
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: KinoColors.bronze),
                    const SizedBox(height: 12),
                    Text(
                      _connected ? 'Загрузка видео...' : 'Подключение...',
                      style: const TextStyle(color: KinoColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_video!),
                  // Управление
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ctrlBtn(Icons.replay_10, () {
                        final pos = _video!.value.position.inSeconds - 10;
                        _seek(pos.toDouble());
                      }),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _video!.value.isPlaying ? _pause : _play,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x80000000),
                          ),
                          child: Icon(
                            _video!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ctrlBtn(Icons.forward_10, () {
                        final pos = _video!.value.position.inSeconds + 10;
                        _seek(pos.toDouble());
                      }),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x60000000),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );

  Widget _buildSeekBar() {
    final dur = _video!.value.duration.inSeconds.toDouble();
    final pos = _video!.value.position.inSeconds.toDouble().clamp(0.0, dur);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            _fmt(_video!.value.position),
            style: const TextStyle(color: KinoColors.textSecondary, fontSize: 11),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: KinoColors.bronze,
                inactiveTrackColor: KinoColors.divider,
                thumbColor: KinoColors.gold,
                overlayColor: KinoColors.bronze.withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
              ),
              child: Slider(
                value: pos,
                min: 0,
                max: dur > 0 ? dur : 1,
                onChanged: _seek,
              ),
            ),
          ),
          Text(
            _fmt(_video!.value.duration),
            style: const TextStyle(color: KinoColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildInviteBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KinoColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KinoColors.bronze.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: KinoColors.bronze, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _inviteLink,
              style: const TextStyle(color: KinoColors.textSecondary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _copyLink,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KinoColors.bronze,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Копировать',
                style: TextStyle(
                  color: KinoColors.background,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    if (_chat.isEmpty) {
      return const Center(
        child: Text(
          'Чат пустой. Пригласи друга!',
          style: TextStyle(color: KinoColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _chat.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          _chat[i],
          style: const TextStyle(
            color: KinoColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      color: KinoColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatCtrl,
              style: const TextStyle(color: KinoColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Сообщение...',
                hintStyle: const TextStyle(color: KinoColors.textSecondary),
                filled: true,
                fillColor: KinoColors.cardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendChat(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendChat,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: KinoColors.bronze,
              ),
              child: const Icon(
                Icons.send,
                color: KinoColors.background,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
