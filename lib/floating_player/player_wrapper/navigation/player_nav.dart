import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/played_item_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/floating_player.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';

import '../controllers/video_view_controller.dart';

class PLayerNav {
  static OverlaySupportEntry overlayEntry;
  static String _lastOverlayId;
  static void showPlayer(
      {@required PlayerData playerData,
      @required WidgetBuilder details,
      @required Color bgColor,
      double bottomMargin = 80,
      OverlayControllerData customControllers}) async {
    if (_lastOverlayId == playerData.itemId) {
      return;
    }
    await _removeOverlayIfExist(bgColor);
    kNotificationSlideDuration = const Duration(milliseconds: 0);
    _lastOverlayId = playerData.itemId;

    final newXX = showOverlay((context, progress) {
      return FloatingWrapper(
        key: Key('player:$_lastOverlayId'),
        customControllers: customControllers,
        onRemove: () {
          _removeOverlayIfExist(null);
          // clearViews('onRemove', forceClear: true);
        },
        playerData: playerData,
        details: details,
        bgColor: bgColor,
        bottomMargin: bottomMargin,
      );
    },
        // key: Key('PlayerOverlay$_lastOverlayId'),
        duration: Duration.zero,
        curve: Curves.decelerate);
    overlayEntry?.dismiss(animate: false);
    overlayEntry = newXX;
  }

  ///returns false if overlay just dismissed
  static bool clearViews(String tag,
      {bool forceClear = false, bool justMinimize = true}) {
    try {
      //print('clearView called $forceClear ${overlayEntry != null} $tag');
      if (overlayEntry != null) {
        final controller = Get.find<FloatingViewController>();

        void forceClearVoid() {
          overlayEntry.dismiss(animate: false);
          overlayEntry = null;
          _lastOverlayId = null;
        }

        if (forceClear || controller.playerState == PlayerState.error) {
          forceClearVoid();
          return false;
        }
        if (controller.isFullScreen.value) {
          controller.toggleFullScreen();
          return false;
        } else if (controller.isMaximized.value &&
            !controller.overlayJustRemoved()) {
          controller.minimize();
          return false;
        }
      }
    } catch (e) {
      // print(e);
    }
    return true;
  }

  static bool canPopup() {
    return clearViews('canPopup');
  }

  static Future<void> _removeOverlayIfExist(Color bgColor) async {
    if (overlayEntry == null) {
      return;
    }
    if (bgColor != null) {
      showOverlay((context, progress) {
        return Container(
          color: bgColor,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }, duration: const Duration(milliseconds: 150));
    }
    overlayEntry.dismiss(animate: false);
    overlayEntry = null;
    _lastOverlayId = null;
    await Future.delayed(const Duration(milliseconds: 100));
    return;
  }
}

class PlayerAwareScaffold extends StatelessWidget {
  const PlayerAwareScaffold({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: child,
        onWillPop: () async {
          return PLayerNav.clearViews('WillPopScope');
        });
  }
}

extension ScaffoldExts on Scaffold {
  Widget attachPLayerAware() => PlayerAwareScaffold(
        child: this,
      );
}
