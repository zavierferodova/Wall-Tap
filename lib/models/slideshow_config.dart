import 'dart:convert';

class SlideshowConfig {
  final String targetScreen; // 'both', 'home', 'lock'
  final String scaleType; // 'full', 'crop', 'fit'
  final String? defaultHomePath;
  final String? defaultLockPath;
  final String defaultScaleType; // 'full', 'crop', 'fit'
  final int currentIndex;
  final bool isRandom;
  final bool isSlideshowEnabled;
  final int intervalMinutes; // 0 = manual / widget tap only
  final bool showPersistentNotification;

  const SlideshowConfig({
    this.targetScreen = 'both',
    this.scaleType = 'crop',
    this.defaultHomePath,
    this.defaultLockPath,
    this.defaultScaleType = 'crop',
    this.currentIndex = 0,
    this.isRandom = false,
    this.isSlideshowEnabled = false,
    this.intervalMinutes = 0,
    this.showPersistentNotification = false,
  });

  String get targetScreenLabel {
    switch (targetScreen) {
      case 'home':
        return 'Home screen';
      case 'lock':
        return 'Lock screen';
      case 'both':
      default:
        return 'Home and Lock screen';
    }
  }

  String get scaleTypeLabel {
    switch (scaleType) {
      case 'crop':
        return 'Center crop';
      case 'fit':
        return 'Fit image';
      case 'full':
      default:
        return 'Full image';
    }
  }

  String get intervalLabel {
    if (intervalMinutes <= 0) return 'Off (Manual)';
    if (intervalMinutes == 1) return '1 minute';
    if (intervalMinutes < 60) return '$intervalMinutes minutes';
    if (intervalMinutes == 60) return '1 hour';
    if (intervalMinutes == 1440) return 'Daily (24h)';
    return '${intervalMinutes ~/ 60} hours';
  }

  SlideshowConfig copyWith({
    String? targetScreen,
    String? scaleType,
    String? defaultHomePath,
    bool clearDefaultHome = false,
    String? defaultLockPath,
    bool clearDefaultLock = false,
    String? defaultScaleType,
    int? currentIndex,
    bool? isRandom,
    bool? isSlideshowEnabled,
    int? intervalMinutes,
    bool? showPersistentNotification,
  }) {
    return SlideshowConfig(
      targetScreen: targetScreen ?? this.targetScreen,
      scaleType: scaleType ?? this.scaleType,
      defaultHomePath: clearDefaultHome ? null : (defaultHomePath ?? this.defaultHomePath),
      defaultLockPath: clearDefaultLock ? null : (defaultLockPath ?? this.defaultLockPath),
      defaultScaleType: defaultScaleType ?? this.defaultScaleType,
      currentIndex: currentIndex ?? this.currentIndex,
      isRandom: isRandom ?? this.isRandom,
      isSlideshowEnabled: isSlideshowEnabled ?? this.isSlideshowEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      showPersistentNotification: showPersistentNotification ?? this.showPersistentNotification,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetScreen': targetScreen,
      'scaleType': scaleType,
      'defaultHomePath': defaultHomePath,
      'defaultLockPath': defaultLockPath,
      'defaultScaleType': defaultScaleType,
      'currentIndex': currentIndex,
      'isRandom': isRandom,
      'isSlideshowEnabled': isSlideshowEnabled,
      'intervalMinutes': intervalMinutes,
      'showPersistentNotification': showPersistentNotification,
    };
  }

  factory SlideshowConfig.fromMap(Map<String, dynamic> map) {
    return SlideshowConfig(
      targetScreen: map['targetScreen'] as String? ?? 'both',
      scaleType: map['scaleType'] as String? ?? 'crop',
      defaultHomePath: map['defaultHomePath'] as String?,
      defaultLockPath: map['defaultLockPath'] as String?,
      defaultScaleType: map['defaultScaleType'] as String? ?? 'crop',
      currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
      isRandom: map['isRandom'] as bool? ?? false,
      isSlideshowEnabled: map['isSlideshowEnabled'] as bool? ?? false,
      intervalMinutes: (map['intervalMinutes'] as num?)?.toInt() ?? 0,
      showPersistentNotification: map['showPersistentNotification'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SlideshowConfig.fromJson(String source) =>
      SlideshowConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}
