import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/subtitle/data/models/style/subtitle_position.dart';
import 'package:flutter_player/subtitle/data/models/style/subtitle_style.dart';
import 'package:flutter_player/subtitle/subtitle_wrapper_package.dart';
import 'package:video_player/video_player.dart';

import 'advanced_overlay_widget.dart';

class VideoPlayerBothWidget extends StatefulWidget {
  const VideoPlayerBothWidget({
    @required this.controller,
    Key key,
  }) : super(key: key);

  final FloatingViewController controller;

  @override
  _VideoPlayerBothWidgetState createState() => _VideoPlayerBothWidgetState();
}

class _VideoPlayerBothWidgetState extends State<VideoPlayerBothWidget> {
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
      : const Center(child: CircularProgressIndicator());

  Widget buildVideo() => OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
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
                    position: const SubtitlePosition(bottom: 5)),
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
