// widgets/transformer_widget.dart
// Металлический диск 220px → 4 лепестка (70px разлёт) + микрофон

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

typedef CategoryCallback = void Function(String category);

class TransformerWidget extends StatefulWidget {
  final CategoryCallback onCategorySelected;
  final VoidCallback onMicTap;
  final VoidCallback onMicLongPress;

  const TransformerWidget({
    super.key,
    required this.onCategorySelected,
    required this.onMicTap,
    required this.onMicLongPress,
  });

  @override
  State<TransformerWidget> createState() => _TransformerWidgetState();
}

class _TransformerWidgetState extends State<TransformerWidget>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  // Лепестки: [category, label, icon, dx, dy]
  static const _petals = [
    ['movies',  'Фильмы',        Icons.movie,           -1.0, -1.0],
    ['series',  'Сериалы',       Icons.tv,               1.0, -1.0],
    ['shorts',  'Короткометражки', Icons.video_library, -1.0,  1.0],
    ['anime',   'Аниме',         Icons.animation,        1.0,  1.0],
  ];

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Лепестки
          ..._petals.map((p) => _buildPetal(p)),

          // Центральный диск
          GestureDetector(
            onTap: _toggle,
            child: _buildDisc(),
          ),

          // Микрофон (только при открытом состоянии)
          if (_isOpen)
            GestureDetector(
              onTap: widget.onMicTap,
              onLongPress: widget.onMicLongPress,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KinoColors.background,
                  border: Border.all(color: KinoColors.gold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: KinoColors.gold.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: KinoColors.gold, size: 24),
              ).animate().scale(duration: 200.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildDisc() {
    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (_, __) {
        final size = 220.0 - (_expandAnim.value * 60); // сжимается при открытии
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              radius: 0.9,
              colors: [Color(0xFFD4A843), Color(0xFF8B5E1A), Color(0xFF3D2506)],
            ),
            boxShadow: [
              BoxShadow(
                color: KinoColors.bronze.withOpacity(0.6 + _expandAnim.value * 0.3),
                blurRadius: 24 + _expandAnim.value * 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: _isOpen
              ? null
              : Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: KinoColors.gold,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: KinoColors.gold.withOpacity(0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .custom(
              duration: 2.seconds,
              builder: (_, value, child) => child!,
            );
      },
    );
  }

  Widget _buildPetal(List petal) {
    final category = petal[0] as String;
    final label    = petal[1] as String;
    final icon     = petal[2] as IconData;
    final dx       = petal[3] as double;
    final dy       = petal[4] as double;

    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (_, __) {
        final offset = _expandAnim.value * 90;
        return Transform.translate(
          offset: Offset(dx * offset, dy * offset),
          child: Opacity(
            opacity: _expandAnim.value,
            child: GestureDetector(
              onTap: () {
                widget.onCategorySelected(category);
                _toggle();
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KinoColors.surface,
                  border: Border.all(color: KinoColors.bronze, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: KinoColors.bronze.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: KinoColors.bronze, size: 22),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: const TextStyle(
                        color: KinoColors.textSecondary,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
