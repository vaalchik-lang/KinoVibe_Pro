// services/webrtc_service.dart
// WebRTC P2P + WebSocket сигнализация + синхронизация плеера

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

// ─── События ──────────────────────────────────────────────────────────────────

enum SyncAction { play, pause, seek }

class SyncEvent {
  final SyncAction action;
  final double positionSec;
  const SyncEvent(this.action, this.positionSec);
}

class PeerEvent {
  final String peerId;
  final bool joined; // true=joined, false=left
  const PeerEvent(this.peerId, this.joined);
}

// ─── WebRTCService ────────────────────────────────────────────────────────────

class WebRTCService {
  // Идентификаторы
  late final String peerId;
  String? roomId;
  String? movieUrl;
  String? movieTitle;

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _pingTimer;

  // WebRTC
  final Map<String, RTCPeerConnection> _pcs = {};
  final _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // Стримы событий
  final _syncCtrl   = StreamController<SyncEvent>.broadcast();
  final _peerCtrl   = StreamController<PeerEvent>.broadcast();
  final _chatCtrl   = StreamController<String>.broadcast();
  final _errorCtrl  = StreamController<String>.broadcast();

  Stream<SyncEvent>  get onSync  => _syncCtrl.stream;
  Stream<PeerEvent>  get onPeer  => _peerCtrl.stream;
  Stream<String>     get onChat  => _chatCtrl.stream;
  Stream<String>     get onError => _errorCtrl.stream;

  int peersCount = 0;

  WebRTCService() {
    peerId = _generateId();
  }

  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  // ─── Подключение ────────────────────────────────────────────────────────────

  Future<void> connect() async {
    final wsUrl = ApiConfig.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/$peerId'));
    _wsSub = _channel!.stream.listen(
      _onMessage,
      onError: (e) => _errorCtrl.add('WS error: $e'),
      onDone: () => _errorCtrl.add('WS disconnected'),
    );
    _startPing();
    debugPrint('[WS] Connected as $peerId');
  }

  void _startPing() {
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _send({'type': 'ping'});
    });
  }

  // ─── Комнаты ────────────────────────────────────────────────────────────────

  Future<String> createRoom({
    required String mUrl,
    required String mTitle,
  }) async {
    movieUrl = mUrl;
    movieTitle = mTitle;
    _send({'type': 'create_room', 'movie_url': mUrl, 'movie_title': mTitle});
    
    final completer = Completer<String>();
    late StreamSubscription sub;
    sub = _errorCtrl.stream.listen((e) {
      if (!completer.isCompleted) completer.completeError(e);
      sub.cancel();
    });
    
    _pendingRoomCompleter = completer;
    _pendingRoomSub = sub;
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Completer<String>? _pendingRoomCompleter;
  StreamSubscription? _pendingRoomSub;

  Future<void> joinRoom(String rId) async {
    roomId = rId.toUpperCase();
    _send({'type': 'join_room', 'room_id': roomId});
  }

  // ─── Синхронизация ──────────────────────────────────────────────────────────

  void sendPlay(double positionSec) =>
      _send({'type': 'sync', 'action': 'play', 'position_sec': positionSec});

  void sendPause(double positionSec) =>
      _send({'type': 'sync', 'action': 'pause', 'position_sec': positionSec});

  void sendSeek(double positionSec) =>
      _send({'type': 'sync', 'action': 'seek', 'position_sec': positionSec});

  void sendChat(String text) =>
      _send({'type': 'chat', 'text': text});

  // ─── WebRTC peer connections ─────────────────────────────────────────────────

  Future<void> _createOffer(String toPeerId) async {
    final pc = await _getOrCreatePC(toPeerId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    _send({
      'type': 'offer',
      'to': toPeerId,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });
  }

  Future<void> _handleOffer(String fromId, String sdp, String type) async {
    final pc = await _getOrCreatePC(fromId);
    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    _send({
      'type': 'answer',
      'to': fromId,
      'sdp': answer.sdp,
      'sdpType': answer.type,
    });
  }

  Future<RTCPeerConnection> _getOrCreatePC(String peerId) async {
    if (_pcs.containsKey(peerId)) return _pcs[peerId]!;
    final pc = await createPeerConnection(_iceServers);
    _pcs[peerId] = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _send({
          'type': 'ice_candidate',
          'to': peerId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex, // ИСПРАВЛЕНО: L заглавная
        });
      }
    };
    pc.onConnectionState = (state) {
      debugPrint('[WebRTC] $peerId => $state');
    };
    return pc;
  }

  // ─── Обработка сообщений ────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String);
    } catch (_) {
      return;
    }
    final type = msg['type'] as String?;
    debugPrint('[WS] ← $type');

    switch (type) {
      case 'room_created':
        roomId = msg['room_id'] as String;
        _pendingRoomCompleter?.complete(roomId!);
        _pendingRoomSub?.cancel();
        _pendingRoomCompleter = null;
        _pendingRoomSub = null;

      case 'room_joined':
        roomId    = msg['room_id'] as String;
        movieUrl  = msg['movie_url'] as String?;
        movieTitle = msg['movie_title'] as String?;
        peersCount = (msg['peers_count'] as int?) ?? 0;
        final isPlaying   = msg['is_playing'] as bool? ?? false;
        final positionSec = (msg['position_sec'] as num?)?.toDouble() ?? 0.0;
        _syncCtrl.add(SyncEvent(
          isPlaying ? SyncAction.play : SyncAction.pause,
          positionSec,
        ));

      case 'peer_joined':
        peersCount = (msg['peers_count'] as int?) ?? peersCount;
        final pid = msg['peer_id'] as String;
        _peerCtrl.add(PeerEvent(pid, true));
        _createOffer(pid);

      case 'peer_left':
        peersCount = (msg['peers_count'] as int?) ?? peersCount;
        final pid = msg['peer_id'] as String;
        _pcs[pid]?.close();
        _pcs.remove(pid);
        _peerCtrl.add(PeerEvent(pid, false));

      case 'offer':
        _handleOffer(
          msg['from'] as String,
          msg['sdp'] as String,
          msg['sdpType'] as String,
        );

      case 'answer':
        final pc = _pcs[msg['from']];
        pc?.setRemoteDescription(RTCSessionDescription(
          msg['sdp'] as String,
          msg['sdpType'] as String,
        ));

      case 'ice_candidate':
        final pc = _pcs[msg['from']];
        pc?.addCandidate(RTCIceCandidate(
          msg['candidate'] as String,
          msg['sdpMid'] as String?,
          msg['sdpMLineIndex'] as int?, // ИСПРАВЛЕНО: L заглавная
        ));

      case 'sync':
        final action = msg['action'] as String;
        final pos = (msg['position_sec'] as num?)?.toDouble() ?? 0.0;
        _syncCtrl.add(SyncEvent(
          action == 'play' ? SyncAction.play : action == 'pause' ? SyncAction.pause : SyncAction.seek,
          pos,
        ));

      case 'chat':
        final from = msg['from_peer'] as String?;
        final text = msg['text'] as String?;
        if (text != null) _chatCtrl.add('$from: $text');

      case 'error':
        _errorCtrl.add(msg['msg'] as String? ?? 'unknown error');
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      debugPrint('[WS] Send error: $e');
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _pingTimer?.cancel();
    _wsSub?.cancel();
    _channel?.sink.close();
    for (final pc in _pcs.values) {
      await pc.close();
    }
    _pcs.clear();
    await _syncCtrl.close();
    await _peerCtrl.close();
    await _chatCtrl.close();
    await _errorCtrl.close();
  }
}
