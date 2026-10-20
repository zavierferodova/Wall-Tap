import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/wallpaper_controller.dart';
import '../../models/album.dart';
import '../../models/wallpaper_item.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/wallpaper_preview_dialog.dart';

class AlbumDetailScreen extends StatefulWidget {
  final WallpaperController controller;
  final String albumId;

  const AlbumDetailScreen({
    super.key,
    required this.controller,
    required this.albumId,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<WallpaperItem> items) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(items.map((e) => e.id));
      }
    });
  }

  Future<void> _showRenameDialog(BuildContext context, String currentName) async {
    final textController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Rename Album',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Album name',
            hintStyle: const TextStyle(color: Colors.white60),
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
              'Save',
              style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await widget.controller.renameAlbum(widget.albumId, newName);
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Add Wallpapers to Album',
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
                        color: const Color(0xFFFF3B30).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_library_outlined, color: Color(0xFFFF3B30)),
                    ),
                    title: const Text('Add from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Select from existing wallpapers', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSelectFromGalleryDialog(context);
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF34C759)),
                    ),
                    title: const Text('Import New Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Pick photos from your device storage', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final images = await picker.pickMultiImage();
                      if (images.isNotEmpty && mounted) {
                        final paths = images.map((e) => e.path).toList();
                        final count = await widget.controller.importImages(paths, targetAlbumId: widget.albumId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $count wallpaper${count == 1 ? '' : 's'} to album'),
                              backgroundColor: const Color(0xFF34C759),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectFromGalleryDialog(BuildContext context) {
    final albumItems = widget.controller.getAlbumItems(widget.albumId);
    final existingIds = albumItems.map((e) => e.id).toSet();
    final candidateItems = widget.controller.items.where((e) => !existingIds.contains(e.id)).toList();

    if (candidateItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All wallpapers are already in this album.'),
          backgroundColor: Color(0xFF222634),
        ),
      );
      return;
    }

    final selectedCandidateIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF12141E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final mediaQuery = MediaQuery.of(context);
          final sheetHeight = mediaQuery.size.height - mediaQuery.padding.top;
          return SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox(
                  height: sheetHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4.5,
                            margin: const EdgeInsets.only(top: 4, bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add Existing Wallpapers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedCandidateIds.length} selected',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                            PressableScale(
                              onTap: () {
                                setModalState(() {
                                  if (selectedCandidateIds.length == candidateItems.length) {
                                    selectedCandidateIds.clear();
                                  } else {
                                    selectedCandidateIds.clear();
                                    selectedCandidateIds.addAll(candidateItems.map((e) => e.id));
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  selectedCandidateIds.length == candidateItems.length ? 'Deselect All' : 'Select All',
                                  style: const TextStyle(
                                    color: Color(0xFFFF3B30),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth >= 900
                                  ? 5
                                  : constraints.maxWidth >= 700
                                      ? 4
                                      : constraints.maxWidth >= 500
                                          ? 3
                                          : 2;
                              return GridView.builder(
                                itemCount: candidateItems.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.65,
                                ),
                                itemBuilder: (context, index) {
                                  final item = candidateItems[index];
                                  final isSelected = selectedCandidateIds.contains(item.id);
                                  final file = File(item.path);

                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedCandidateIds.remove(item.id);
                                        } else {
                                          selectedCandidateIds.add(item.id);
                                        }
                                      });
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: file.existsSync()
                                              ? Image.file(file, fit: BoxFit.cover)
                                              : Container(color: Colors.grey.shade900),
                                        ),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFFFF3B30) : Colors.transparent,
                                              width: 2.5,
                                            ),
                                            color: isSelected ? const Color(0xFFFF3B30).withAlpha(50) : Colors.transparent,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? const Color(0xFFFF3B30) : Colors.black54,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check, size: 15, color: Colors.white)
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: PressableScale(
                            onTap: selectedCandidateIds.isEmpty
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(ctx);
                                    await widget.controller.addItemsToAlbum(
                                      widget.albumId,
                                      selectedCandidateIds,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Added ${selectedCandidateIds.length} wallpapers to album'),
                                        backgroundColor: const Color(0xFF34C759),
                                      ),
                                    );
                                  },
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedCandidateIds.isEmpty
                                    ? const Color(0xFF222634)
                                    : const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: selectedCandidateIds.isEmpty
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(80),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Add (${selectedCandidateIds.length}) to Album',
                                style: TextStyle(
                                  color: selectedCandidateIds.isEmpty ? Colors.white38 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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

  Future<void> _showBatchDeleteSheet() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF161824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                'Delete $count Wallpaper${count == 1 ? '' : 's'}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose whether to remove from this album or permanently delete.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF242938),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.playlist_remove_rounded, color: Color(0xFFFF3B30), size: 22),
                ),
                title: const Text('Remove from Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Remove from this album only, keep in gallery', style: TextStyle(color: Colors.white54, fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF3B30), size: 22),
                ),
                title: const Text(
                  'Delete Permanently',
                  style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Permanently delete from storage and all albums', style: TextStyle(color: Colors.white54, fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (action == 'remove' && mounted) {
      final toRemove = Set<String>.from(_selectedIds);
      _exitSelectionMode();
      await widget.controller.removeItemsFromAlbum(widget.albumId, toRemove);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Removed $count wallpaper${count == 1 ? '' : 's'} from album'),
            backgroundColor: const Color(0xFF2A2D3D),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else if (action == 'delete' && mounted) {
      final toDelete = Set<String>.from(_selectedIds);
      _exitSelectionMode();
      final deleted = await widget.controller.deleteItems(toDelete);
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

  int _calculateWallpaperColumns(double width) {
    if (width >= 1200) return 6;
    if (width >= 960) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final albums = widget.controller.albums;
        final index = albums.indexWhere((a) => a.id == widget.albumId);

        if (index == -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const Scaffold(backgroundColor: Color(0xFF0D0E12));
        }

        final album = albums[index];

        final items = widget.controller.getAlbumItems(album.id);
        final isActiveShuffle = widget.controller.activeAlbumId == album.id;

        return PopScope(
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _exitSelectionMode();
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
                        : _buildHeader(album, items.length, items.where((i) => i.isEnabled).length, isActiveShuffle),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState(context)
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = _calculateWallpaperColumns(constraints.maxWidth);
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.70,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isSelected = _selectedIds.contains(item.id);

                                  return _buildWallpaperCard(
                                    context: context,
                                    item: item,
                                    index: index,
                                    isSelected: isSelected,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Album album, int itemCount, int activeCount, bool isActiveShuffle) {
    return KeyedSubtree(
      key: const ValueKey('album_header'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PressableScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2C3040)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showRenameDialog(context, album.name),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            album.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_rounded, color: Colors.white60, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (itemCount > 0) ...[
                  PressableScale(
                    onTap: () => _enterSelectionMode(),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D26),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2C3040)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.checklist_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                PressableScale(
                  onTap: () => _showAddOptions(context),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(90),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$itemCount wallpaper${itemCount == 1 ? '' : 's'} • $activeCount active',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    if (isActiveShuffle) {
                      await widget.controller.setActiveAlbum(null);
                    } else {
                      await widget.controller.setActiveAlbum(album.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActiveShuffle ? const Color(0xFFFF3B30).withAlpha(40) : const Color(0xFF1B1D26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActiveShuffle ? const Color(0xFFFF3B30) : const Color(0xFF2C3040),
                      ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActiveShuffle ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                          color: isActiveShuffle ? const Color(0xFFFF3B30) : Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActiveShuffle ? 'Active' : 'Use in Shuffle',
                          style: TextStyle(
                            color: isActiveShuffle ? const Color(0xFFFF3B30) : Colors.white70,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(List<WallpaperItem> items) {
    final count = _selectedIds.length;
    final allSelected = items.isNotEmpty && count == items.length;
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$count selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _toggleSelectAll(items);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        allSelected ? 'Deselect All' : 'Select All',
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
                        alignment: Alignment.center,
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
                      onTap: count == 0 ? null : () => _showBatchDeleteSheet(),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        decoration: BoxDecoration(
                          color: count == 0
                              ? Colors.white.withAlpha(15)
                              : const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: count == 0
                                ? const Color(0xFF383F56)
                                : const Color(0xFFFF3B30),
                          ),
                          boxShadow: count > 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(90),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: count > 0 ? Colors.white : Colors.white30,
                                size: 16,
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Delete ($count)',
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C28),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C3040)),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 38,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Wallpapers in Album',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add wallpapers from your gallery or import new photos to start curating this album.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            PressableScale(
              onTap: () => _showAddOptions(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Wallpapers',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  Widget _buildWallpaperCard({
    required BuildContext context,
    required WallpaperItem item,
    required int index,
    required bool isSelected,
  }) {
    final file = File(item.path);
    final isCurrent = widget.controller.currentWallpaper?.id == item.id;
    final isNext = widget.controller.nextWallpaper?.id == item.id && !isCurrent;

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(item.id);
        }
      },
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF3B30)
                : (isCurrent
                    ? const Color(0xFFFF3B30)
                    : (isNext ? const Color(0xFF007AFF) : const Color(0xFF242836))),
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
              if (file.existsSync())
                Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF1B1D26),
                    child: const Icon(Icons.broken_image, color: Colors.white38),
                  ),
                )
              else
                Container(
                  color: const Color(0xFF1B1D26),
                  child: const Icon(Icons.broken_image, color: Colors.white38),
                ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.transparent,
                      Colors.black.withAlpha(160),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              if (!item.isEnabled)
                Container(
                  color: Colors.black.withAlpha(120),
                ),

              if (isSelected)
                Container(
                  color: const Color(0xFFFF3B30).withAlpha(45),
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
                left: 8,
                bottom: 8,
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
