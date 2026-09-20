import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/wallpaper_item.dart';
import '../../controllers/wallpaper_controller.dart';
import 'pressable_scale.dart';

class WallpaperPreviewDialog extends StatefulWidget {
  final WallpaperItem item;
  final WallpaperController controller;

  const WallpaperPreviewDialog({
    super.key,
    required this.item,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required WallpaperItem item,
    required WallpaperController controller,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return WallpaperPreviewDialog(item: item, controller: controller);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<WallpaperPreviewDialog> createState() => _WallpaperPreviewDialogState();
}

class _WallpaperPreviewDialogState extends State<WallpaperPreviewDialog>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_animController.isAnimating) return;

    final currentMatrix = _transformationController.value;
    final isZoomed = currentMatrix.getMaxScaleOnAxis() > 1.05;

    final Matrix4 targetMatrix;
    if (isZoomed) {
      targetMatrix = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      targetMatrix = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }

    _zoomAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _confirmDelete(WallpaperItem currentItem) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Wallpaper?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently remove this wallpaper from Wall Tap storage.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.controller.deleteItem(currentItem.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentItem = widget.controller.items.firstWhere(
          (i) => i.id == widget.item.id,
          orElse: () => widget.item,
        );
        final isCurrentDeviceWallpaper =
            widget.controller.currentWallpaper?.id == currentItem.id;
        final file = File(currentItem.path);
        final fileExists = file.existsSync();

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable & Pannable Image Area
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleControls,
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 6.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: fileExists
                        ? Image.file(
                            file,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white38,
                                size: 64,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white38,
                              size: 64,
                            ),
                          ),
                  ),
                ),
              ),

              // Top Bar Overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                top: _showControls ? 0 : -100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(200),
                            Colors.black.withAlpha(80),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                            children: [
                              // Close button
                              PressableScale(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161822).withAlpha(220),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withAlpha(35)),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const Spacer(),



                              // Resolution and file size badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161822).withAlpha(220),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withAlpha(35)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(100),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_size_select_actual_outlined,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentItem.resolutionText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${currentItem.formattedSize}',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

              // Bottom Sheet / Action Panel Overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                bottom: _showControls ? 0 : -220,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161822).withAlpha(240),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        border: const Border(
                          top: BorderSide(color: Color(0xFF2A2E3D), width: 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(200),
                            blurRadius: 28,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag handle indicator
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(60),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // File Name & Quick controls row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentItem.fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            currentItem.isEnabled
                                                ? 'Active in shuffle rotation'
                                                : 'Excluded from rotation',
                                            style: TextStyle(
                                              color: currentItem.isEnabled
                                                  ? const Color(0xFF34C759)
                                                  : Colors.white38,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Toggle Active / Excluded Button
                                PressableScale(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.controller.toggleItemEnabled(currentItem.id);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentItem.isEnabled
                                          ? const Color(0xFF1E3A28)
                                          : const Color(0xFF222530),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: currentItem.isEnabled
                                            ? const Color(0xFF34C759)
                                            : const Color(0xFF323746),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          currentItem.isEnabled
                                              ? Icons.check_circle_rounded
                                              : Icons.remove_circle_outline_rounded,
                                          color: currentItem.isEnabled
                                              ? const Color(0xFF34C759)
                                              : Colors.white60,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          currentItem.isEnabled ? 'Active' : 'Excluded',
                                          style: TextStyle(
                                            color: currentItem.isEnabled
                                                ? const Color(0xFF34C759)
                                                : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Delete Button
                                PressableScale(
                                  onTap: () => _confirmDelete(currentItem),
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E1B1E),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFF4E2429)),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFFF453A),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Primary "Set as Current Wallpaper" Action
                            PressableScale(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                final success =
                                    await widget.controller.setCurrentWallpaper(currentItem);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Wallpaper applied to device!'
                                          : 'Could not set wallpaper.',
                                    ),
                                    backgroundColor: success
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFFFF3B30),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCurrentDeviceWallpaper
                                        ? const [Color(0xFF2E6E3E), Color(0xFF34C759)]
                                        : const [Color(0xFFFF3B30), Color(0xFFFF5E3A)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isCurrentDeviceWallpaper
                                              ? const Color(0xFF34C759)
                                              : const Color(0xFFFF3B30))
                                          .withAlpha(80),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isCurrentDeviceWallpaper
                                          ? Icons.check_circle_rounded
                                          : Icons.wallpaper_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isCurrentDeviceWallpaper
                                          ? 'Current Wallpaper'
                                          : 'Set as Current Wallpaper',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
              ),
            ],
          ),
        );
      },
    );
  }
}
