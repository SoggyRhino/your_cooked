import 'package:flutter/material.dart';

class PulseLoadAnimatedBox extends StatefulWidget {
  const PulseLoadAnimatedBox({super.key});

  @override
  State<PulseLoadAnimatedBox> createState() => _PulseLoadAnimatedBoxState();
}

class _PulseLoadAnimatedBoxState extends State<PulseLoadAnimatedBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.3,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(decoration: BoxDecoration(color: Colors.grey)),
    );
  }
}
