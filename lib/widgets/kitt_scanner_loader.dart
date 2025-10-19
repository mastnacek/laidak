import 'package:flutter/material.dart';
import '../core/theme/theme_colors.dart';

/// KITT Scanner Loader - ikonický "Knight Rider" scanning efekt
///
/// Animovaný pruh, který se pohybuje tam a zpět (jako KITT z Knight Rider).
/// Použití při načítání AI tag suggestions.
///
/// Features:
/// - Smooth animace tam a zpět
/// - Gradient efekt pro futuristický vzhled
/// - Customizovatelná barva a rychlost
/// - Responsive šířka
class KittScannerLoader extends StatefulWidget {
  /// Barva scanning pruhu (default: červená jako KITT)
  final Color color;

  /// Šířka scanning pruhu (procenta z celkové šířky)
  final double scannerWidthRatio;

  /// Doba jednoho průchodu tam a zpět (ms)
  final int durationMs;

  /// Výška loaderu
  final double height;

  const KittScannerLoader({
    super.key,
    this.color = Colors.red,
    this.scannerWidthRatio = 0.3,
    this.durationMs = 1500,
    this.height = 4.0,
  });

  @override
  State<KittScannerLoader> createState() => _KittScannerLoaderState();
}

class _KittScannerLoaderState extends State<KittScannerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // AnimationController pro nekonečnou animaci
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );

    // Tween animace od 0.0 do 1.0 (pozice pruhu)
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Spustit repeat animaci (tam a zpět)
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Textový label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🤖 AI generuje tagy',
              style: TextStyle(
                fontSize: 12,
                color: theme.appColors.base5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // KITT Scanner
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scannerWidth = constraints.maxWidth * widget.scannerWidthRatio;

              return AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  // Vypočítat pozici scanning pruhu
                  final position = _animation.value * (constraints.maxWidth - scannerWidth);

                  return Stack(
                    children: [
                      // Pozadí (tmavá linka)
                      Container(
                        width: constraints.maxWidth,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: theme.appColors.base2,
                          borderRadius: BorderRadius.circular(widget.height / 2),
                        ),
                      ),

                      // Scanning pruh (s gradientem)
                      Positioned(
                        left: position,
                        child: Container(
                          width: scannerWidth,
                          height: widget.height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.0),
                                widget.color.withValues(alpha: 0.8),
                                widget.color,
                                widget.color.withValues(alpha: 0.8),
                                widget.color.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(widget.height / 2),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
