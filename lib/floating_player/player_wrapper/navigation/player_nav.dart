import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/draggable_widget.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/details/player_details.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player.dart';
import 'package:get/get.dart';

import '../controllers/video_view_controller.dart';

class PLayerNav {
  static OverlayEntry overlayEntry;

  static void showPlayer(BuildContext ctx, WidgetBuilder player, WidgetBuilder details, {Color bgColor}) async {
    if (!clearViews(forceClear: true)) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    overlayEntry = OverlayEntry(
        maintainState: true,
        opaque: false,
        builder: (context) {
          return Positioned.fill(
            child: GetBuilder<FloatingViewController>(
                init: FloatingViewController(),
                global: true,
                autoRemove: false,
                builder: (model) {
                  return Material(
                    type: MaterialType.transparency,
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Obx(
                          () => IgnorePointer(
                            ignoring: !model.isMaximized.value,
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 250),
                              opacity: model.isMaximized.value ? 1 : 0,
                              child: PLayerDetails(
                                child: details,
                                bgColor: bgColor,
                              ),
                            ),
                          ),
                        ),
                        // if (!model.isFullScreen)
                        DraggableWidget(
                          onRemove: () {
                            clearViews(forceClear: true);
                          },
                          bottomMargin: 80,
                          intialVisibility: true,
                          horizontalSapce: 0,
                          dragAnimationScale: 0.5,
                          shadowBorderRadius: 0,
                          initialHeight: model.initialHeight,
                          touchDelay: Duration(milliseconds: 100),
                          child: player != null
                              ? player(context)
                              : Player(
                                  usePlayerPlaceHolder: false,
                                ),
                          initialPosition: AnchoringPosition.maximized,
                        ),
                      ],
                    ),
                  );
                }),
          );
        });
    Overlay.of(ctx).insert(overlayEntry);
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
      print(e);
    }
    return true;
  }

  static bool canPopup() {
    return clearViews();
  }
}
