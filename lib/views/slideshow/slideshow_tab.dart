import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../controllers/wallpaper_controller.dart';
import '../../models/slideshow_config.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/wallpaper_preview_dialog.dart';
import '../widgets/widget_guide_dialog.dart';

class SlideshowTab extends StatefulWidget {
  final WallpaperController controller;

  const SlideshowTab({super.key, required this.controller});

  @override
  State<SlideshowTab> createState() => _SlideshowTabState();
}

class _SlideshowTabState extends State<SlideshowTab> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isShuffling = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        final paths = images.map((e) => e.path).toList();
        final count = await widget.controller.importImages(paths);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $count wallpaper${count == 1 ? '' : 's'} to collection'),
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFolder(BuildContext context) async {
    try {
      final count = await widget.controller.pickAndImportFolder();
      if (context.mounted) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $count wallpaper${count == 1 ? '' : 's'} from folder'),
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images found in selected folder'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick folder: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleShuffle() async {
    if (widget.controller.activeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add wallpapers first!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isShuffling) return;
    setState(() => _isShuffling = true);
    _rotationController.forward(from: 0.0);

    final success = await widget.controller.shuffleNext();

    if (mounted) {
      setState(() => _isShuffling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Wallpaper rotated!' : 'Could not set wallpaper.'),
            ],
          ),
          backgroundColor: success ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showIntervalPicker(BuildContext context) {
    final current = widget.controller.config.intervalMinutes;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Auto-Shuffle Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildIntervalOption(ctx, 'Off (Tap or Widget only)', 0, current),
                _buildIntervalOption(ctx, 'Every 1 minute (Fast test)', 1, current),
                _buildIntervalOption(ctx, 'Every 15 minutes', 15, current),
                _buildIntervalOption(ctx, 'Every 30 minutes', 30, current),
                _buildIntervalOption(ctx, 'Every 1 hour', 60, current),
                _buildIntervalOption(ctx, 'Every 3 hours', 180, current),
                _buildIntervalOption(ctx, 'Every 6 hours', 360, current),
                _buildIntervalOption(ctx, 'Every 12 hours', 720, current),
                _buildIntervalOption(ctx, 'Every 24 hours (Daily)', 1440, current),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalOption(BuildContext ctx, String label, int minutes, int current) {
    final isSelected = current == minutes;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFFF3B30) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFF3B30)) : null,
      onTap: () {
        widget.controller.updateInterval(minutes);
        Navigator.pop(ctx);
      },
    );
  }

  void _showSourceSelectorSheet() {
    final controller = widget.controller;
    final albums = controller.albums;
    final activeAlbumId = controller.activeAlbumId;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Shuffle Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: activeAlbumId == null
                        ? const Color(0xFFFF3B30).withAlpha(40)
                        : const Color(0xFF222634),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: activeAlbumId == null ? const Color(0xFFFF3B30) : Colors.white70,
                    size: 22,
                  ),
                ),
                title: const Text('All Wallpapers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('${controller.items.length} wallpapers', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: activeAlbumId == null
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF3B30))
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await controller.setActiveAlbum(null);
                },
              ),
              if (albums.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Divider(color: Color(0xFF262B3A)),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      final isSelected = activeAlbumId == album.id;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF3B30).withAlpha(40)
                                : const Color(0xFF222634),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_special_rounded,
                            color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFFFF5E3A),
                            size: 22,
                          ),
                        ),
                        title: Text(album.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('${album.count} wallpapers', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF3B30))
                            : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await controller.setActiveAlbum(album.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  BoxFit _getBoxFit(String scaleType) {
    switch (scaleType.toLowerCase()) {
      case 'crop':
        return BoxFit.cover;
      case 'fit':
        return BoxFit.contain;
      case 'full':
      default:
        return BoxFit.fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final config = controller.config;
        final items = controller.activeItems;
        final currentItem = controller.currentWallpaper;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0E12),
          body: SafeArea(
            child: Column(
              children: [
                // Pinned Sticky Navbar
                _buildStickyNavbar(context, controller, config),

                // Scrollable Content
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      final scrolled = notification.metrics.pixels > 4.0;
                      if (scrolled != _isScrolled) {
                        setState(() {
                          _isScrolled = scrolled;
                        });
                      }
                      return false;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                      children: [
                        // Hero Device Mockup
                        Center(
              child: Container(
                width: 210,
                height: 380,
                decoration: BoxDecoration(
                  color: const Color(0xFF161820),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: const Color(0xFF2D3244), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withAlpha(45),
                      blurRadius: 36,
                      spreadRadius: -10,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(160),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Active Wallpaper Image with Animated Cross-Fade
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, animation) {
                          final isCurrent = currentItem != null && (child.key == ValueKey<String>('${currentItem.id}_${config.scaleType}'));
                          if (isCurrent) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                                child: child,
                              ),
                            );
                          } else {
                            // Keep outgoing child solid underneath to eliminate dark dip
                            return child;
                          }
                        },
                        child: currentItem != null && File(currentItem.path).existsSync()
                            ? Image.file(
                                key: ValueKey<String>('${currentItem.id}_${config.scaleType}'),
                                File(currentItem.path),
                                fit: _getBoxFit(config.scaleType),
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                key: const ValueKey('empty_state'),
                                color: const Color(0xFF151720),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Colors.white.withAlpha(90),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Add Wallpaper',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(150),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // Camera punch-hole notch
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 48,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Floating active badge at bottom of phone mockup
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(30)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34C759),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  currentItem != null ? config.targetScreenLabel : 'No Wallpapers',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
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

            const SizedBox(height: 14),

            // Active Source Selector Chip
            Center(
              child: PressableScale(
                onTap: _showSourceSelectorSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.activeAlbum != null
                          ? const Color(0xFFFF3B30).withAlpha(140)
                          : const Color(0xFF2C3040),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.activeAlbum != null
                            ? Icons.folder_special_rounded
                            : Icons.photo_library_rounded,
                        size: 16,
                        color: controller.activeAlbum != null
                            ? const Color(0xFFFF3B30)
                            : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Source: ${controller.activeAlbum != null ? controller.activeAlbum!.name : "All Wallpapers"}',
                        style: TextStyle(
                          color: controller.activeAlbum != null
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Large Tactile "Shuffle Wallpaper" Button
            PressableScale(
              onTap: _handleShuffle,
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3B30), Color(0xFFFF5E3A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withAlpha(90),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Shuffle Wallpaper',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Wallpaper Configuration Card
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFFFF3B30), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Wallpaper Configuration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Target Screen Selector
                  const Text(
                    'Target Screen',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPillOption(
                        label: 'Both',
                        icon: Icons.smartphone_rounded,
                        isSelected: config.targetScreen == 'both',
                        onTap: () => controller.updateTargetScreen('both'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillOption(
                        label: 'Home',
                        icon: Icons.home_rounded,
                        isSelected: config.targetScreen == 'home',
                        onTap: () => controller.updateTargetScreen('home'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillOption(
                        label: 'Lock',
                        icon: Icons.lock_outline_rounded,
                        isSelected: config.targetScreen == 'lock',
                        onTap: () => controller.updateTargetScreen('lock'),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF222634), height: 1),
                  ),

                  // Scale Mode Selector
                  const Text(
                    'Scale Mode',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPillOption(
                        label: 'Full Image',
                        icon: Icons.aspect_ratio_rounded,
                        isSelected: config.scaleType == 'full',
                        onTap: () => controller.updateScaleType('full'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillOption(
                        label: 'Center Crop',
                        icon: Icons.crop_rounded,
                        isSelected: config.scaleType == 'crop',
                        onTap: () => controller.updateScaleType('crop'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillOption(
                        label: 'Fit',
                        icon: Icons.fit_screen_rounded,
                        isSelected: config.scaleType == 'fit',
                        onTap: () => controller.updateScaleType('fit'),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF222634), height: 1),
                  ),

                  // Auto Shuffle Interval
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Auto-Shuffle Timer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      PressableScale(
                        onTap: () => _showIntervalPicker(context),
                        child: const Text(
                          'More options',
                          style: TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Interval Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickIntervalChip('Off', 0, config.intervalMinutes),
                        const SizedBox(width: 8),
                        _buildQuickIntervalChip('1m', 1, config.intervalMinutes),
                        const SizedBox(width: 8),
                        _buildQuickIntervalChip('15m', 15, config.intervalMinutes),
                        const SizedBox(width: 8),
                        _buildQuickIntervalChip('1h', 60, config.intervalMinutes),
                        const SizedBox(width: 8),
                        _buildQuickIntervalChip('Daily', 1440, config.intervalMinutes),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Add Photos & Folder Action Cards
            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    onTap: () => _pickImages(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161822),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF262A38)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF3B30), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Photos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressableScale(
                    onTap: () => _pickFolder(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161822),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF262A38)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Folder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (items.isNotEmpty) ...[
              const SizedBox(height: 26),
              // Up Next Queue Reel Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rotation Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${items.length} in rotation',
                    style: const TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Queue Horizontal Carousel
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isCurrent = currentItem?.id == item.id;

                    return PressableScale(
                      onTap: () {
                        WallpaperPreviewDialog.show(
                          context,
                          item: item,
                          controller: controller,
                        );
                      },
                      child: Container(
                        width: 82,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFFFF3B30) : const Color(0xFF262A38),
                            width: isCurrent ? 2.5 : 1.0,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF3B30).withAlpha(80),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(item.path),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                              if (isCurrent)
                                Positioned(
                                  top: 5,
                                  left: 5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ],
),
          ),
        );
      },
    );
  }

  Widget _buildStickyNavbar(
    BuildContext context,
    WallpaperController controller,
    SlideshowConfig config,
  ) {
    return AnimatedContainer(
      key: const Key('sticky_navbar'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E12),
        border: Border(
          bottom: BorderSide(
            color: _isScrolled ? const Color(0xFF1E212D) : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(70),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF3B30).withAlpha(70)),
                  ),
                  child: const Icon(Icons.wallpaper_rounded, color: Color(0xFFFF3B30), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wall Tap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Studio',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Random / Sequential Mode Toggle Pill
              PressableScale(
                onTap: () => controller.toggleRandom(!config.isRandom),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2C3040)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config.isRandom ? Icons.shuffle : Icons.repeat,
                        color: config.isRandom ? const Color(0xFFFF3B30) : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        config.isRandom ? 'Random' : 'Order',
                        style: TextStyle(
                          color: config.isRandom ? const Color(0xFFFF3B30) : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Button Help
              Tooltip(
                message: 'Widget Guide & Help',
                child: PressableScale(
                  onTap: () => WidgetGuideDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C3040)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Help',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFF1B1E29),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFF282C3C),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 15,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIntervalChip(String label, int minutes, int currentMinutes) {
    final isSelected = currentMinutes == minutes;
    return PressableScale(
      onTap: () => widget.controller.updateInterval(minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFF1B1E29),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFF282C3C),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
