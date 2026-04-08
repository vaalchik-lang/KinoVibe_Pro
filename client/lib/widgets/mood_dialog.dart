// widgets/mood_dialog.dart — Диалог настроения (стекломорфизм)

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoodDialog extends StatefulWidget {
  final String category;
  final ValueChanged<String> onSubmit;

  const MoodDialog({
    super.key,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<MoodDialog> createState() => _MoodDialogState();
}

class _MoodDialogState extends State<MoodDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    widget.onSubmit(text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: KinoColors.cardBg.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KinoColors.bronze.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: KinoColors.bronze.withOpacity(0.15),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                'Опиши своё настроение',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'KinoVibe найдёт фильм для тебя',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Поле ввода
              TextField(
                controller: _ctrl,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(color: KinoColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Например: грустно, хочу что-то тёплое...',
                  hintStyle: const TextStyle(color: KinoColors.textSecondary),
                  filled: true,
                  fillColor: KinoColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: KinoColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: KinoColors.bronze),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),

              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: KinoColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KinoColors.bronze,
                      foregroundColor: KinoColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KinoColors.background,
                            ),
                          )
                        : const Text('Найти'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
