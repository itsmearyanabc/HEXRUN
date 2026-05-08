import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  const LoadingOverlay({super.key, required this.isLoading, required this.child, this.message});
  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (isLoading) Container(color: Colors.black54, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Colors.white),
      if (message != null) ...[const SizedBox(height: 12), Text(message!, style: const TextStyle(color: Colors.white, fontSize: 16))],
    ]))),
  ]);
}

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorDisplay({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 64, color: Colors.red),
    const SizedBox(height: 16),
    Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
    if (onRetry != null) ...[const SizedBox(height: 16), ElevatedButton(onPressed: onRetry, child: const Text('Retry'))],
  ]));
}

class HexIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  const HexIconButton({super.key, required this.icon, required this.label, required this.onPressed, this.color});
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onPressed, icon: Icon(icon), label: Text(label),
    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
  );
}

class StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const StatChip({super.key, required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text('$value $label'), padding: const EdgeInsets.symmetric(horizontal: 8));
}