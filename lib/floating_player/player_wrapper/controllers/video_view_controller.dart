import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';

import '../../draggable_widget.dart';

class FloatingViewController extends GetxController {
  final Duration toggleOffDuration = const Duration(seconds: 5);
  VlcPlayerController videoPlayerController;
  RxBool _showControllerView = false.obs;
  RxBool get showControllerView => _showControllerView;
  bool get showDetails => detailsTopPadding > 0;
  double detailsTopPadding = 0;
  Size screenSize;
  double initialHeight;
  Timer controllerTimer;
  var anchoringPosition = AnchoringPosition.maximized.obs;
  var isFullScreen = false.obs;
  RxBool isMaximized = true.obs;
  var dragging = false.obs;
  var controllersCanBeVisible = true.obs;
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
    });

    ever(dragging, (f) {
      controllersCanBeVisible(!dragging.value && anchoringPosition.value != AnchoringPosition.minimized);
    });
  }
  set showControllerViewValue(bool value) {
    _showControllerView.value = value && isMaximized.value;
  }

  void toggleControllers() {
    showControllerViewValue = (!_showControllerView.value);
    if (_showControllerView.value) {
      _startToggleOffTimer();
    } else {
      controllerTimer?.cancel();
    }
  }

  VlcPlayerController createController({VlcPlayerController vlcPlayerController}) {
    videoPlayerController = vlcPlayerController ??
        VlcPlayerController.network('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            hwAcc: HwAcc.FULL, autoPlay: true, options: VlcPlayerOptions(), autoInitialize: true);
    return videoPlayerController;
  }

  @override
  void onClose() {
    normalScreenOptions();
    super.onClose();
  }

  void minimize() {
    anchoringPosition(AnchoringPosition.minimized);
  }

  @override
  void dispose() {
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
      if (_showControllerView.value) {
        showControllerViewValue = false;
      }
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
}
