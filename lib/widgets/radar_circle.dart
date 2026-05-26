import 'package:flutter/material.dart';

class RadarCircle extends StatefulWidget {
  final bool saved;
  final VoidCallback onTap;
  final String placeName;
  final String city;
  final String district;
  final String category;

  const RadarCircle({
    super.key,
    required this.saved,
    required this.onTap,
    required this.placeName,
    required this.city,
    required this.district,
    required this.category,
  });
    @override
  State<RadarCircle> createState() => _RadarCircleState();
}

class _RadarCircleState extends State<RadarCircle>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {

    final color = widget.saved
        ? Colors.green
        : Colors.red;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 30 + (_controller.value * 20),
                  spreadRadius: 6,
                ),
              ],
              border: Border.all(
                color: color,
                width: 6,
              ),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🍽️',
                  style: TextStyle(fontSize: 42),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.placeName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '${widget.city}, ${widget.district}',
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 8),

                Text(
                  'Kategori: ${widget.category}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}