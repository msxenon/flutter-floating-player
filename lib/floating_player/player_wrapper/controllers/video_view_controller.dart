import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';

class FloatingViewController extends GetxController {
  static const String detailsControllerId = 'detailsController1';
  final Duration toggleOffDuration = const Duration(seconds: 5);
  VlcPlayerController videoPlayerController;
  RxBool isMaximized = true.obs;
  RxBool _showControllerView = false.obs;
  RxBool get showControllerView => _showControllerView;
  bool get showDetails => detailsTopPadding > 0;
  double detailsTopPadding = 0;
  Size screenSize;
  double initialHeight;
  Timer controllerTimer;
  bool isFullScreen = false;
  FloatingViewController({this.screenSize}) {
    if (screenSize?.width == null) {
      screenSize = Size(Get.width, Get.height);
    }
    initialHeight = screenSize.width / (16 / 9);
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

  VlcPlayerController createController() {
    videoPlayerController = videoPlayerController = VlcPlayerController.network('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        hwAcc: HwAcc.FULL, autoPlay: true, options: VlcPlayerOptions(), autoInitialize: true);
    return videoPlayerController;
  }

  void minimize() {}
  @override
  void onInit() async {
    super.onInit();
    // await Future.delayed(Duration(seconds: 1));
    // await videoPlayerController.initialize();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void dispose() {
    videoPlayerController?.stopRendererScanning();
    videoPlayerController?.removeListener(() {});
    controllerTimer?.cancel();
    super.dispose();
  }

  void onMaximizedStateChange(bool _isMaximized) {
    isMaximized.value = _isMaximized;
  }

  void onDraggingChange(bool dragging) {}

  void setPlayerHeight(double d) {
    detailsTopPadding = d;
    update(List.of([detailsControllerId]));
  }

  void _startToggleOffTimer() {
    controllerTimer = Timer(toggleOffDuration, () {
      if (_showControllerView.value) {
        showControllerViewValue = false;
      }
    });
  }

  void toggleFullScreen() {
    if (!isFullScreen) {
      ///is going full screen
      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    isFullScreen = !isFullScreen;
    update();
  }
}
