// screens/join_room_screen.dart — Присоединиться к комнате по коду

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/movie_model.dart';
import 'room_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _ctrl = TextEditingController();

  void _join() {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length < 4) return;
    // Создаём заглушку-фильм (реальные данные придут с сервера через room_joined)
    final stub = MovieItem(
      title: 'Загрузка...',
      url: '',
      thumbnail: '',
      duration: 0,
      viewCount: 0,
      channel: '',
      uploadDate: '',
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          movie: stub,
          joinRoomId: code,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinoColors.background,
      appBar: AppBar(
        backgroundColor: KinoColors.surface,
        title: const Text(
          'Присоединиться к комнате',
          style: TextStyle(color: KinoColors.gold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: KinoColors.bronze),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введи код комнаты',
              style: TextStyle(
                color: KinoColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Попроси друга скопировать код из его комнаты.',
              style: TextStyle(color: KinoColors.textSecondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: KinoColors.gold,
                fontSize: 28,
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLength: 8,
              decoration: InputDecoration(
                hintText: 'AB12CD34',
                hintStyle: TextStyle(
                  color: KinoColors.textSecondary.withOpacity(0.4),
                  letterSpacing: 6,
                  fontSize: 28,
                ),
                counterStyle: const TextStyle(color: KinoColors.textSecondary),
                filled: true,
                fillColor: KinoColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: KinoColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: KinoColors.bronze, width: 2),
                ),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KinoColors.bronze,
                  foregroundColor: KinoColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Войти в комнату',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
