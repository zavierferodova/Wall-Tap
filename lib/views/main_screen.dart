import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/wallpaper_controller.dart';
import 'slideshow/slideshow_tab.dart';
import 'playlist/playlist_tab.dart';
import 'album_widgets/album_widgets_tab.dart';
import 'settings/settings_tab.dart';
import 'widgets/pressable_scale.dart';

class MainScreen extends StatefulWidget {
  final WallpaperController controller;

  const MainScreen({super.key, required this.controller});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.loadAlbumWidgets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.reloadFromStorage();
      widget.controller.loadAlbumWidgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      extendBody: true,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              SlideshowTab(controller: widget.controller),
              PlaylistTab(controller: widget.controller),
              AlbumWidgetsTab(controller: widget.controller),
              SettingsTab(controller: widget.controller),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xB8161824),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFF2B3042), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          label: 'Studio',
                          icon: Icons.shuffle_rounded,
                        ),
                        _buildNavItem(
                          index: 1,
                          label: 'Library',
                          icon: Icons.photo_library_rounded,
                        ),
                        _buildNavItem(
                          index: 2,
                          label: 'Widgets',
                          icon: Icons.widgets_rounded,
                        ),
                        _buildNavItem(
                          index: 3,
                          label: 'Settings',
                          icon: Icons.tune_rounded,
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
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      flex: isSelected ? 3 : 2,
      child: PressableScale(
        onTap: () {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
            widget.controller.reloadFromStorage();
            widget.controller.loadAlbumWidgets();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF3B30) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 20,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
