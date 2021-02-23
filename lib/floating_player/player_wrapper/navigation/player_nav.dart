import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/draggable_widget.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/details/player_details.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player.dart';
import 'package:get/get.dart';

import '../controllers/video_view_controller.dart';

class PLayerNav {
  static OverlayEntry overlayEntry;

  static void showPlayer(BuildContext ctx) async {
    if (!clearViews()) {
      await Future.delayed(Duration(milliseconds: 200));
    }
    OverlayState overlayState = Overlay.of(ctx);
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
                              child: PLayerDetails(),
                            ),
                          ),
                        ),
                        // if (!model.isFullScreen)
                        DraggableWidget(
                          onRemove: () {
                            clearViews();
                          },
                          bottomMargin: 80,
                          intialVisibility: true,
                          horizontalSapce: 0,
                          dragAnimationScale: 0.5,
                          shadowBorderRadius: 0,
                          touchDelay: Duration(milliseconds: 100),
                          child: Player(
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
    overlayState.insert(overlayEntry);
  }

  static bool clearViews() {
    if (overlayEntry != null) {
      overlayEntry.remove();
      overlayEntry = null;
      FloatingViewController().dispose();
      return false;
    }
    return true;
  }

  static bool canPopup() {
    return clearViews();
  }
}
