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
      (1, 'Every 1 minute'),
      (3, 'Every 3 minutes'),
      (5, 'Every 5 minutes'),
      (10, 'Every 10 minutes'),
      (15, 'Every 15 minutes'),
      (30, 'Every 30 minutes'),
      (45, 'Every 45 minutes'),
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
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
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
                          final latest = widget.controller.albumWidgets.firstWhere(
                            (w) => w.widgetId == widgetConfig.widgetId,
                            orElse: () => widgetConfig,
                          );
                          widget.controller.updateAlbumWidgetConfig(latest.copyWith(intervalMinutes: opt.$1));
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
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
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
                        final latest = widget.controller.albumWidgets.firstWhere(
                          (w) => w.widgetId == widgetConfig.widgetId,
                          orElse: () => widgetConfig,
                        );
                        widget.controller.updateAlbumWidgetConfig(latest.copyWith(
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
                          final latest = widget.controller.albumWidgets.firstWhere(
                            (w) => w.widgetId == widgetConfig.widgetId,
                            orElse: () => widgetConfig,
                          );
                          widget.controller.updateAlbumWidgetConfig(latest.copyWith(
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

  Widget _buildHeader(List<AlbumWidgetConfig> albumWidgets) {
    return KeyedSubtree(
      key: const Key('widgets_header'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Album Widgets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (albumWidgets.isNotEmpty)
            PressableScale(
              onTap: _handleSyncAll,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSyncing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Sync All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final albumWidgets = widget.controller.albumWidgets;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0E12),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(albumWidgets),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFF3B30),
                    backgroundColor: const Color(0xFF161824),
                    onRefresh: _handleRefresh,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: albumWidgets.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
                                child: _buildOnboardingCard(context),
                              )
                            : GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: albumWidgets.length,
                                itemBuilder: (context, index) =>
                                    _buildAlbumWidgetCard(context, albumWidgets[index]),
                              ),
                      ),
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
            title: 'Assign album to start rotation',
            description: 'Select which album you want this widget to rotate, and adjust its size freely!',
          ),
          const SizedBox(height: 20),
          PressableScale(
            onTap: _handleRefresh,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2436), Color(0xFF161926)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C3246)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isChecking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3B30)),
                    )
                  else
                    const Icon(Icons.refresh_rounded, color: Color(0xFFFF3B30), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Check Placed Widgets',
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
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

    return PressableScale(
      key: Key('album_widget_grid_card_${widgetConfig.widgetId}'),
      onTap: () => _showWidgetConfigSheet(context, widgetConfig.widgetId),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161822),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Square photo display with AnimatedSwitcher
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
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.97, end: 1.0).animate(
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
                      key: ValueKey<String>('widget_${widgetConfig.widgetId}_${currentItem.id}'),
                      File(currentItem.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      key: ValueKey<String>('widget_${widgetConfig.widgetId}_empty'),
                      color: const Color(0xFF0E1017),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 28,
                            color: Colors.white.withAlpha(80),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            totalCount == 0 ? 'Album has no photos' : 'Photo unavailable',
                            style: TextStyle(
                              color: Colors.white.withAlpha(120),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),

            // Bottom gradient overlay for contrast and legibility
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 76,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(220),
                      Colors.black.withAlpha(140),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // Widget badge as title on bottom of image
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Widget #${widgetConfig.widgetId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (totalCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${((widgetConfig.currentIndex) % totalCount) + 1}/$totalCount',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widgetConfig.albumName.isNotEmpty ? widgetConfig.albumName : 'All Photos',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWidgetConfigSheet(BuildContext context, int widgetId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final configIndex = widget.controller.albumWidgets.indexWhere((w) => w.widgetId == widgetId);
            if (configIndex == -1) {
              return const SizedBox.shrink();
            }
            final currentConfig = widget.controller.albumWidgets[configIndex];
            final currentItem = _getCurrentItemForWidget(currentConfig);
            final albumItems = widget.controller.getAlbumItems(currentConfig.albumId);
            final totalCount = currentConfig.totalImages > 0 ? currentConfig.totalImages : albumItems.length;

            return SafeArea(
              child: Center(
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(top: 4, bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Header Row
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withAlpha(35),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFF3B30).withAlpha(80)),
                              ),
                              child: const Icon(
                                Icons.photo_size_select_actual_rounded,
                                color: Color(0xFFFF3B30),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Widget #${currentConfig.widgetId}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Configure Shuffle & Display',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              icon: const Icon(Icons.close_rounded, color: Colors.white70),
                              splashRadius: 20,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Mini Preview & Info Card
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10121A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E2232)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: const Color(0xFF0E1017),
                                  child: currentItem != null && File(currentItem.path).existsSync()
                                      ? Image.file(
                                          File(currentItem.path),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.photo_library_outlined,
                                          color: Colors.white24,
                                          size: 28,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentConfig.albumName.isNotEmpty ? currentConfig.albumName : 'All Photos',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      totalCount > 0
                                          ? 'Photo ${((currentConfig.currentIndex) % totalCount) + 1} of $totalCount'
                                          : 'No photos in album',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${currentConfig.intervalLabel} • ${currentConfig.isRandom ? 'Random' : 'Ordered'}',
                                      style: const TextStyle(
                                        color: Color(0xFFFF3B30),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Shuffle Now Button
                        PressableScale(
                          onTap: () {
                            widget.controller.shuffleAlbumWidget(currentConfig.widgetId);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3B30).withAlpha(80),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Shuffle Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'SHUFFLE CONFIGURATION',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Album Selector Tile
                        InkWell(
                          onTap: () => _showAlbumPicker(context, currentConfig),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10121A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E2232)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.photo_library_rounded, color: Colors.white70, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Photo Album',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentConfig.albumName.isNotEmpty ? currentConfig.albumName : 'All Photos',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Order Mode (Ordered / Random)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10121A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E2232)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.alt_route_rounded, color: Colors.white70, size: 16),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Mode',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Playback Sequence',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161824),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: const Color(0xFF242838)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PressableScale(
                                      onTap: () {
                                        if (currentConfig.isRandom) {
                                          widget.controller.updateAlbumWidgetConfig(currentConfig.copyWith(isRandom: false));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: !currentConfig.isRandom ? const Color(0xFFFF3B30) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Ordered',
                                          style: TextStyle(
                                            color: !currentConfig.isRandom ? Colors.white : Colors.white60,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    PressableScale(
                                      onTap: () {
                                        if (!currentConfig.isRandom) {
                                          widget.controller.updateAlbumWidgetConfig(currentConfig.copyWith(isRandom: true));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: currentConfig.isRandom ? const Color(0xFFFF3B30) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Random',
                                          style: TextStyle(
                                            color: currentConfig.isRandom ? Colors.white : Colors.white60,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Interval Selector Tile
                        InkWell(
                          onTap: () => _showIntervalPicker(context, currentConfig),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10121A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E2232)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Shuffle Interval',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentConfig.intervalLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
                  color: Colors.white70,
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
