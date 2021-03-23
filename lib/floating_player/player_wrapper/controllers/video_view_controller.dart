import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/played_item_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';
import 'package:subtitle_wrapper_package/subtitle_controller.dart';
import 'package:wakelock/wakelock.dart';

import '../../draggable_widget.dart';
import '../mock_data.dart';

enum TextSizes { normal, medium, large, xlarge }

class PlayerSettingsController extends GetxController {
  SubtitleController subtitleController;
  DateTime dateTime;
  String link;
  bool isEnabled = false;
  Map<String, String> videoResolutions = {};
  String selectedRes;
  TextSizes textEnum = TextSizes.medium;
  static const double _defaultTextSize = 20;
  double textSize = _defaultTextSize;
  Function(Duration, dynamic videoItem, String itemId) onDisposeListener;
  double _getTextSize() {
    double result = _defaultTextSize;
    switch (textEnum) {
      case TextSizes.normal:
        result = result * 1;
        break;
      case TextSizes.medium:
        result = (result * 1.5);
        break;
      case TextSizes.large:
        result = (result * 2);
        break;
      case TextSizes.xlarge:
        result = (result * 3);
        break;
    }
    return result;
  }

  void setTextSize(TextSizes _textSize) {
    textEnum = _textSize;
    textSize = _getTextSize();
    update();
  }

  void initVideoResolutions(Map<String, String> res) {
    videoResolutions = res;
    if (selectedRes == null || !videoResolutions.containsKey(selectedRes)) {
      selectedRes = videoResolutions.keys.first;
    }
  }

  void changeVideoRes(String name) {
    if (name == selectedRes) {
      return;
    }
    selectedRes = name;
    Get.find<FloatingViewController>().setNewVideo();
    print('video set $name ${getVideo()}');
    update();
  }

  String getVideo() {
    return videoResolutions[selectedRes];
  }

  Future<void> initSubtitles({String subtitleLink}) async {
    this.link = subtitleLink;
    return _setSubtitle();
  }

  String getCaptionStringValue() {
    if (isEnabled == null) {
      return 'Unavailable'.tr;
    } else if (isEnabled) {
      return 'Arabic'.tr;
    } else {
      return 'Off'.tr;
    }
  }

  Future<void> _setSubtitle() async {
    var subtitleLink = link;
    var subtitleType = SubtitleType.values.firstWhere(
        (e) => subtitleLink.split('.')?.last == e.getName(),
        orElse: () => SubtitleType.webvtt);
    if (subtitleController == null) {
      isEnabled = link?.isNotEmpty == true;
    }
    subtitleController = SubtitleController(
        subtitleUrl: subtitleLink,
        subtitleType: subtitleType,
        showSubtitles: isEnabled);
    return;
  }

  void toggleSubtitle(bool forceIsEnabled) {
    print('toggle subtitle $forceIsEnabled == $isEnabled');

    if (forceIsEnabled == isEnabled) {
      return;
    }
    isEnabled = forceIsEnabled;
    update();

    print('toggle subtitle end $isEnabled');
  }
}

extension SubtitleTypeX on SubtitleType {
  getName() => this.toString().split('.').last;
}

class FloatingViewController extends GetxController {
  final Duration toggleOffDuration = const Duration(seconds: 5);
  VlcPlayerController videoPlayerController;
  var controlsIsShowing = false.obs;
  PlayerSettingsController playerSettingsController =
      Get.put(PlayerSettingsController());

  bool get showDetails => detailsTopPadding > 0;
  double detailsTopPadding = 0;
  Size screenSize;
  double initialHeight;
  Timer controllerTimer;
  Timer savePositionTimer;
  var anchoringPosition = AnchoringPosition.maximized.obs;
  var isFullScreen = false.obs;
  var isMaximized = true.obs;
  var dragging = false.obs;
  var controllersCanBeVisible = true.obs;
  var canMinimize = true.obs;
  var canClose = true.obs;
  var isUsingController = false.obs;
  OverlayEntry _overlayEntry;
  Color floatingBottomSheetBgColor = Colors.white;
  Color floatingBottomSheetTextColor = Colors.black87;
  Color floatingBottomSheetDivColor = Colors.black.withOpacity(0.3);
  OverlayControllerData customController;
  WidgetBuilder customControllers;
  PlayerData _playerData;

  @override
  onInit() {
    anchoringPosition.value = AnchoringPosition.maximized;
    dragging.value = false;
    super.onInit();
  }

  FloatingViewController({this.screenSize}) {
    if (screenSize?.width == null) {
      screenSize = Size(MediaQuery.of(Get.context).size.width,
          MediaQuery.of(Get.context).size.height);
    }
    initialHeight = screenSize.width / (16 / 9);
    anchoringPosition.listen((x) {
      print('anchoringPosition changed $x');
    });
    ever(anchoringPosition, (f) {
      isMaximized(anchoringPosition.value == AnchoringPosition.maximized);
      isFullScreen(anchoringPosition.value == AnchoringPosition.fullScreen);
      controllersCanBeVisible(!dragging.value &&
          anchoringPosition.value != AnchoringPosition.minimized);
      canMinimize(isMaximized.value);
      canClose(!isFullScreen.value);
      removeOverlay();
    });

    ever(dragging, (f) {
      controllersCanBeVisible(!dragging.value &&
          anchoringPosition.value != AnchoringPosition.minimized);
      if (dragging.value) {
        controlsIsShowing(false);
      }
      removeOverlay();
    });
    ever(isUsingController, (f) {
      if (isUsingController.value) {
        controllerTimer?.cancel();
      } else {
        _startToggleOffTimer();
      }
    });
  }

  void toggleControllers() {
    if (!controllersCanBeVisible.value) {
      return;
    }
    controlsIsShowing(!controlsIsShowing.value);
    if (controlsIsShowing.value) {
      _startToggleOffTimer();
    } else {
      controllerTimer?.cancel();
    }
  }

  Future<void> createController(PlayerData playerData) async {
    _playerData = playerData;
    var videoRes = (playerData.videoRes == null || playerData.useMockData)
        ? {'BigBunny': MockData.mp4Bunny, 'Other': MockData.shortMovie}
        : playerData.videoRes;
    var subtitleLink = (playerData.subtitle == null || playerData.useMockData)
        ? MockData.srt
        : playerData.subtitle;
    playerSettingsController.initVideoResolutions(videoRes);
    await setNewVideo();
    await playerSettingsController.initSubtitles(subtitleLink: subtitleLink);
    return;
  }

  Future<void> setNewVideo() async {
    videoPlayerController = VlcPlayerController.network(
        playerSettingsController.getVideo(),
        hwAcc: HwAcc.FULL,
        autoPlay: true,
        options: VlcPlayerOptions(), onInit: () async {
      if (_playerData?.startPosition != null) {
        await Future.delayed(Duration(milliseconds: 1000));
        videoPlayerController?.seekTo(_playerData.startPosition);
      }
    }, autoInitialize: true);
    videoPlayerController.addListener(() async {
      await refreshWakelock();
    });

    return;
  }

  Future<void> refreshWakelock() async {
    if (videoPlayerController.value.isPlaying) {
      if (!await Wakelock.enabled) {
        _startSavePositionTimer();
        await Wakelock.enable();
      }
    } else {
      if (await Wakelock.enabled) {
        _stopSavePositionTimer();
        await Wakelock.disable();
      }
    }
    return;
  }

  @override
  void onClose() {
    removeOverlay();
    normalScreenOptions();
    _stopSavePositionTimer();
    super.onClose();
  }

  void minimize() {
    anchoringPosition(AnchoringPosition.minimized);
  }

  @override
  void dispose() {
    removeOverlay();
    videoPlayerController?.stopRendererScanning();
    videoPlayerController?.removeListener(() {});
    controllerTimer?.cancel();
    normalScreenOptions();
    super.dispose();
  }

  void onDraggingChange(bool dragging) {}

  void setPlayerHeight(double d) {
    detailsTopPadding = d;
    update();
  }

  void _startToggleOffTimer() {
    controllerTimer = Timer(toggleOffDuration, () {
      controlsIsShowing(false);
    });
  }

  void toggleFullScreen() {
    if (!isFullScreen.value) {
      anchoringPosition(AnchoringPosition.fullScreen);

      ///is going full screen
      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      anchoringPosition(AnchoringPosition.maximized);
      normalScreenOptions();
    }
    update();
  }

  void normalScreenOptions() {
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  showOverlay(BuildContext context, WidgetBuilder w) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(builder: (context) => w(context));
    Overlay.of(context).insert(_overlayEntry);
    print('overlay is showing');
  }

  DateTime overlayRemoveTimeStamp;
  removeOverlay() {
    if (_overlayEntry != null) {
      overlayRemoveTimeStamp = DateTime.now();
      _overlayEntry?.remove();
      _overlayEntry = null;
      print('overlay removed');
    }
  }

  @override
  String toString() {
    return 'FloatingViewController{toggleOffDuration: $toggleOffDuration, videoPlayerController: $videoPlayerController, controlsIsShowing: $controlsIsShowing, detailsTopPadding: $detailsTopPadding, screenSize: $screenSize, initialHeight: $initialHeight, controllerTimer: $controllerTimer, anchoringPosition: $anchoringPosition, isFullScreen: $isFullScreen, isMaximized: $isMaximized, dragging: $dragging, controllersCanBeVisible: $controllersCanBeVisible, canMinimize: $canMinimize, canClose: $canClose}';
  }

  bool overlayJustRemoved() {
    return _overlayEntry != null ||
        (overlayRemoveTimeStamp
                ?.add(Duration(seconds: 1))
                ?.isAfter(DateTime.now()) ??
            false);
  }

  void playerDispose() async {
    savePosition();
    _playerData?.onDispose();
  }

  void savePosition() {
    try {
      final currentPos = videoPlayerController?.value?.position;
      if (currentPos == null) {
        return;
      }
      _playerData?.savePosition(SavePosition(
          seconds: currentPos.inSeconds,
          videoItem: _playerData.videoItem,
          itemId: _playerData.itemId));
    } catch (e) {
      print(e);
    }
  }

  PlayerData pLayData() {
    return _playerData;
  }

  bool isLive() {
    return _playerData.playType == PlayType.live;
  }

  bool hasOptions() {
    return _playerData.subtitle != null;
  }

  void _stopSavePositionTimer() {
    savePositionTimer?.cancel();
    savePositionTimer = null;
  }

  void _startSavePositionTimer() {
    if (savePositionTimer != null) {
      return;
    }
    savePositionTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      savePosition();
    });
  }
}
