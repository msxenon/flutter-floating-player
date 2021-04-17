import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:flutter_player/player_init.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class AdvancedOverlayWidget extends StatelessWidget {
  const AdvancedOverlayWidget({
    @required this.controller,
    Key key,
    this.onClickedFullScreen,
  }) : super(key: key);
  final FloatingViewController controller;
  final VoidCallback onClickedFullScreen;

  static const autoSeekSeconds = 10;
  String getPosition() {
    final positonDuration = Duration(
        milliseconds: controller
            .videoPlayerController.value.position.inMilliseconds
            .round());
    final totalDuration = Duration(
        milliseconds: controller
            .videoPlayerController.value.duration.inMilliseconds
            .round());
    final position = [positonDuration.inMinutes, positonDuration.inSeconds]
        .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
        .join(':');
    final total = [totalDuration.inMinutes, totalDuration.inSeconds]
        .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
        .join(':');
    return '$position / $total';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: controller.toggleControllers,
        child: Obx(() {
          final double iconSize = controller.isFullScreen.value ? 40 : 24;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: controller.controlsIsShowing.value ? 1 : 0,
            child: IgnorePointer(
              ignoring: !controller.controlsIsShowing.value,
              child: Container(
                padding: controller.isFullScreen.value
                    ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                    : EdgeInsets.zero,
                color: Colors.black54,
                child: Stack(
                  children: <Widget>[
                    Center(child: buildPlay(iconSize)),
                    Positioned(
                      left: 8,
                      bottom: 28,
                      child: Text(
                        getPosition(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          Expanded(child: buildIndicator()),
                          const SizedBox(width: 12),
                          GestureDetector(
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 28,
                            ),
                            onTap: () {
                              controller.resetControllerTimer();
                              onClickedFullScreen();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!controller.isPlayingLocally)
                            CastIcon(
                              onTap: (f) {
                                showFloatingBottomSheet(
                                  context,
                                  controller,
                                  List.generate(f.length, (index) {
                                    final e = f[index];
                                    return FloatingSheetListTile(
                                      floatingViewController: controller,
                                      title: e.name,
                                      onTap: () => controller.startCasting(e),
                                    );
                                  }),
                                );
                              },
                            ),
                          IconButton(
                            onPressed: () => showFloatingBottomSheet(
                                context, controller, null),
                            color: Colors.white,
                            iconSize: iconSize,
                            icon: const Icon(Icons.menu),
                          ),
                        ],
                      ),
                    ),
                    if (controller.canMinimize.value)
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: IconButton(
                          onPressed: controller.minimize,
                          color: Colors.white,
                          iconSize: iconSize,
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                    if (controller.isFullScreen.value)
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            controller.playerData.itemTitle,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
        }),
      );

  Widget buildIndicator() => Container(
        margin: const EdgeInsets.all(8).copyWith(right: 0),
        height: 16,
        child: VideoProgressIndicator(
          controller.videoPlayerController,
          allowScrubbing: !controller.isLive(),
        ),
      );

  Widget buildPlay(double iconSize) {
    if (controller.videoPlayerController.value.isBuffering) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (controller.isEnded()) {
      return IconButton(
          icon: const Icon(
            Icons.replay_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            controller.videoPlayerController.seekTo(const Duration());
            controller.videoPlayerController.play();
          });
    }
    final canForward = (controller.videoPlayerController.value.duration -
                controller.videoPlayerController.value.position)
            .inSeconds >
        autoSeekSeconds;
    final canRewind =
        controller.videoPlayerController.value.position.inSeconds >
            autoSeekSeconds;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!controller.isLive())
          IconButton(
            icon: Icon(
              Icons.replay_10,
              color: canRewind ? Colors.white : Colors.white54,
              size: iconSize,
            ),
            onPressed: canRewind
                ? () {
                    controller.resetControllerTimer();

                    controller.videoPlayerController.seekTo(
                        controller.videoPlayerController.value.position -
                            const Duration(seconds: autoSeekSeconds));
                  }
                : null,
          ),
        controller.videoPlayerController.value.isPlaying
            ? IconButton(
                onPressed: () {
                  controller.resetControllerTimer();
                  controller.videoPlayerController.pause();
                },
                icon: Icon(
                  Icons.pause,
                  color: Colors.white,
                  size: iconSize,
                ),
              )
            : IconButton(
                onPressed: () => controller.videoPlayerController.play(),
                icon: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
        if (!controller.isLive())
          IconButton(
            icon: Icon(
              Icons.forward_10,
              color: canForward ? Colors.white : Colors.white54,
              size: iconSize,
            ),
            onPressed: canForward
                ? () {
                    controller.resetControllerTimer();

                    controller.videoPlayerController.seekTo(
                        controller.videoPlayerController.value.position +
                            const Duration(seconds: autoSeekSeconds));
                  }
                : null,
          ),
      ],
    );
  }
}
