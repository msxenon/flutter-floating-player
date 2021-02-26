import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/draggable_widget.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player.dart';
import 'package:get/get.dart';

import 'details/player_details.dart';

class FloatingWrapper extends StatefulWidget {
  final WidgetBuilder player;
  final WidgetBuilder details;
  final Color bgColor;
  final Function onRemove;
  FloatingWrapper({this.player, this.details, this.bgColor, @required this.onRemove, Key key}) : super(key: key);

  @override
  _FloatingWrapperState createState() => _FloatingWrapperState();
}

class _FloatingWrapperState extends State<FloatingWrapper> {
  final FloatingViewController floatingViewController = Get.put(FloatingViewController(), permanent: true);

  OverlayEntry myOverlay;
  @override
  void dispose() {
    floatingViewController.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FloatingViewController>(
        init: floatingViewController,
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
                        child: widget.details,
                        bgColor: widget.bgColor,
                      ),
                    ),
                  ),
                ),
                if (!model.isFullScreen)
                  DraggableWidget(
                    onRemove: widget.onRemove,
                    bottomMargin: 80,
                    intialVisibility: true,
                    horizontalSapce: 0,
                    dragAnimationScale: 0.5,
                    shadowBorderRadius: 0,
                    initialHeight: model.initialHeight,
                    touchDelay: Duration(milliseconds: 100),
                    child: widget.player != null
                        ? widget.player(context)
                        : Player(
                            usePlayerPlaceHolder: false,
                          ),
                    initialPosition: AnchoringPosition.maximized,
                  ),
              ],
            ),
          );
        });
  }
}
