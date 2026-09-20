import 'package:flutter/material.dart';
import 'pressable_scale.dart';

class WidgetGuideDialog extends StatelessWidget {
  const WidgetGuideDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const WidgetGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2130), Color(0xFF161824)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2C3246), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.widgets_rounded,
                        color: Color(0xFFFF3B30),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Screen Widget',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Preview upcoming wallpaper & control shuffle from home screen',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10121A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF222634), width: 0.8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WidgetStepRow(
                              step: '1',
                              text: 'Long-press any empty space on your Android home screen',
                            ),
                            SizedBox(height: 10),
                            _WidgetStepRow(
                              step: '2',
                              text: 'Select "Widgets" and find "Wall Tap"',
                            ),
                            SizedBox(height: 10),
                            _WidgetStepRow(
                              step: '3',
                              text: 'Drag it onto your home screen to preview and rotate wallpapers',
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFF222634), height: 1),
                            ),
                            _WidgetControlRow(
                              icon: Icons.preview_rounded,
                              title: 'Up Next',
                              description: 'Live preview of the next upcoming wallpaper',
                            ),
                            SizedBox(height: 8),
                            _WidgetControlRow(
                              icon: Icons.skip_next_rounded,
                              title: 'Next',
                              description: 'Instantly apply the previewed wallpaper',
                            ),
                            SizedBox(height: 8),
                            _WidgetControlRow(
                              icon: Icons.settings_rounded,
                              title: 'Settings',
                              description: 'Open Wall Tap configuration directly',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: PressableScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3B30), Color(0xFFFF5E3A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Got It',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetStepRow extends StatelessWidget {
  final String step;
  final String text;

  const _WidgetStepRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withAlpha(50),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _WidgetControlRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _WidgetControlRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
