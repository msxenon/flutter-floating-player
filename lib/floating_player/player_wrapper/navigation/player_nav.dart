import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_data.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_state_enum.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/floating_player.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';

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
  static Future<bool> clearViews(String tag,
      {bool forceClear = false, bool justMinimize = true}) async {
    try {
      //print('clearView called $forceClear ${overlayEntry != null} $tag');
      final currentRoute = Get.currentRoute;
      bool hasPLayerOpen = false;
      if (overlayEntry != null) {
        hasPLayerOpen = true;
        final controller = Get.find<FloatingViewController>();

        if (forceClear || controller.playerState == PlayerState.error) {
          await _closePlayer();
          return false;
        }
        if (controller.isFullScreen.value) {
          controller.toggleFullScreen();
          return false;
        } else if (controller.isMaximized.value &&
            !controller.overlayJustRemoved()) {
          controller.minimize();
          return false;
        } else if (currentRoute == '/') {}
      }
      debugPrint(
          // ignore: lines_longer_than_80_chars
          'PLayer BackAction Interceptor $currentRoute isPLayerOverlay $hasPLayerOpen $tag');
    } catch (e, s) {
      // ignore: prefer_interpolation_to_compose_strings
      debugPrint(
          // ignore: prefer_interpolation_to_compose_strings
          e +
              s.toString() +
              ' ========================================== $tag');
    }
    return true;
  }

  static Future<void> _closePlayer() async {
    overlayEntry?.dismiss(animate: false);
    overlayEntry = null;
    _lastOverlayId = null;
    final controller = Get.find<FloatingViewController>();
    await controller?.disposePlayerRelatedControllers();

    return;
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
    await _closePlayer();
    await Future.delayed(const Duration(milliseconds: 50));
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
