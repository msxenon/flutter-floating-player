import 'dart:async';
import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_data.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_settings_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_state_enum.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/save_position.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:flutter_player/player_init.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import '../../draggable_widget.dart';
import '../mock_data.dart';

class FloatingViewController extends GetxController {
  FloatingViewController(
    this.playerData, {
    @required this.customController,
    this.screenSize,
  }) {
    if (screenSize?.width == null) {
      screenSize = Size(MediaQuery.of(Get.context).size.width,
          MediaQuery.of(Get.context).size.height);
    }
    initialHeight = screenSize.width / (16 / 9);
    anchoringPosition.listen((x) {
      debugPrint('anchoringPosition changed $x');
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
    ever(playerSettings.isConnected, (f) async {
      final newState = playerSettings.isConnected.value
          ? PlayerState.casting
          : PlayerState.normal;
      if (newState != playerState) {
        playerState = newState;
        update();

        await videoPlayerController?.pause();
      }
    });
    ever(dragging, (f) {
      controllersCanBeVisible(!dragging.value &&
          anchoringPosition.value != AnchoringPosition.minimized);
      if (dragging.value) {
        controlsIsShowing(false);
      }
      removeOverlay();
    });
    ever(controlsIsShowing, (f) {
      if (controlsIsShowing.value) {
        controllerTimer?.cancel();
      } else {
        _startToggleOffTimer();
      }
    });
  }

  final Duration toggleOffDuration = const Duration(seconds: 5);
  VideoPlayerController videoPlayerController;
  var controlsIsShowing = false.obs;
  PlayerSettingsController playerSettingsController =
      Get.put(PlayerSettingsController(), permanent: true);
  PlayerState playerState = PlayerState.normal;
  String errorMessage = '';
  bool get showDetails => detailsTopPadding > 0;
  double detailsTopPadding = 0;
  Size screenSize;
  double initialHeight;
  Timer controllerTimer;
  Timer savePositionTimer;
  final anchoringPosition = AnchoringPosition.maximized.obs;
  final isFullScreen = false.obs;
  final isMaximized = true.obs;
  final dragging = false.obs;
  final controllersCanBeVisible = true.obs;
  final canMinimize = true.obs;
  final canClose = true.obs;
  OverlayEntry _overlayEntry;
  final Color floatingBottomSheetBgColor = Colors.white;
  final Color floatingBottomSheetTextColor = Colors.black87;
  final Color floatingBottomSheetDivColor = Colors.black.withOpacity(0.3);
  final OverlayControllerData customController;
  WidgetBuilder customControllers;
  PlayerData _playerData;
  final PlayerData playerData;
  bool _isLocal = false;
  bool get isPlayingLocally => _isLocal;

  @override
  void onInit() {
    anchoringPosition.value = AnchoringPosition.maximized;
    dragging.value = false;
    super.onInit();
  }

  void changeAnchor(AnchoringPosition _anchoringPosition, String tag) {
    debugPrint(
        // ignore: lines_longer_than_80_chars
        'changeAnchor old ${anchoringPosition.value} => $_anchoringPosition $tag');
    controlsIsShowing(false);
    anchoringPosition.value = _anchoringPosition;
  }

  void toggleControllers() {
    if (!controllersCanBeVisible.value) {
      return;
    }
    controlsIsShowing(!controlsIsShowing.value);
    debugPrint('toggleControllers to ${controlsIsShowing.value}');
    if (controlsIsShowing.value) {
      _startToggleOffTimer();
    } else {
      controllerTimer?.cancel();
    }
  }

  Future<void> createController() async {
    try {
      _playerData = playerData;
      final videoRes = (playerData.videoRes == null || playerData.useMockData)
          ? {'BigBunny': MockData.mp4Bunny, 'Other': MockData.shortMovie}
          : playerData.videoRes;
      final subtitleLink = playerData.subtitle;
      playerSettingsController.initVideoResolutions(videoRes);
      await setNewVideo();
      await playerSettingsController.initSubtitles(subtitleLink: subtitleLink);
      return;
    } catch (e, s) {
      debugPrint('createController $e $s');
      playerState = PlayerState.error;
      errorMessage = 'Error #1\n$e';
      return;
    }
  }

  Future<void> setNewVideo() async {
    playerState = PlayerState.normal;
    final filePath = playerSettingsController.getVideo();
    _isLocal = !filePath.startsWith('http');
    debugPrint('setNewVideo $filePath => isLocal? $_isLocal');
    if (_isLocal) {
      videoPlayerController = VideoPlayerController.file(File(filePath));
      await videoPlayerController.initialize().then((_) {
        videoPlayerController.seekTo(_getStartPosition());
        videoPlayerController.play();
      });
    } else {
      videoPlayerController = VideoPlayerController.network(filePath);
      await videoPlayerController.initialize().then((_) {
        videoPlayerController.seekTo(_getStartPosition());
        videoPlayerController.play();
      });
    }

    videoPlayerController.addListener(() async {
      await refreshWakelock();
      if (videoPlayerController.value.hasError) {
        errorMessage = videoPlayerController.value.errorDescription;
        playerState = PlayerState.error;
        update();
      }
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
    playerDispose();
    removeOverlay();
    _stopSavePositionTimer();
    videoPlayerController?.dispose();
    super.onClose();
  }

  void minimize() {
    changeAnchor(AnchoringPosition.minimized, 'minimize');
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
    isFullScreen.value = !isFullScreen.value;

    if (!isFullScreen.value) {
      changeAnchor(AnchoringPosition.maximized, 'toggleFullScreen');
      AutoOrientation.portraitAutoMode();
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    } else {
      changeAnchor(AnchoringPosition.fullScreen, 'toggleFullScreen');
      AutoOrientation.landscapeAutoMode();
      SystemChrome.setEnabledSystemUIOverlays([]);
    }
    update();
  }

  void showOverlay(BuildContext context, WidgetBuilder w) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(builder: (context) => w(context));
    Overlay.of(context).insert(_overlayEntry);
    debugPrint('overlay is showing');
  }

  DateTime overlayRemoveTimeStamp;
  void removeOverlay() {
    if (_overlayEntry != null) {
      overlayRemoveTimeStamp = DateTime.now();
      _overlayEntry?.remove();
      _overlayEntry = null;
      debugPrint('overlay removed');
    }
  }

  @override
  String toString() {
    // ignore: lines_longer_than_80_chars
    return 'FloatingViewController{toggleOffDuration: $toggleOffDuration, videoPlayerController: $videoPlayerController, controlsIsShowing: $controlsIsShowing, detailsTopPadding: $detailsTopPadding, screenSize: $screenSize, initialHeight: $initialHeight, controllerTimer: $controllerTimer, anchoringPosition: $anchoringPosition, isFullScreen: $isFullScreen, isMaximized: $isMaximized, dragging: $dragging, controllersCanBeVisible: $controllersCanBeVisible, canMinimize: $canMinimize, canClose: $canClose}';
  }

  bool overlayJustRemoved() {
    return _overlayEntry != null ||
        (overlayRemoveTimeStamp
                ?.add(const Duration(seconds: 1))
                ?.isAfter(DateTime.now()) ??
            false);
  }

  void playerDispose() async {
    savePosition();
    if (_playerData?.onDispose != null) {
      _playerData?.onDispose();
    }
  }

  void savePosition() {
    try {
      final currentPos = videoPlayerController?.value?.position?.inSeconds;
      final totalDuration = videoPlayerController?.value?.duration?.inSeconds;

      if (currentPos == null || totalDuration == null) {
        debugPrint('Position was null');
        return;
      }
      _playerData?.savePosition(SavePosition(
          seconds: currentPos,
          videoItem: _playerData.videoItem,
          totalSeconds: totalDuration,
          itemId: _playerData.itemId));
      debugPrint('Position sent to save from player');
    } catch (e) {
      debugPrint(e);
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
    savePositionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      savePosition();
    });
  }

  void resetControllerTimer() {
    controllerTimer?.cancel();
    _startToggleOffTimer();
  }

  final playerSettings = Get.find<PlayerCastSettings>();
  void startCasting(CastDevice device) {
    playerSettings.cast(device, _castMessage());
  }

  Map<String, dynamic> _castMessage() {
    return playerData.castMessage(
        videoLink: playerSettingsController.getVideo(),
        position: videoPlayerController.value.position);
  }

  void disconnectCasting() {
    playerSettings.disconnect();
  }

  Future<bool> disposePlayerRelatedControllers() async {
    await Get.delete<PlayerSettingsController>(force: true);
    return Get.delete<FloatingViewController>(force: true);
  }

  Duration _getStartPosition() {
    Duration result;
    //test
    const startPosition = Duration(seconds: 577);

    // final startPosition = playerData.startPosition ?? const Duration();
    if (startPosition + const Duration(seconds: 10) >
        videoPlayerController.value.duration) {
      result = const Duration();
      debugPrint('StartPosition #1');
    } else {
      if (startPosition - const Duration(seconds: 10) < const Duration()) {
        result = const Duration();
        debugPrint('StartPosition #2');
      } else {
        result = startPosition - const Duration(seconds: 10);
        debugPrint('StartPosition #3');
      }
    }
    debugPrint('StartPosition getter $startPosition => $result');
    return result;
  }

  bool isEnded() {
    return videoPlayerController.value.position.inSeconds ==
        videoPlayerController.value.duration.inSeconds;
  }
}
