import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';

import '../../draggable_widget.dart';

class FloatingViewController extends GetxController {
  final Duration toggleOffDuration = const Duration(seconds: 5);
  VlcPlayerController videoPlayerController;
  var controlsIsShowing = false.obs;

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
    });

    ever(dragging, (f) {
      controllersCanBeVisible(!dragging.value && anchoringPosition.value != AnchoringPosition.minimized);
      if (dragging.value) {
        controlsIsShowing(false);
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

  void createController({VlcPlayerController vlcPlayerController}) {
    videoPlayerController = vlcPlayerController ??
        VlcPlayerController.network('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            hwAcc: HwAcc.FULL, autoPlay: true, options: VlcPlayerOptions(), autoInitialize: true);
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
      videoPlayerController?.isPlaying()?.then((isPlaying) {
        if (controlsIsShowing.value && isPlaying) {
          controlsIsShowing(false);
        }
      });
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

  @override
  String toString() {
    return 'FloatingViewController{toggleOffDuration: $toggleOffDuration, videoPlayerController: $videoPlayerController, controlsIsShowing: $controlsIsShowing, detailsTopPadding: $detailsTopPadding, screenSize: $screenSize, initialHeight: $initialHeight, controllerTimer: $controllerTimer, anchoringPosition: $anchoringPosition, isFullScreen: $isFullScreen, isMaximized: $isMaximized, dragging: $dragging, controllersCanBeVisible: $controllersCanBeVisible, canMinimize: $canMinimize, canClose: $canClose}';
  }
}
