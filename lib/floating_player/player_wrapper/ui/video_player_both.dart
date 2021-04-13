import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/subtitle/data/models/style/subtitle_position.dart';
import 'package:flutter_player/subtitle/data/models/style/subtitle_style.dart';
import 'package:flutter_player/subtitle/subtitle_wrapper_package.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:video_player/video_player.dart';

import 'advanced_overlay_widget.dart';

class VideoPlayerBothWidget extends StatefulWidget {
  final FloatingViewController controller;

  const VideoPlayerBothWidget({
    Key key,
    @required this.controller,
  }) : super(key: key);

  @override
  _VideoPlayerBothWidgetState createState() => _VideoPlayerBothWidgetState();
}

class _VideoPlayerBothWidgetState extends State<VideoPlayerBothWidget> {
  Orientation target;

  @override
  void initState() {
    super.initState();

    NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((event) {
      debugPrint('NativeDeviceOrientationCommunicator XXXX $event');
      //
      // final isPortrait = event == NativeDeviceOrientation.portraitUp;
      // final isLandscape = event == NativeDeviceOrientation.landscapeLeft ||
      //     event == NativeDeviceOrientation.landscapeRight;
      // final isTargetPortrait = target == Orientation.portrait;
      // final isTargetLandscape = target == Orientation.landscape;
      //
      // if (isPortrait && isTargetPortrait || isLandscape && isTargetLandscape) {
      //   target = null;
      //   SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      // }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    AutoOrientation.portraitAutoMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.controller != null &&
          widget.controller.videoPlayerController.value.initialized
      ? Container(alignment: Alignment.topCenter, child: buildVideo())
      : Center(child: CircularProgressIndicator());

  Widget buildVideo() => OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          debugPrint('setOrientation $orientation XXXX === $target');

          target = orientation;
          return Stack(
            fit: isPortrait ? StackFit.loose : StackFit.expand,
            children: <Widget>[
              buildVideoPlayer(),
              SubTitleWrapper(
                controller: widget.controller,
                subtitleController: widget
                    .controller.playerSettingsController.subtitleController,
                subtitleStyle: SubtitleStyle(
                    textColor: Colors.white,
                    fontSize: Theme.of(context).textTheme.subtitle1.fontSize *
                        widget.controller.playerSettingsController
                            .getTextSize(widget.controller.isFullScreen.value),
                    hasBorder: true,
                    position: SubtitlePosition(bottom: 5)),
              ),
              Positioned.fill(
                child: AdvancedOverlayWidget(
                  controller: widget.controller,
                  onClickedFullScreen: () {
                    widget.controller.toggleFullScreen();
                  },
                ),
              ),
            ],
          );
        },
      );

  Widget buildVideoPlayer() {
    final video = AspectRatio(
      aspectRatio: widget.controller.videoPlayerController.value.aspectRatio,
      child: VideoPlayer(widget.controller.videoPlayerController),
    );

    return buildFullScreen(child: video);
  }

  Widget buildFullScreen({
    @required Widget child,
  }) {
    final size = widget.controller.videoPlayerController.value.size;
    final width = size?.width ?? 0;
    final height = size?.height ?? 0;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}
