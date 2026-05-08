import 'package:flutter/material.dart';

/// Run start/stop controls overlay
class RunControls extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RunControls({super.key, required this.isTracking, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTracking)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton.extended(
              heroTag: 'capture',
              onPressed: () {},
              backgroundColor: Theme.of(context).colorScheme.secondary,
              icon: const Icon(Icons.hexagon),
              label: const Text('Capture'),
            ),
          ),
        FloatingActionButton.extended(
          heroTag: 'run',
          onPressed: isTracking ? onStop : onStart,
          backgroundColor: isTracking ? Colors.red : Colors.green,
          icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
          label: Text(isTracking ? 'Stop Run' : 'Start Run'),
        ),
      ],
    );
  }
}