import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/wallpaper_controller.dart';
import '../../models/album_widget_config.dart';
import '../../models/wallpaper_item.dart';
import '../widgets/pressable_scale.dart';

class AlbumWidgetsTab extends StatefulWidget {
  final WallpaperController controller;

  const AlbumWidgetsTab({super.key, required this.controller});

  @override
  State<AlbumWidgetsTab> createState() => _AlbumWidgetsTabState();
}

class _AlbumWidgetsTabState extends State<AlbumWidgetsTab> with WidgetsBindingObserver {
  bool _isSyncing = false;
  bool _isChecking = false;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.loadAlbumWidgets();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        widget.controller.loadAlbumWidgets();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.loadAlbumWidgets();
    }
  }

  Future<void> _handleSyncAll() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await widget.controller.syncAllAlbumWidgets();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('All album widgets updated!'),
            ],
          ),
          backgroundColor: const Color(0xFF34C759),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    await widget.controller.loadAlbumWidgets();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  void _showIntervalPicker(BuildContext context, AlbumWidgetConfig widgetConfig) {
    final current = widgetConfig.intervalMinutes;
    final options = [
      (0, 'Manual (Tap only)'),
      (1, 'Every 1 minute (Fast test)'),
      (5, 'Every 5 minutes'),
      (15, 'Every 15 minutes'),
      (30, 'Every 30 minutes'),
      (60, 'Every 1 hour'),
      (180, 'Every 3 hours'),
      (360, 'Every 6 hours'),
      (1440, 'Every 24 hours (Daily)'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Widget #${widgetConfig.widgetId} Shuffle Interval',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (final opt in options)
                      ListTile(
                        title: Text(
                          opt.$2,
                          style: TextStyle(
                            color: current == opt.$1 ? const Color(0xFFFF3B30) : Colors.white,
                            fontWeight: current == opt.$1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: current == opt.$1 ? const Icon(Icons.check, color: Color(0xFFFF3B30)) : null,
                        onTap: () {
                          widget.controller.updateAlbumWidgetConfig(widgetConfig.copyWith(intervalMinutes: opt.$1));
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAlbumPicker(BuildContext context, AlbumWidgetConfig widgetConfig) {
    final currentId = widgetConfig.albumId;
    final albums = widget.controller.albums;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Assign Album to Widget #${widgetConfig.widgetId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        'All Photos (Full Gallery)',
                        style: TextStyle(
                          color: (currentId == 'all' || currentId == 'all_photos' || currentId.isEmpty)
                              ? const Color(0xFFFF3B30)
                              : Colors.white,
                          fontWeight: (currentId == 'all' || currentId == 'all_photos' || currentId.isEmpty)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${widget.controller.items.length} photos',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: (currentId == 'all' || currentId == 'all_photos' || currentId.isEmpty)
                          ? const Icon(Icons.check, color: Color(0xFFFF3B30))
                          : null,
                      onTap: () {
                        widget.controller.updateAlbumWidgetConfig(widgetConfig.copyWith(
                          albumId: 'all_photos',
                          albumName: 'All Photos',
                        ));
                        Navigator.pop(ctx);
                      },
                    ),
                    for (final album in albums)
                      ListTile(
                        title: Text(
                          album.name,
                          style: TextStyle(
                            color: currentId == album.id ? const Color(0xFFFF3B30) : Colors.white,
                            fontWeight: currentId == album.id ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${album.count} photos',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: currentId == album.id
                            ? const Icon(Icons.check, color: Color(0xFFFF3B30))
                            : null,
                        onTap: () {
                          widget.controller.updateAlbumWidgetConfig(widgetConfig.copyWith(
                            albumId: album.id,
                            albumName: album.name,
                          ));
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  WallpaperItem? _getCurrentItemForWidget(AlbumWidgetConfig config) {
    if (config.currentImagePath.isNotEmpty) {
      final match = widget.controller.items.where((it) => it.path == config.currentImagePath).firstOrNull;
      if (match != null) return match;
      if (File(config.currentImagePath).existsSync()) {
        return WallpaperItem(
          id: 'widget_${config.widgetId}_current',
          path: config.currentImagePath,
          fileName: config.currentImagePath.split('/').last,
          width: 0,
          height: 0,
          fileSize: 0,
          dateAdded: DateTime.now(),
        );
      }
    }
    final items = widget.controller.getAlbumItems(config.albumId);
    if (items.isEmpty) return null;
    final safeIndex = (config.currentIndex >= 0 && config.currentIndex < items.length)
        ? config.currentIndex
        : 0;
    return items[safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    final albumWidgets = widget.controller.albumWidgets;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      body: RefreshIndicator(
        color: const Color(0xFFFF3B30),
        backgroundColor: const Color(0xFF161824),
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Sleek Glassmorphic App Bar
            SliverAppBar(
              backgroundColor: const Color(0xFF0D0E12),
              pinned: true,
              expandedHeight: 110,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  'Album Widgets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                if (albumWidgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: PressableScale(
                      onTap: _handleSyncAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2436),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E3850)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSyncing)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                              )
                            else
                              const Icon(Icons.sync_rounded, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Sync All',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Main Content
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle & Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF161A28), Color(0xFF12141E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF23283E)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withAlpha(35),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF38BDF8).withAlpha(80)),
                              ),
                              child: const Icon(
                                Icons.dashboard_customize_rounded,
                                color: Color(0xFF38BDF8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Desktop Photo Frames',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    albumWidgets.isNotEmpty
                                        ? '${albumWidgets.length} active widget${albumWidgets.length > 1 ? 's' : ''} placed on home screen'
                                        : 'Rotate album photos on your home screen without changing wallpaper',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            albumWidgets.isNotEmpty ? 'Placed Widgets' : 'Get Started',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (albumWidgets.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${albumWidgets.length} Active',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (albumWidgets.isEmpty) ...[
                        _buildOnboardingCard(context),
                      ] else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 600) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 350,
                                ),
                                itemCount: albumWidgets.length,
                                itemBuilder: (context, index) =>
                                    _buildAlbumWidgetCard(context, albumWidgets[index]),
                              );
                            }
                            return Column(
                              children: [
                                for (int i = 0; i < albumWidgets.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _buildAlbumWidgetCard(context, albumWidgets[i]),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ],
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

  Widget _buildOnboardingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF242836)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Add an Album Widget',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const _StepRow(
            step: '1',
            title: 'Long-press empty space',
            description: 'Go to your Android home screen and touch & hold any empty area.',
          ),
          const SizedBox(height: 12),
          const _StepRow(
            step: '2',
            title: 'Choose Wall Tap Album Display',
            description: 'Tap "Widgets", scroll to find Wall Tap, and drag "Wall Tap Album Display" to your screen.',
          ),
          const SizedBox(height: 12),
          const _StepRow(
            step: '3',
            title: 'Assign album & enjoy',
            description: 'Select which album you want this widget to rotate, and adjust its size freely!',
          ),
          const SizedBox(height: 20),
          PressableScale(
            onTap: _handleRefresh,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2436), Color(0xFF161926)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C3246)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isChecking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                    )
                  else
                    const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Check Placed Widgets',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumWidgetCard(BuildContext context, AlbumWidgetConfig widgetConfig) {
    final currentItem = _getCurrentItemForWidget(widgetConfig);
    final albumItems = widget.controller.getAlbumItems(widgetConfig.albumId);
    final totalCount = widgetConfig.totalImages > 0 ? widgetConfig.totalImages : albumItems.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF242838)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Widget ID & Shuffle Now button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.photo_size_select_actual_rounded,
                        color: Color(0xFF38BDF8),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Widget #${widgetConfig.widgetId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$totalCount photo${totalCount == 1 ? '' : 's'} in queue',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: () => widget.controller.shuffleAlbumWidget(widgetConfig.widgetId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2436),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2E3850)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle_rounded, color: Color(0xFF38BDF8), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Shuffle Now',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Live Photo Preview Card
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0E1017),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2232)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (currentItem != null && File(currentItem.path).existsSync())
                  Image.file(
                    File(currentItem.path),
                    fit: BoxFit.cover,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 32,
                          color: Colors.white.withAlpha(80),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          totalCount == 0 ? 'Album has no photos' : 'Photo unavailable',
                          style: TextStyle(
                            color: Colors.white.withAlpha(120),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dark gradient overlay at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(200),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Active badge & photo index
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ON HOME SCREEN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${((widgetConfig.currentIndex) % totalCount) + 1} / $totalCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 1. Album Selector Tile
          InkWell(
            onTap: () => _showAlbumPicker(context, widgetConfig),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10121A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2232)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_rounded, color: Colors.white54, size: 18),
                  const SizedBox(width: 10),
                  const Text('Album', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widgetConfig.albumName.isNotEmpty ? widgetConfig.albumName : 'All Photos',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. Order Mode & Interval Controls
          Row(
            children: [
              // Order Mode Pills
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10121A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2232)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: () {
                            if (widgetConfig.isRandom) {
                              widget.controller.updateAlbumWidgetConfig(widgetConfig.copyWith(isRandom: false));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: !widgetConfig.isRandom ? const Color(0xFFFF3B30) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Ordered',
                              style: TextStyle(
                                color: !widgetConfig.isRandom ? Colors.white : Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: PressableScale(
                          onTap: () {
                            if (!widgetConfig.isRandom) {
                              widget.controller.updateAlbumWidgetConfig(widgetConfig.copyWith(isRandom: true));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: widgetConfig.isRandom ? const Color(0xFFFF3B30) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Random',
                              style: TextStyle(
                                color: widgetConfig.isRandom ? Colors.white : Colors.white60,
                                fontSize: 12,
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

              const SizedBox(width: 10),

              // Interval Selector Button
              Expanded(
                child: InkWell(
                  onTap: () => _showIntervalPicker(context, widgetConfig),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10121A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2232)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white54, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widgetConfig.intervalLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
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
}

class _StepRow extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _StepRow({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF3B30).withAlpha(120)),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
