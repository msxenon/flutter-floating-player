import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/draggable_widget.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';

import 'controls_overlay.dart';
import 'details/player_details.dart';

class FloatingWrapper extends StatefulWidget {
  final WidgetBuilder player;
  final WidgetBuilder details;
  final Color bgColor;
  final Function onRemove;
  final double bottomMargin;
  final OverlayControllerData customControllers;
  FloatingWrapper({this.player, this.details, this.bgColor, @required this.onRemove, this.bottomMargin: 80, this.customControllers, Key key}) : super(key: key);

  @override
  _FloatingWrapperState createState() => _FloatingWrapperState();
}

class _FloatingWrapperState extends State<FloatingWrapper> {
  final FloatingViewController floatingViewController = Get.put(FloatingViewController(), permanent: true);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    floatingViewController.anchoringPosition(AnchoringPosition.maximized);
    floatingViewController.customControllers = (f) => ControlsOverlay();
    if (widget.customControllers != null) {
      floatingViewController.customController = widget.customControllers;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FloatingViewController>(
        init: floatingViewController,
        autoRemove: true,
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
                      opacity: (model.isMaximized.value && !model.dragging.value) ? 1 : 0,
                      child: PLayerDetails(
                        child: widget.details,
                        bgColor: widget.bgColor,
                      ),
                    ),
                  ),
                ),
                DraggableWidget(
                  onRemove: widget.onRemove,
                  bottomMargin: widget.bottomMargin,
                  intialVisibility: true,
                  horizontalSapce: 0,
                  dragAnimationScale: 0.5,
                  shadowBorderRadius: 0,
                  initialHeight: model.initialHeight,
                  touchDelay: Duration(milliseconds: 100),
                  child: widget.player != null ? widget.player(context) : Player(),
                  initialPosition: AnchoringPosition.maximized,
                ),
              ],
            ),
          );
        });
  }
}
