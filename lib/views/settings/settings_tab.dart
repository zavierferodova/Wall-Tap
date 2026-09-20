import 'package:flutter/material.dart';
import '../../controllers/wallpaper_controller.dart';
import '../widgets/pressable_scale.dart';

class SettingsTab extends StatelessWidget {
  final WallpaperController controller;

  const SettingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;

        int totalBytes = 0;
        for (final item in items) {
          totalBytes += item.fileSize;
        }
        final storageSizeText = totalBytes < 1024 * 1024
            ? '${(totalBytes / 1024).toStringAsFixed(1)} KB'
            : '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

        return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 150),
              children: [
            // Top Bar
            const Padding(
              padding: EdgeInsets.only(bottom: 20, top: 4),
              child: Text(
                'Settings & System',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Background & Battery Section
            _buildSectionHeader('Background Execution & Alarms'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF242836)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        controller.isBatteryOptimizationIgnored
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_alert_rounded,
                        color: controller.isBatteryOptimizationIgnored
                            ? const Color(0xFF34C759)
                            : Colors.orange,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Battery Optimization',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isBatteryOptimizationIgnored
                                  ? 'Unrestricted execution granted. Wallpaper will change reliably on schedule even during deep sleep.'
                                  : 'Android may throttle background alarms when the screen is off. Tap Allow to ensure on-time rotations.',
                              style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!controller.isBatteryOptimizationIgnored) ...[
                    const SizedBox(height: 14),
                    PressableScale(
                      onTap: () async {
                        await controller.requestDisableBatteryOptimization();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF5E3A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Allow Unrestricted Background Execution',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF242836)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    controller.config.showPersistentNotification
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: controller.config.showPersistentNotification
                        ? const Color(0xFFFF3B30)
                        : Colors.white38,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Status Notification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Show a persistent, unremovable notification indicating that Wall Tap is actively running in the background.',
                          style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    key: const Key('switch_persistent_notification'),
                    value: controller.config.showPersistentNotification,
                    activeThumbColor: const Color(0xFFFF3B30),
                    activeTrackColor: const Color(0xFFFF3B30).withAlpha(80),
                    onChanged: (val) async {
                      await controller.togglePersistentNotification(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Storage & Playlist Data
            _buildSectionHeader('Storage & Playlist Data'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF242836)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.storage_rounded, color: Colors.white70, size: 20),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Playlist Storage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${items.length} files ($storageSizeText)',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFF222634), height: 1),
                  ),
                  PressableScale(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1B1D26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Clear All Wallpapers?', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'This will permanently remove all imported pictures and reset your playlist.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        for (final item in List.of(items)) {
                          await controller.deleteItem(item.id);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All wallpapers cleared.')),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF453A), size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Clear All Wallpapers',
                            style: TextStyle(
                              color: Color(0xFFFF453A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About Wall Tap'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF242836)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF5E3A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withAlpha(60),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.wallpaper_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wall Tap',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF222634), height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: Color(0xFFFF3B30),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created By',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Zavier Ferodova Al Fitroh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Zavier Developer',
                              style: TextStyle(
                                color: Color(0xFFFF5E3A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1E2B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF282D3D)),
                    ),
                    child: const Text(
                      'This app created by Zavier Ferodova Al Fitroh as Zavier Developer. Designed for automatic wallpaper scheduling, album rotation, and home screen widgets.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  ),
);
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
