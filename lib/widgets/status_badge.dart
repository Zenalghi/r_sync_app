import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated pulse dot and status badge widget indicating ESP32 connection state.
class StatusBadge extends StatelessWidget {
  final bool isConnected;
  final String ip;
  final String wifiStatus;
  final String time;

  const StatusBadge({
    super.key,
    required this.isConnected,
    required this.ip,
    required this.wifiStatus,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? (isDark
                ? AppColors.tealDark.withValues(alpha: 0.3)
                : AppColors.tealContainer)
            : (isDark
                ? AppColors.darkCard
                : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.teal.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(isActive: isConnected),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isConnected ? (ip.isNotEmpty ? ip : 'ESP32 Terhubung') : 'ESP32 Terputus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isConnected
                      ? (isDark ? AppColors.tealLight : AppColors.tealDark)
                      : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
                ),
              ),
              if (isConnected && time.isNotEmpty && !time.contains('Not Synced'))
                Text(
                  time.split(' ').length > 1 ? time.split(' ')[1] : time,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool isActive;

  const _PulsingDot({required this.isActive});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.emerald,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
