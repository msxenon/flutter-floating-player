import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/draggable_widget.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_data.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';

import 'details/player_details.dart';

class FloatingWrapper extends StatefulWidget {
  FloatingWrapper(
      {@required this.onRemove,
      this.details,
      this.bgColor,
      this.playerData,
      this.bottomMargin = 80,
      this.customControllers,
      Key key})
      : controller = Get.put(
            FloatingViewController(playerData,
                customController: customControllers),
            permanent: true),
        super(key: key);
  final WidgetBuilder details;
  final Color bgColor;
  final Function onRemove;
  final double bottomMargin;
  final OverlayControllerData customControllers;
  final PlayerData playerData;
  final FloatingViewController controller;
  @override
  _FloatingWrapperState createState() => _FloatingWrapperState();
}

class _FloatingWrapperState extends State<FloatingWrapper> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<FloatingViewController>(
        init: widget.controller,
        // tag: widget.playerData.itemId,
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
                      duration: const Duration(milliseconds: 250),
                      opacity:
                          (model.isMaximized.value && !model.dragging.value)
                              ? 1
                              : 0,
                      child: PLayerDetails(
                        floatingViewController: model,
                        child: widget.details,
                        bgColor: widget.bgColor,
                      ),
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: DraggableWidget(
                    onRemove: widget.onRemove,
                    bottomMargin: widget.bottomMargin,
                    intialVisibility: true,
                    horizontalSapce: 0,
                    dragAnimationScale: 0.5,
                    shadowBorderRadius: 0,
                    initialHeight: model.initialHeight,
                    touchDelay: const Duration(milliseconds: 100),
                    child: Player(
                      floatingViewController: model,
                      key: Key(widget.playerData.itemId),
                      tag: widget.playerData.itemId,
                    ),
                    initialPosition: AnchoringPosition.maximized,
                  ),
                ),
              ],
            ),
          );
        });
  }
}
