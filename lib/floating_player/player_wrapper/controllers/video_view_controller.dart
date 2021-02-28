import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';
import 'package:subtitle_wrapper_package/subtitle_controller.dart';

import '../../draggable_widget.dart';

enum TextSizes { normal, medium, large, xlarge }

class PlayerSettingsController extends GetxController {
  SubtitleController subtitleController;
  DateTime dateTime;
  String link;
  bool isEnabled;
  Map<String, String> videoResolutions = {};
  String selectedRes;
  TextSizes textEnum = TextSizes.medium;
  static const double _defaultTextSize = 20;
  double textSize = _defaultTextSize;
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

  void initSubtitles({String subtitleLink}) {
    this.link = subtitleLink;
    _setSubtitle();
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

  void _setSubtitle() {
    var subtitleLink = link;
    var subtitleType = SubtitleType.values.firstWhere((e) => subtitleLink.split('.')?.last == e.getName(), orElse: () => SubtitleType.webvtt);
    if (subtitleController == null) {
      isEnabled = link?.isNotEmpty == true;
    }
    subtitleController = SubtitleController(subtitleUrl: subtitleLink, subtitleType: subtitleType, showSubtitles: isEnabled);
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
  PlayerSettingsController playerSettingsController = Get.put(PlayerSettingsController());
  bool get showDetails => detailsTopPadding > 0;
  double detailsTopPadding = 0;
  Size screenSize;
  double initialHeight;
  Timer controllerTimer;
  var anchoringPosition = AnchoringPosition.maximized.obs;
  var isFullScreen = false.obs;
  var isMaximized = true.obs;
  var dragging = false.obs;
  var controllersCanBeVisible = true.obs;
  var canMinimize = true.obs;
  var canClose = true.obs;
  OverlayEntry _overlayEntry;
  Color floatingBottomSheetBgColor = Colors.white;
  Color floatingBottomSheetTextColor = Colors.black87;
  Color floatingBottomSheetDivColor = Colors.black.withOpacity(0.3);
  OverlayControllerData customController;
  WidgetBuilder customControllers;

  @override
  onInit() {
    anchoringPosition.value = AnchoringPosition.maximized;
    dragging.value = false;
    super.onInit();
  }

  FloatingViewController({this.screenSize}) {
    if (screenSize?.width == null) {
      screenSize = Size(Get.width, Get.height);
    }
    initialHeight = screenSize.width / (16 / 9);
    anchoringPosition.listen((x) {
      print('anchoringPosition changed $x');
    });
    ever(anchoringPosition, (f) {
      isMaximized(anchoringPosition.value == AnchoringPosition.maximized);
      isFullScreen(anchoringPosition.value == AnchoringPosition.fullScreen);
      controllersCanBeVisible(!dragging.value && anchoringPosition.value != AnchoringPosition.minimized);
      canMinimize(isMaximized.value);
      canClose(!isFullScreen.value);
      removeOverlay();
    });

    ever(dragging, (f) {
      controllersCanBeVisible(!dragging.value && anchoringPosition.value != AnchoringPosition.minimized);
      if (dragging.value) {
        controlsIsShowing(false);
      }
      removeOverlay();
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

  void createController({VlcPlayerController vlcPlayerController, Map<String, String> videoRes, String subtitleLink}) {
    print('create controllercalled');
    playerSettingsController.initVideoResolutions(videoRes);
    setNewVideo();
    playerSettingsController.initSubtitles(subtitleLink: subtitleLink);
  }

  void setNewVideo() {
    print('create controllercalled');

    videoPlayerController = VlcPlayerController.network(playerSettingsController.getVideo(), hwAcc: HwAcc.FULL, autoPlay: true, options: VlcPlayerOptions(), autoInitialize: true);
  }

  @override
  void onClose() {
    removeOverlay();
    normalScreenOptions();
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
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
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
    return _overlayEntry != null || (overlayRemoveTimeStamp?.add(Duration(seconds: 1))?.isAfter(DateTime.now()) ?? false);
  }
}
