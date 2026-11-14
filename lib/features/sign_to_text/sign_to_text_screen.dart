import 'dart:math' as math;

import 'package:flutter/material.dart';

class SignToTextScreen extends StatefulWidget {
  const SignToTextScreen({super.key});

  @override
  State<SignToTextScreen> createState() => _SignToTextScreenState();
}

class _SignToTextScreenState extends State<SignToTextScreen> {
  bool _running = false;
  String _latestLabel = 'Waiting for a sign';
  double _confidence = 0.0;

  static const List<String> _mockLabels = [
    'HELLO',
    'THANK-YOU',
    'PLEASE',
    'HELP',
    'YES',
    'NO',
  ];

  Future<void> _simulateRecognition() async {
    if (_running) return;

    setState(() {
      _running = true;
      _latestLabel = 'Scanning hand landmarks…';
      _confidence = 0.0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final pick = _mockLabels[math.Random().nextInt(_mockLabels.length)];
    setState(() {
      _running = false;
      _latestLabel = pick;
      _confidence = 0.86 + (math.Random().nextDouble() * 0.12);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Center(
                  child: Icon(Icons.videocam_outlined, size: 64),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Live preview',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? null : _simulateRecognition,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(_running ? 'Recognising…' : 'Start mock recognition'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected phrase',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _latestLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Confidence'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _confidence.clamp(0.0, 1.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _confidence > 0.0
                        ? '${_confidence.toStringAsFixed(2)} / 1.00'
                        : 'No result yet',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
