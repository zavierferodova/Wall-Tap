import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/wallpaper_controller.dart';
import '../../models/slideshow_config.dart';
import '../../models/wallpaper_item.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/wallpaper_preview_dialog.dart';

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
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
                _buildIntervalOption(ctx, 'Every 3 minutes', 3, current),
                _buildIntervalOption(ctx, 'Every 5 minutes', 5, current),
                _buildIntervalOption(ctx, 'Every 10 minutes', 10, current),
                _buildIntervalOption(ctx, 'Every 15 minutes', 15, current),
                _buildIntervalOption(ctx, 'Every 30 minutes', 30, current),
                _buildIntervalOption(ctx, 'Every 45 minutes', 45, current),
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
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
                            color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFFFF3B30),
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
        final currentItem = controller.currentWallpaper;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0E12),
          body: SafeArea(
            bottom: false,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final contentMaxWidth = constraints.maxWidth >= 720 ? 580.0 : 540.0;

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 150),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Hero Row: Lock Mockup, Home Mockup, Shuffle Button
                                    _buildHeroRow(
                                      context,
                                      controller,
                                      config,
                                      currentItem,
                                      availableWidth: contentMaxWidth,
                                    ),
                                    const SizedBox(height: 18),

                                    // Source Selector Card ("Source Cars v")
                                    _buildSourceSelectorCard(controller),
                                    const SizedBox(height: 16),

                                    // Unified Configuration Card: APPLY TO, FIT, AUTO-SHUFFLE EVERY
                                    _buildConfigurationCard(context, controller, config),

                                    if (controller.activeItems.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _buildRotationQueueHeader(),
                                      const SizedBox(height: 12),
                                      _buildRotationQueueCarousel(controller.activeItems, currentItem, controller),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _buildHeroRow(
    BuildContext context,
    WallpaperController controller,
    SlideshowConfig config,
    WallpaperItem? currentItem, {
    required double availableWidth,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final deviceAspectRatio = (screenWidth > 0 && screenHeight > 0)
        ? (screenWidth / screenHeight)
        : (9.0 / 16.0);
    final isLandscape = deviceAspectRatio > 1.0;

    final double mockupHeight;
    final double mockupWidth;

    if (isLandscape) {
      final naturalHeight = (screenHeight * 0.22).clamp(120.0, 160.0);
      final maxW = (availableWidth - 110) / 2;
      if (naturalHeight * deviceAspectRatio <= maxW) {
        mockupHeight = naturalHeight;
        mockupWidth = mockupHeight * deviceAspectRatio;
      } else {
        mockupWidth = maxW;
        mockupHeight = mockupWidth / deviceAspectRatio;
      }
    } else {
      final naturalHeight = (screenHeight * 0.26).clamp(180.0, 220.0);
      final maxW = (availableWidth - 110) / 2;
      if (naturalHeight * deviceAspectRatio <= maxW) {
        mockupHeight = naturalHeight;
        mockupWidth = mockupHeight * deviceAspectRatio;
      } else {
        mockupWidth = maxW;
        mockupHeight = mockupWidth / deviceAspectRatio;
      }
    }

    final cornerRadius = (mockupWidth * 0.18).clamp(16.0, 22.0);

    return Center(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              (details.primaryVelocity! < -200 || details.primaryVelocity! > 200)) {
            widget.controller.shuffleNext();
          }
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Lock Screen Mockup
              _buildLockMockup(
                mockupWidth,
                mockupHeight,
                cornerRadius,
                isLandscape,
                currentItem,
                config,
              ),
              const SizedBox(width: 10),

              // 2. Home Screen Mockup
              _buildHomeMockup(
                mockupWidth,
                mockupHeight,
                cornerRadius,
                isLandscape,
                currentItem,
                config,
              ),
              const SizedBox(width: 18),

              // 3. Circular Shuffle Button
              _buildCircularShuffleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockMockup(
    double width,
    double height,
    double cornerRadius,
    bool isLandscape,
    WallpaperItem? currentItem,
    SlideshowConfig config,
  ) {
    return Container(
      key: const Key('hero_device_mockup'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161820),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(color: const Color(0xFF262A38), width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius - 2.2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Active Wallpaper Image or Gradient
            _buildMockupWallpaper(currentItem, config),

            // Subtle dark overlay gradient for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(60),
                    Colors.transparent,
                    Colors.black.withAlpha(100),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Camera punch-hole notch / Dynamic Island
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                key: Key(isLandscape ? 'hero_landscape_camera' : 'hero_portrait_notch'),
                margin: const EdgeInsets.only(top: 6),
                width: isLandscape ? 8 : (width * 0.22).clamp(20.0, 36.0),
                height: isLandscape ? 8 : 7,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: isLandscape ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isLandscape ? null : BorderRadius.circular(4),
                ),
              ),
            ),

            // Clock & Date (9:41, Tue, Oct 20)
            Positioned(
              top: (height * 0.14).clamp(24.0, 36.0),
              left: 4,
              right: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '9:41',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (width * 0.27).clamp(20.0, 28.0),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tue, Oct 20',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: (width * 0.10).clamp(9.0, 11.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom "Lock" Pill
            Positioned(
              bottom: 8,
              left: 6,
              right: 6,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Lock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeMockup(
    double width,
    double height,
    double cornerRadius,
    bool isLandscape,
    WallpaperItem? currentItem,
    SlideshowConfig config,
  ) {
    return Container(
      key: const Key('hero_home_mockup'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161820),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(color: const Color(0xFF262A38), width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius - 2.2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Active Wallpaper Image or Gradient
            _buildMockupWallpaper(currentItem, config),

            // Subtle dark overlay gradient for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(60),
                    Colors.transparent,
                    Colors.black.withAlpha(100),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Camera punch-hole notch / Dynamic Island
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                width: isLandscape ? 8 : (width * 0.22).clamp(20.0, 36.0),
                height: isLandscape ? 8 : 7,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: isLandscape ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isLandscape ? null : BorderRadius.circular(4),
                ),
              ),
            ),

            // App Icons Grid (2 rows x 4 columns)
            Positioned(
              top: (height * 0.15).clamp(26.0, 40.0),
              left: 4,
              right: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => Container(
                      width: (width * 0.125).clamp(9.0, 13.0),
                      height: (width * 0.125).clamp(9.0, 13.0),
                      margin: const EdgeInsets.all(2.2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(85),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                    )),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => Container(
                      width: (width * 0.125).clamp(9.0, 13.0),
                      height: (width * 0.125).clamp(9.0, 13.0),
                      margin: const EdgeInsets.all(2.2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(85),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                    )),
                  ),
                ],
              ),
            ),

            // Bottom "Home" Pill
            Positioned(
              bottom: 8,
              left: 6,
              right: 6,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockupWallpaper(WallpaperItem? currentItem, SlideshowConfig config) {
    return AnimatedSwitcher(
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
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
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
              key: const ValueKey('default_wallpaper_gradient'),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1D4ED8),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCircularShuffleButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressableScale(
          onTap: _handleShuffle,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3B30).withAlpha(100),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: RotationTransition(
                turns: _rotationController,
                child: const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Shuffle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceSelectorCard(WallpaperController controller) {
    return PressableScale(
      onTap: _showSourceSelectorSheet,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141620),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF242838)),
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Source  ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: controller.activeAlbum != null ? controller.activeAlbum!.name : 'All Wallpapers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortInterval(int minutes) {
    if (minutes <= 0) return 'Off';
    if (minutes == 1) return '1m';
    if (minutes < 60) return '${minutes}m';
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${minutes}m';
  }

  Widget _buildConfigurationCard(
    BuildContext context,
    WallpaperController controller,
    SlideshowConfig config,
  ) {
    final isCustomInterval = ![0, 1, 5, 15, 60].contains(config.intervalMinutes);
    return Container(
      key: const Key('wallpaper_config_card'),
      decoration: BoxDecoration(
        color: const Color(0xFF141620),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF242838)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. APPLY TO
          const Text(
            'APPLY TO',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1017),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildSegmentOption(
                  key: const Key('segment_apply_both'),
                  label: 'Both',
                  isSelected: config.targetScreen == 'both',
                  onTap: () => controller.updateTargetScreen('both'),
                ),
                _buildSegmentOption(
                  key: const Key('segment_apply_home'),
                  label: 'Home',
                  isSelected: config.targetScreen == 'home',
                  onTap: () => controller.updateTargetScreen('home'),
                ),
                _buildSegmentOption(
                  key: const Key('segment_apply_lock'),
                  label: 'Lock',
                  isSelected: config.targetScreen == 'lock',
                  onTap: () => controller.updateTargetScreen('lock'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. FIT
          const Text(
            'FIT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1017),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildSegmentOption(
                  key: const Key('segment_fit_full'),
                  label: 'Full',
                  isSelected: config.scaleType == 'full',
                  onTap: () => controller.updateScaleType('full'),
                ),
                _buildSegmentOption(
                  key: const Key('segment_fit_crop'),
                  label: 'Crop',
                  isSelected: config.scaleType == 'crop',
                  onTap: () => controller.updateScaleType('crop'),
                ),
                _buildSegmentOption(
                  key: const Key('segment_fit_fit'),
                  label: 'Fit',
                  isSelected: config.scaleType == 'fit',
                  onTap: () => controller.updateScaleType('fit'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. AUTO-SHUFFLE EVERY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'AUTO-SHUFFLE EVERY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: () => _showIntervalPicker(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(
                    'More options',
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1017),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildSegmentOption(
                  key: const Key('segment_interval_off'),
                  label: 'Off',
                  isSelected: config.intervalMinutes == 0,
                  onTap: () => controller.updateInterval(0),
                ),
                _buildSegmentOption(
                  key: const Key('segment_interval_1m'),
                  label: '1m',
                  isSelected: config.intervalMinutes == 1,
                  onTap: () => controller.updateInterval(1),
                ),
                _buildSegmentOption(
                  key: const Key('segment_interval_5m'),
                  label: '5m',
                  isSelected: config.intervalMinutes == 5,
                  onTap: () => controller.updateInterval(5),
                ),
                _buildSegmentOption(
                  key: const Key('segment_interval_15m'),
                  label: '15m',
                  isSelected: config.intervalMinutes == 15,
                  onTap: () => controller.updateInterval(15),
                ),
                _buildSegmentOption(
                  key: const Key('segment_interval_1h'),
                  label: '1h',
                  isSelected: config.intervalMinutes == 60,
                  onTap: () => controller.updateInterval(60),
                ),
                if (isCustomInterval)
                  _buildSegmentOption(
                    key: const Key('segment_interval_custom'),
                    label: _formatShortInterval(config.intervalMinutes),
                    isSelected: true,
                    onTap: () => _showIntervalPicker(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOption({
    Key? key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressableScale(
        key: key,
        onTap: onTap,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF3B30) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotationQueueHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Rotation Queue',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRotationQueueCarousel(
    List<WallpaperItem> items,
    WallpaperItem? currentItem,
    WallpaperController controller,
  ) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isCurrent = currentItem?.id == item.id;
          final isNext = controller.nextWallpaper?.id == item.id && !isCurrent;

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
                  color: isCurrent
                      ? const Color(0xFFFF3B30)
                      : (isNext ? const Color(0xFF007AFF) : const Color(0xFF262A38)),
                  width: (isCurrent || isNext) ? 2.5 : 1.0,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withAlpha(80),
                          blurRadius: 10,
                        ),
                      ]
                    : (isNext
                        ? [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withAlpha(80),
                              blurRadius: 10,
                            ),
                          ]
                        : null),
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
                    if (isNext)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEXT',
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Wall Tap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.isSlideshowEnabled ? 'Shuffle on' : 'Shuffle off',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    key: const Key('switch_slideshow_running'),
                    value: config.isSlideshowEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFFFF3B30),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF2C3040),
                    onChanged: (val) async {
                      await controller.toggleSlideshowEnabled(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
