import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RunControls extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RunControls({
    super.key,
    required this.isTracking,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xE6161616),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, size: 18, color: AppTheme.accent.withValues(alpha: 0.85)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTracking
                          ? 'Run or ride until your path closes back near the start — hexes inside the loop claim automatically.'
                          : 'Tap start, move until your GPS path forms a closed shape; territory fills in with no extra buttons.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isTracking ? onStop : onStart,
                borderRadius: BorderRadius.circular(40),
                child: Ink(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTracking ? const Color(0xFFE53935) : AppTheme.accent,
                    boxShadow: [
                      BoxShadow(
                        color: (isTracking ? const Color(0xFFE53935) : AppTheme.accent).withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isTracking ? 'Stop session' : 'Start tracking',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
