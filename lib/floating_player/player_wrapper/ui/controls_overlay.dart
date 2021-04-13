import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';

class ControlsOverlay extends StatelessWidget {
  ControlsOverlay(
      {Key key,
      this.position = '',
      this.duration = '',
      this.sliderValue,
      this.sliderUpdate})
      : super(key: key);
  final String position;
  final String duration;
  final double sliderValue;
  final Function(double) sliderUpdate;
  final FloatingViewController controller = Get.find<FloatingViewController>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // AnimatedSwitcher(
        //   duration: Duration(milliseconds: 50),
        //   reverseDuration: Duration(milliseconds: 200),
        //   child: Obx(() {
        //     if (!controller.isMaximized.value) {
        //       return SizedBox.shrink();
        //     }
        //     return Builder(
        //       builder: (ctx) {
        //         if (controller.videoPlayerController.value.) {
        //           return Center(
        //             child: IconButton(
        //               onPressed: () async {
        //                 await controller.videoPlayerController.stop();
        //                 await controller.videoPlayerController.play();
        //               },
        //               color: Colors.white,
        //               iconSize: 100.0,
        //               icon: Icon(Icons.replay),
        //             ),
        //           );
        //         } else {
        //           switch (controller.videoPlayerController.value.playingState) {
        //             case PlayingState.initializing:
        //               return CircularProgressIndicator();
        //
        //             case PlayingState.initialized:
        //             case PlayingState.stopped:
        //             case PlayingState.paused:
        //               return SizedBox.expand(
        //                 child: Container(
        //                   color: Colors.black45,
        //                   child: Row(
        //                     crossAxisAlignment: CrossAxisAlignment.center,
        //                     mainAxisAlignment: MainAxisAlignment.spaceAround,
        //                     children: [
        //                       IconButton(
        //                         onPressed: () async {
        //                           if (controller.videoPlayerController.value
        //                                   .duration !=
        //                               null) {
        //                             await controller.videoPlayerController
        //                                 .seekTo(controller.videoPlayerController
        //                                         .value.position -
        //                                     Duration(seconds: 10));
        //                           }
        //                         },
        //                         color: Colors.white,
        //                         iconSize: 60.0,
        //                         icon: Icon(Icons.replay_10),
        //                       ),
        //                       IconButton(
        //                         onPressed: () async {
        //                           await controller.videoPlayerController.play();
        //                         },
        //                         color: Colors.white,
        //                         iconSize: 100.0,
        //                         icon: Icon(Icons.play_arrow),
        //                       ),
        //                       IconButton(
        //                         onPressed: () async {
        //                           if (controller.videoPlayerController.value
        //                                   .duration !=
        //                               null) {
        //                             await controller.videoPlayerController
        //                                 .seekTo(controller.videoPlayerController
        //                                         .value.position +
        //                                     Duration(seconds: 10));
        //                           }
        //                         },
        //                         color: Colors.white,
        //                         iconSize: 60.0,
        //                         icon: Icon(Icons.forward_10),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               );
        //
        //             case PlayingState.buffering:
        //             case PlayingState.playing:
        //               return SizedBox.shrink();
        //
        //             case PlayingState.ended:
        //             case PlayingState.error:
        //               return Center(
        //                 child: IconButton(
        //                   onPressed: () async {
        //                     await controller.videoPlayerController.play();
        //                   },
        //                   color: Colors.white,
        //                   iconSize: 100.0,
        //                   icon: Icon(Icons.replay),
        //                 ),
        //               );
        //           }
        //         }
        //         return SizedBox.shrink();
        //       },
        //     );
        //   }),
        // ),
        Visibility(
          visible: controller.controllersCanBeVisible.value &&
              controller.controlsIsShowing.value,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              height: 50,
              color: Colors.black87,
              child: Row(
                children: [
                  ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: [
                      IconButton(
                        icon: Icon(Icons.more_vert),
                        color: Colors.white,
                        onPressed: () =>
                            showFloatingBottomSheet(context, controller, null),
                      ),
                      IconButton(
                        icon: Icon(Icons.cast),
                        color: Colors.white,
                        onPressed: () async {
                          // _getRendererDevices();
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Size: ' +
                              (controller.videoPlayerController.value.size
                                          ?.width
                                          ?.toInt() ??
                                      0)
                                  .toString() +
                              'x' +
                              (controller.videoPlayerController.value.size
                                          ?.height
                                          ?.toInt() ??
                                      0)
                                  .toString(),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        SizedBox(height: 5),
                        // Text(
                        //   'Status: ' +
                        //       controller
                        //           .videoPlayerController.value.playingState
                        //           .toString()
                        //           .split('.')[1],
                        //   textAlign: TextAlign.center,
                        //   overflow: TextOverflow.ellipsis,
                        //   style: TextStyle(color: Colors.white, fontSize: 10),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Visibility(
            visible: controller.controllersCanBeVisible.value,
            child: Container(
              height: 50,
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: controller.videoPlayerController.value.isPlaying
                        ? Icon(Icons.pause_circle_outline)
                        : Icon(Icons.play_circle_outline),
                    onPressed: () async {
                      return controller.videoPlayerController.value.isPlaying
                          ? await controller.videoPlayerController.pause()
                          : await controller.videoPlayerController.play();
                    },
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          position,
                          style: TextStyle(color: Colors.white),
                        ),
                        Expanded(
                          child: Slider(
                            activeColor: Colors.redAccent,
                            inactiveColor: Colors.white70,
                            value: sliderValue,
                            min: 0.0,
                            max: controller
                                        .videoPlayerController.value.duration ==
                                    null
                                ? 1.0
                                : controller.videoPlayerController.value
                                    .duration.inSeconds
                                    .toDouble(),
                            onChanged: (progress) {
                              sliderUpdate(progress);
                              //convert to Milliseconds since VLC requires MS to set time
                              // controller.videoPlayerController
                              //     .setTime(sliderValue.toInt() * 1000);
                            },
                          ),
                        ),
                        Text(
                          duration,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.fullscreen),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
