import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/wallpaper_controller.dart';
import '../../models/wallpaper_item.dart';
import '../../models/album.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/wallpaper_preview_dialog.dart';
import 'album_detail_screen.dart';

class PlaylistTab extends StatefulWidget {
  final WallpaperController controller;

  const PlaylistTab({super.key, required this.controller});

  @override
  State<PlaylistTab> createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  int _selectedSegment = 0; // 0 = All Wallpapers, 1 = Albums
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  final TextEditingController _albumSearchController = TextEditingController();
  final FocusNode _albumSearchFocusNode = FocusNode();
  String _albumSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _albumSearchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _albumSearchFocusNode.removeListener(_onSearchFocusChanged);
    _albumSearchFocusNode.dispose();
    _albumSearchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode([String? initialId]) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      if (initialId != null) {
        _selectedIds.add(initialId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    final allIds = widget.controller.items.map((e) => e.id).toList();
    setState(() {
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(allIds);
      }
    });
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
              content: Text('Added $count wallpaper${count == 1 ? '' : 's'}'),
              backgroundColor: const Color(0xFF34C759),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding wallpapers: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Sort Wallpapers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded, color: Colors.white70),
                title: const Text('Name (A to Z)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  widget.controller.sortItemsAlphabetical();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.aspect_ratio_rounded, color: Colors.white70),
                title: const Text('Resolution (High to Low)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  widget.controller.sortItemsByResolution();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded, color: Colors.white70),
                title: const Text('Date Added (Newest First)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  widget.controller.sortItemsByDate();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBatchDelete() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF161824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFFF3B30),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Delete $count Wallpaper${count == 1 ? '' : 's'}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These wallpapers will be permanently removed from your collection and app storage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222634),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PressableScale(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withAlpha(80),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Delete ($count)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final idsToDelete = Set<String>.from(_selectedIds);
      _exitSelectionMode();
      final deleted = await widget.controller.deleteItems(idsToDelete);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Deleted $deleted wallpaper${deleted == 1 ? '' : 's'}'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleBatchIncludeExclude(List<WallpaperItem> items) async {
    final selectedItems = items.where((i) => _selectedIds.contains(i.id)).toList();
    if (selectedItems.isEmpty) return;

    final allExcluded = selectedItems.every((i) => !i.isEnabled);
    final allActive = selectedItems.every((i) => i.isEnabled);

    if (allExcluded) {
      final ids = Set<String>.from(_selectedIds);
      _exitSelectionMode();
      await widget.controller.setItemsEnabled(ids, true);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Included ${ids.length} wallpaper${ids.length == 1 ? '' : 's'}'),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else if (allActive) {
      final ids = Set<String>.from(_selectedIds);
      _exitSelectionMode();
      await widget.controller.setItemsEnabled(ids, false);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Excluded ${ids.length} wallpaper${ids.length == 1 ? '' : 's'}'),
            backgroundColor: const Color(0xFFFF9F0A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      // Mixed statuses: Show bottom sheet for user choice
      final count = _selectedIds.length;
      final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF161824),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Update $count Selected Wallpapers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Some selected wallpapers are active and some are excluded.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF34C759), size: 22),
                  ),
                  title: const Text('Include All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Include selected in rotation', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(ctx, 'include'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFFF9F0A), size: 22),
                  ),
                  title: const Text('Exclude All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Exclude selected from rotation', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(ctx, 'exclude'),
                ),
              ],
            ),
          ),
        ),
      );

      if (action == 'include' && mounted) {
        final ids = Set<String>.from(_selectedIds);
        _exitSelectionMode();
        await widget.controller.setItemsEnabled(ids, true);
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Included ${ids.length} wallpaper${ids.length == 1 ? '' : 's'}'),
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (action == 'exclude' && mounted) {
        final ids = Set<String>.from(_selectedIds);
        _exitSelectionMode();
        await widget.controller.setItemsEnabled(ids, false);
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Excluded ${ids.length} wallpaper${ids.length == 1 ? '' : 's'}'),
              backgroundColor: const Color(0xFFFF9F0A),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateAlbumDialog(BuildContext context, {List<String>? initialItemIds}) async {
    final messenger = ScaffoldMessenger.of(context);
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Album',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Nature, Anime, Minimal',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1F2232),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text(
              'Create',
              style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final album = await widget.controller.createAlbum(name, initialItemIds: initialItemIds);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Created album "${album.name}"'),
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    }
  }



  Widget _buildSegmentSwitcher() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF161824),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF262B3A)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  index: 0,
                  label: 'All Wallpapers',
                  count: widget.controller.items.length,
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  index: 1,
                  label: 'Albums',
                  count: widget.controller.albums.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedSegment == index;

    return PressableScale(
      onTap: () {
        if (_selectedSegment != index) {
          if (_isSelectionMode) _exitSelectionMode();
          _albumSearchFocusNode.unfocus();
          setState(() {
            _selectedSegment = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF3B30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNormalHeader(List<WallpaperItem> items) {
    final albums = widget.controller.albums;
    final query = _albumSearchQuery.trim().toLowerCase();
    final filteredAlbums = query.isEmpty
        ? albums
        : albums.where((a) => a.name.toLowerCase().contains(query)).toList();

    return KeyedSubtree(
      key: const ValueKey('normal_header'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    _selectedSegment == 1
                        ? (_albumSearchQuery.trim().isNotEmpty
                            ? '${filteredAlbums.length} of ${albums.length} albums found'
                            : '${albums.length} album${albums.length == 1 ? '' : 's'}${widget.controller.activeAlbum != null ? ' • Active: ${widget.controller.activeAlbum!.name}' : ''}')
                        : (widget.controller.activeAlbum != null
                            ? 'Active: ${widget.controller.activeAlbum!.name} (${widget.controller.activeItems.length})'
                            : '${items.length} wallpapers • ${widget.controller.activeItems.length} active'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                if (_selectedSegment == 0 && items.isNotEmpty) ...[
                  PressableScale(
                    onTap: () => _enterSelectionMode(),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D26),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2C3040)),
                      ),
                      child: const Icon(Icons.checklist_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_selectedSegment == 0) ...[
                  PressableScale(
                    onTap: () => _showSortDialog(context),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D26),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2C3040)),
                      ),
                      child: const Icon(Icons.sort_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PressableScale(
                    onTap: () => _pickImages(context),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(100),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  if (albums.isNotEmpty) ...[
                    PressableScale(
                      onTap: () {
                        if (_albumSearchFocusNode.hasFocus) {
                          _albumSearchFocusNode.unfocus();
                        } else {
                          _albumSearchFocusNode.requestFocus();
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _albumSearchFocusNode.hasFocus || _albumSearchQuery.isNotEmpty
                              ? const Color(0xFFFF3B30).withAlpha(40)
                              : const Color(0xFF1B1D26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _albumSearchFocusNode.hasFocus || _albumSearchQuery.isNotEmpty
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF2C3040),
                          ),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: _albumSearchFocusNode.hasFocus || _albumSearchQuery.isNotEmpty
                              ? const Color(0xFFFF3B30)
                              : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PressableScale(
                    onTap: () => _showCreateAlbumDialog(context),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(100),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'New Album',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(List<WallpaperItem> items) {
    final count = _selectedIds.length;
    final selectedItems = items.where((i) => _selectedIds.contains(i.id)).toList();
    final allExcluded = selectedItems.isNotEmpty && selectedItems.every((i) => !i.isEnabled);

    return KeyedSubtree(
      key: const ValueKey('selection_header'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1D28),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFF3B30).withAlpha(90)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  PressableScale(
                    onTap: _exitSelectionMode,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$count selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PressableScale(
                    onTap: _toggleSelectAll,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        _selectedIds.length == items.length ? 'Deselect All' : 'Select All',
                        style: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: count == 0 ? null : () => _handleBatchIncludeExclude(items),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        decoration: BoxDecoration(
                          color: count == 0
                              ? Colors.white.withAlpha(15)
                              : (allExcluded
                                  ? const Color(0xFF34C759).withAlpha(40)
                                  : const Color(0xFFFF9F0A).withAlpha(40)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: count == 0
                                ? const Color(0xFF383F56)
                                : (allExcluded
                                    ? const Color(0xFF34C759).withAlpha(140)
                                    : const Color(0xFFFF9F0A).withAlpha(140)),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                allExcluded ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                                color: count == 0
                                    ? Colors.white30
                                    : (allExcluded ? const Color(0xFF34C759) : const Color(0xFFFF9F0A)),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                allExcluded ? 'Include' : 'Exclude',
                                style: TextStyle(
                                  color: count == 0
                                      ? Colors.white30
                                      : (allExcluded ? const Color(0xFF34C759) : const Color(0xFFFF9F0A)),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressableScale(
                      onTap: _selectedIds.isEmpty ? null : _confirmBatchDelete,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _selectedIds.isEmpty
                              ? Colors.white.withAlpha(15)
                              : const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedIds.isEmpty
                                ? const Color(0xFF383F56)
                                : const Color(0xFFFF3B30),
                          ),
                          boxShadow: _selectedIds.isEmpty
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(100),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: _selectedIds.isEmpty ? Colors.white30 : Colors.white,
                                size: 16,
                              ),
                              if (_selectedIds.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Delete (${_selectedIds.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF262A38)),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 54,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your gallery is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import photos from your device to start rotating wallpapers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            PressableScale(
              onTap: () => _pickImages(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Import Wallpapers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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

  Widget _buildEmptyAlbumsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF262A38)),
              ),
              child: const Icon(
                Icons.folder_special_outlined,
                size: 54,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No albums created yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create albums like Nature, Anime, or Minimal to curate specific wallpaper rotations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            PressableScale(
              onTap: () => _showCreateAlbumDialog(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create First Album',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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

  Widget _buildAlbumSearchBar() {
    final isFocused = _albumSearchFocusNode.hasFocus;
    final hasQuery = _albumSearchQuery.isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161824),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFFFF3B30)
                  : (hasQuery ? const Color(0xFFFF3B30).withAlpha(120) : const Color(0xFF262B3A)),
              width: isFocused ? 1.4 : 1.0,
            ),
          ),
          child: TextField(
            controller: _albumSearchController,
            focusNode: _albumSearchFocusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFFFF3B30),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search albums...',
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isFocused || hasQuery ? const Color(0xFFFF3B30) : Colors.white38,
                size: 20,
              ),
              suffixIcon: hasQuery
                  ? PressableScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _albumSearchController.clear();
                        setState(() {
                          _albumSearchQuery = '';
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white60,
                          size: 18,
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _albumSearchQuery = val;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoAlbumSearchResultsState(String query) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF262A38)),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No albums found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No albums match "$query". Check for typos or try a different term.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 22),
            PressableScale(
              onTap: () {
                HapticFeedback.selectionClick();
                _albumSearchController.clear();
                _albumSearchFocusNode.unfocus();
                setState(() {
                  _albumSearchQuery = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2232),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2E3346)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Clear Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
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
    );
  }

  int _calculateAlbumColumns(double width) {
    if (width >= 1200) return 5;
    if (width >= 960) return 4;
    if (width >= 640) return 3;
    return 2;
  }

  int _calculateWallpaperColumns(double width) {
    if (width >= 1200) return 6;
    if (width >= 960) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  Widget _buildAlbumsGrid() {
    final allAlbums = widget.controller.albums;
    if (allAlbums.isEmpty) {
      return _buildEmptyAlbumsState();
    }

    final query = _albumSearchQuery.trim().toLowerCase();
    final filteredAlbums = query.isEmpty
        ? allAlbums
        : allAlbums.where((a) => a.name.toLowerCase().contains(query)).toList();

    if (filteredAlbums.isEmpty) {
      return _buildNoAlbumSearchResultsState(_albumSearchQuery.trim());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateAlbumColumns(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 150),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemCount: filteredAlbums.length,
          itemBuilder: (context, index) {
            final album = filteredAlbums[index];
            final isActive = widget.controller.activeAlbumId == album.id;
            final albumItems = widget.controller.getAlbumItems(album.id);
            final coverItem = albumItems.isNotEmpty ? albumItems.first : null;
            final activeCount = albumItems.where((i) => i.isEnabled).length;

            return _buildAlbumCard(album, coverItem, isActive, activeCount);
          },
        );
      },
    );
  }

  Widget _buildAlbumCard(Album album, WallpaperItem? coverItem, bool isActive, int activeCount) {
    final coverFile = coverItem != null ? File(coverItem.path) : null;
    final isAlbumAllExcluded = album.count > 0 && activeCount == 0;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(
              controller: widget.controller,
              albumId: album.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFF3B30) : const Color(0xFF242836),
            width: isActive ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverFile != null && coverFile.existsSync())
                Image.file(coverFile, fit: BoxFit.cover)
              else
                Container(
                  color: const Color(0xFF161822),
                  child: const Center(
                    child: Icon(Icons.folder_rounded, size: 48, color: Colors.white24),
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.transparent,
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              if (isAlbumAllExcluded)
                Container(
                  color: Colors.black.withAlpha(120),
                ),

              if (isActive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shuffle_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'ACTIVE SHUFFLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Container(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  color: const Color(0xFF1B1D28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) async {
                    if (value == 'toggle_active') {
                      HapticFeedback.selectionClick();
                      if (isActive) {
                        await widget.controller.setActiveAlbum(null);
                      } else {
                        await widget.controller.setActiveAlbum(album.id);
                      }
                    } else if (value == 'delete') {
                      await widget.controller.deleteAlbum(album.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Text(
                        isActive ? 'Deselect as Shuffle' : 'Set as Shuffle',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Album', style: TextStyle(color: Color(0xFFFF3B30))),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.count == 0
                          ? '0 wallpapers'
                          : activeCount == album.count
                              ? '${album.count} wallpapers • All active'
                              : activeCount == 0
                                  ? '${album.count} wallpapers • Excluded'
                                  : '${album.count} wallpapers • $activeCount active',
                      style: TextStyle(
                        color: isAlbumAllExcluded ? Colors.white60 : Colors.white70,
                        fontSize: 11.5,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final items = controller.items;

        return PopScope(
      canPop: !_isSelectionMode && _albumSearchQuery.isEmpty && !_albumSearchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isSelectionMode) {
            _exitSelectionMode();
          } else if (_albumSearchFocusNode.hasFocus) {
            _albumSearchFocusNode.unfocus();
          } else if (_albumSearchQuery.isNotEmpty) {
            setState(() {
              _albumSearchController.clear();
              _albumSearchQuery = '';
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0E12),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSelectionMode
                    ? _buildSelectionHeader(items)
                    : _buildNormalHeader(items),
              ),
              if (!_isSelectionMode) _buildSegmentSwitcher(),
              if (!_isSelectionMode && _selectedSegment == 1 && widget.controller.albums.isNotEmpty)
                _buildAlbumSearchBar(),
              Expanded(
                child: _selectedSegment == 0
                    ? (items.isEmpty
                        ? _buildEmptyState()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = _calculateWallpaperColumns(constraints.maxWidth);

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.70,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isCurrent = controller.currentWallpaper?.id == item.id;
                                  final isSelected = _selectedIds.contains(item.id);
                                  return _buildGalleryCard(context, item, isCurrent, isSelected);
                                },
                              );
                            },
                          ))
                    : _buildAlbumsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildGalleryCard(
    BuildContext context,
    WallpaperItem item,
    bool isCurrent,
    bool isSelected,
  ) {
    final fileExists = File(item.path).existsSync();
    final isNext = widget.controller.nextWallpaper?.id == item.id && !isCurrent;

    return PressableScale(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item.id);
        } else {
          WallpaperPreviewDialog.show(
            context,
            item: item,
            controller: widget.controller,
          );
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(item.id);
        } else {
          _toggleSelection(item.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF3B30)
                : (isCurrent
                    ? const Color(0xFFFF3B30)
                    : (isNext ? const Color(0xFF007AFF) : const Color(0xFF232734))),
            width: (isSelected || isCurrent || isNext) ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isSelected ? 120 : 80),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (fileExists)
                Image.file(
                  File(item.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              else
                const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),

              if (!item.isEnabled)
                Container(
                  color: Colors.black.withAlpha(120),
                ),

              if (isSelected)
                Container(
                  color: const Color(0xFFFF3B30).withAlpha(45),
                ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withAlpha(190),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              if (!_isSelectionMode && (isCurrent || isNext || !item.isEnabled))
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(80),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (!item.isEnabled || isNext) const SizedBox(width: 5),
                      ],
                      if (isNext) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(80),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (!item.isEnabled) const SizedBox(width: 5),
                      ],
                      if (!item.isEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(190),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Colors.white60,
                                size: 11,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'EXCLUDED',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFFFF3B30) : Colors.black.withAlpha(150),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF3B30) : Colors.white70,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.circle,
                      color: isSelected ? Colors.white : Colors.transparent,
                      size: 16,
                    ),
                  ),
                ),

              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                  ),
                  child: Text(
                    item.resolutionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              if (!_isSelectionMode)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.controller.toggleItemEnabled(item.id);
                    },
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isEnabled ? const Color(0xFF34C759) : Colors.black.withAlpha(170),
                            border: Border.all(
                              color: item.isEnabled ? const Color(0xFF34C759) : Colors.white30,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(90),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.isEnabled ? Icons.check : Icons.remove_circle_outline_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
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
