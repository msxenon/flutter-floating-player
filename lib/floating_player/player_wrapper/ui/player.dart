import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/mock_data.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';
import 'package:subtitle_wrapper_package/data/models/style/subtitle_style.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';

class Player extends StatefulWidget {
  final bool usePlayerPlaceHolder;
  final Widget customPlayer;

  const Player({Key key, this.usePlayerPlaceHolder, this.customPlayer}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final FloatingViewController floatingViewController = Get.find();
  @override
  void initState() {
    floatingViewController.createController(videoRes: {'BigBunny': MockData.mp4Bunny, 'Other': MockData.shortMovie}, subtitleLink: MockData.srt);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlayerSettingsController>(
        init: floatingViewController.playerSettingsController,
        builder: (model) {
          return SubTitleWrapper(
            key: Key(floatingViewController.playerSettingsController.getVideo() + 'sub'),
            videoPlayerController: floatingViewController.videoPlayerController,
            subtitleController: model.subtitleController,
            subtitleStyle: SubtitleStyle(
              textColor: Colors.white,
              fontSize: model.isEnabled ? model.textSize : 0,
              hasBorder: true,
            ),
            videoChild: VlcPlayerWithControls(
              key: Key(floatingViewController.playerSettingsController.getVideo()),
              controller: floatingViewController.videoPlayerController,
            ),
          );
        });
  }
}
