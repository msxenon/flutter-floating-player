import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/subtitle/data/models/style/subtitle_style.dart';
import 'package:flutter_player/subtitle/subtitle_wrapper_package.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';

import 'controls_overlay.dart';

typedef OverlayControllerData = Widget Function(
    {@required String position,
    @required String duration,
    @required double sliderValue,
    @required Function(double) sliderUpdate,
    @required VlcPlayerController controller});

class VlcPlayerWithControls extends StatefulWidget {
  final FloatingViewController controller;

  VlcPlayerWithControls({
    Key key,
    @required this.controller,
  })  : assert(controller != null, 'You must provide a vlc controller'),
        super(key: key);

  @override
  VlcPlayerWithControlsState createState() => VlcPlayerWithControlsState();
}

class VlcPlayerWithControlsState extends State<VlcPlayerWithControls>
    with AutomaticKeepAliveClientMixin {
  //
  final double initSnapshotRightPosition = 10;
  final double initSnapshotBottomPosition = 10;

  //
  double sliderValue = 0.0;
  String position = '';
  String duration = '';
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;

  //
  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.videoPlayerController.addListener(listener);
  }

  void listener() async {
    if (!mounted) return;
    //
    if (widget.controller.videoPlayerController.value.isInitialized) {
      var oPosition = widget.controller.videoPlayerController.value.position;
      var oDuration = widget.controller.videoPlayerController.value.duration;
      if (oPosition != null && oDuration != null) {
        if (oDuration.inHours == 0) {
          var strPosition = oPosition.toString().split('.')[0];
          var strDuration = oDuration.toString().split('.')[0];
          position =
              "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          duration =
              "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        } else {
          position = oPosition.toString().split('.')[0];
          duration = oDuration.toString().split('.')[0];
        }
        setSliderValue(widget
            .controller.videoPlayerController.value.position.inSeconds
            .toDouble());
      }
      numberOfCaptions =
          widget.controller.videoPlayerController.value.spuTracksCount;
      numberOfAudioTracks =
          widget.controller.videoPlayerController.value.audioTracksCount;
      //
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Center(
                child: VlcPlayer(
                  controller: widget.controller.videoPlayerController,
                  aspectRatio: 16 / 9,
                  placeholder: Center(child: CircularProgressIndicator()),
                ),
              ),
              SubTitleWrapper(
                controller: widget.controller,
                subtitleController: widget
                    .controller.playerSettingsController.subtitleController,
                subtitleStyle: SubtitleStyle(
                  textColor: Colors.white,
                  fontSize: Theme.of(context).textTheme.subtitle1.fontSize *
                      widget.controller.playerSettingsController.textSize,
                  hasBorder: true,
                ),
              ),
              widget.controller.customController != null
                  ? widget.controller.customController(
                      controller: widget.controller.videoPlayerController,
                      position: position,
                      duration: duration,
                      sliderValue: sliderValue,
                      sliderUpdate: (progress) {
                        setState(() {
                          setSliderValue(progress.floor().toDouble());
                        });
                      })
                  : ControlsOverlay(
                      position: position,
                      duration: duration,
                      sliderValue: sliderValue,
                      sliderUpdate: (progress) {
                        setState(() {
                          setSliderValue(progress.floor().toDouble());
                        });
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  setSliderValue(double newSliderValue) {
    if (widget.controller.videoPlayerController.value.isEnded) {
      sliderValue = widget
          .controller.videoPlayerController.value.duration.inSeconds
          .toDouble();
    } else {
      sliderValue = newSliderValue;
    }
  }
}

showFloatingBottomSheet(BuildContext context,
    FloatingViewController floatingViewController, List<Widget> list) {
  floatingViewController.showOverlay(context, (context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => floatingViewController.removeOverlay(),
        child: Container(
          constraints: BoxConstraints.expand(),
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: FloatingBottomSheet(
                    children: (list ??
                        [
                          FloatingSheetListTile(
                            floatingViewController: floatingViewController,
                            title: 'Captions'.tr,
                            icon: Icons.closed_caption_outlined,
                            titleStatus: floatingViewController
                                .playerSettingsController
                                .getCaptionStringValue(),
                            onTap: floatingViewController
                                        .playerSettingsController.isEnabled ==
                                    null
                                ? null
                                : () {
                                    showFloatingBottomSheet(
                                        context, floatingViewController, [
                                      FloatingSheetListTile(
                                        floatingViewController:
                                            floatingViewController,
                                        selected: floatingViewController
                                                .playerSettingsController
                                                .isEnabled ==
                                            false,
                                        title: 'Off'.tr,
                                        onTap: () => floatingViewController
                                            .playerSettingsController
                                            .toggleSubtitle(false),
                                      ),
                                      FloatingSheetListTile(
                                        floatingViewController:
                                            floatingViewController,
                                        selected: floatingViewController
                                            .playerSettingsController.isEnabled,
                                        title: 'Arabic'.tr,
                                        onTap: () => floatingViewController
                                            .playerSettingsController
                                            .toggleSubtitle(true),
                                      ),
                                    ]);
                                  },
                          ),
                          if (floatingViewController
                              .playerSettingsController.isEnabled)
                            FloatingSheetListTile(
                              floatingViewController: floatingViewController,
                              title: 'Text_size'.tr,
                              icon: Icons.text_fields_outlined,
                              titleStatus: floatingViewController
                                  .playerSettingsController.textEnum
                                  .toString()
                                  .split('.')[1]
                                  .capitalize,
                              onTap: () {
                                showFloatingBottomSheet(
                                    context,
                                    floatingViewController,
                                    List.generate(TextSizes.values.length,
                                        (index) {
                                      var key = TextSizes.values[index];
                                      return FloatingSheetListTile(
                                        floatingViewController:
                                            floatingViewController,
                                        selected: floatingViewController
                                                .playerSettingsController
                                                .textEnum ==
                                            key,
                                        title: key
                                            .toString()
                                            .split('.')[1]
                                            .capitalize,
                                        onTap: () => floatingViewController
                                            .playerSettingsController
                                            .setTextSize(key),
                                      );
                                    }));
                              },
                            ),
                          if (floatingViewController.playerSettingsController
                                  .videoResolutions.length >
                              1)
                            FloatingSheetListTile(
                              floatingViewController: floatingViewController,
                              title: 'Video_Resolution'.tr,
                              icon: Icons.video_settings_outlined,
                              titleStatus: floatingViewController
                                  .playerSettingsController.selectedRes,
                              onTap: () {
                                showFloatingBottomSheet(
                                    context,
                                    floatingViewController,
                                    List.generate(
                                        floatingViewController
                                            .playerSettingsController
                                            .videoResolutions
                                            .length, (index) {
                                      var key = floatingViewController
                                          .playerSettingsController
                                          .videoResolutions
                                          .keys
                                          .toList()[index];
                                      return FloatingSheetListTile(
                                        floatingViewController:
                                            floatingViewController,
                                        selected: floatingViewController
                                                .playerSettingsController
                                                .selectedRes ==
                                            key,
                                        title: key,
                                        onTap: () => floatingViewController
                                            .playerSettingsController
                                            .changeVideoRes(key),
                                      );
                                    }));
                              },
                            )
                        ])
                      ..addAll([
                        Container(
                          height: 1,
                          color: floatingViewController
                              .floatingBottomSheetDivColor,
                        ),
                        FloatingSheetListTile(
                          floatingViewController: floatingViewController,
                          title: 'Cancel'.tr,
                          icon: Icons.close,
                          onTap: () {},
                        )
                      ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

//todo
class FloatingSheetListTile extends StatelessWidget {
  final FloatingViewController floatingViewController;
  final Function onTap;
  final String title;
  final String titleStatus;
  final bool selected;
  final IconData icon;
  const FloatingSheetListTile(
      {Key key,
      @required this.floatingViewController,
      this.onTap,
      this.selected,
      @required this.title,
      this.titleStatus,
      this.icon})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon ?? Icons.check,
        color: (selected == true || icon != null)
            ? floatingViewController.floatingBottomSheetTextColor
            : Colors.transparent,
      ),
      title: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: title,
            style: TextStyle(
                color: floatingViewController.floatingBottomSheetTextColor),
          ),
          if (titleStatus != null)
            TextSpan(
              text: ' - ',
              style: TextStyle(
                  color: floatingViewController.floatingBottomSheetTextColor
                      .withOpacity(0.5)),
            ),
          if (titleStatus != null)
            TextSpan(
              text: titleStatus,
              style: TextStyle(
                  color: floatingViewController.floatingBottomSheetTextColor
                      .withOpacity(0.5)),
            ),
        ]),
      ),
      onTap: onTap != null
          ? () {
              floatingViewController.removeOverlay();
              onTap();
            }
          : null,
    );
  }
}

class FloatingBottomSheet extends StatefulWidget {
  final List<Widget> children;

  FloatingBottomSheet({Key key, @required this.children}) : super(key: key);
  final FloatingViewController floatingViewController = Get.find();
  @override
  _FloatingBottomSheetState createState() {
    return _FloatingBottomSheetState();
  }
}

class _FloatingBottomSheetState extends State<FloatingBottomSheet>
    with SingleTickerProviderStateMixin {
  bool show = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        show = true;
      });
    });
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      alignment: Alignment.topLeft,
      width: MediaQuery.of(Get.context).size.width,
      height: show
          ? min(MediaQuery.of(context).size.height,
              (widget.children.length * 50.0) + 10)
          : 0,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.floatingViewController.floatingBottomSheetBgColor,
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: widget.children,
        ),
      ),
    );
  }
}
