import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/floating_player.dart';
import 'package:get/get.dart';

import '../controllers/video_view_controller.dart';

class PLayerNav {
  static OverlayEntry overlayEntry;

  static void showPlayer(BuildContext ctx, WidgetBuilder player, WidgetBuilder details, {Color bgColor, double bottomMargin: 80}) async {
    if (!clearViews(forceClear: true)) {
      await Future.delayed(Duration(milliseconds: 200));
    }
    overlayEntry = OverlayEntry(
        maintainState: true,
        opaque: false,
        builder: (context) {
          return FloatingWrapper(
            onRemove: () {
              clearViews(forceClear: true);
            },
            player: player,
            details: details,
            bgColor: bgColor,
            bottomMargin: bottomMargin,
          );
        });
    Overlay.of(ctx, rootOverlay: false).insert(overlayEntry);
  }

  static bool clearViews({bool forceClear: false}) {
    try {
      final controller = Get.find<FloatingViewController>();
      if (forceClear && overlayEntry != null) {
        overlayEntry.remove();
        overlayEntry = null;
        controller.onClose();
        return false;
      } else {
        if (controller.isMaximized.value) {
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
    return clearViews();
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
          return PLayerNav.clearViews();
        });
  }
}

extension ScaffoldExts on Scaffold {
  Widget attachPLayerAware() => PlayerAwareScaffold(
        child: this,
      );
}
