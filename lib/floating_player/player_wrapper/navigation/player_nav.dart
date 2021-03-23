import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/floating_player.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';

import '../controllers/video_view_controller.dart';

class PLayerNav {
  static OverlaySupportEntry overlayEntry;
  static String _lastOverlayId;
  static void showPlayer(
      BuildContext _ctx, WidgetBuilder player, WidgetBuilder details,
      {@required String overlayId,
      Color bgColor,
      double bottomMargin: 80,
      OverlayControllerData customControllers}) async {
    if (_lastOverlayId == overlayId) {
      return;
    } else if (!clearViews('showPlayer', forceClear: true)) {
      await Future.delayed(Duration(milliseconds: 200));
    }
    _lastOverlayId = overlayId;
    overlayEntry = showOverlay((context, double) {
      return FloatingWrapper(
        customControllers: customControllers,
        onRemove: () {
          clearViews('onRemove', forceClear: true);
        },
        player: player,
        details: details,
        bgColor: bgColor,
        bottomMargin: bottomMargin,
      );
    }, key: ModalKey(overlayId), duration: Duration.zero);
  }

  ///returns false if overlay just dismissed
  static bool clearViews(String tag, {bool forceClear: false}) {
    try {
      //print('clearView called $forceClear ${overlayEntry != null} $tag');
      if (forceClear && overlayEntry != null) {
        overlayEntry.dismiss(animate: false);
        overlayEntry = null;
        _lastOverlayId = null;
        final controller = Get.find<FloatingViewController>();
        controller.onClose();
        return false;
      } else if (overlayEntry != null) {
        final controller = Get.find<FloatingViewController>();
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
}

class PlayerAwareScaffold extends StatelessWidget {
  final Widget child;

  const PlayerAwareScaffold({Key key, this.child}) : super(key: key);
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
