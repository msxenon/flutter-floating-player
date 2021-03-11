import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/played_item_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';
import 'package:subtitle_wrapper_package/data/models/style/subtitle_style.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';

class Player extends StatefulWidget {
  final PlayerData playerData;
  const Player({Key? key, this.playerData = const PlayerData()})
      : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final FloatingViewController floatingViewController = Get.find();
  bool showPLayer = false;
  @override
  void initState() {
    _setControllers();
    super.initState();
  }

  void _setControllers() async {
    await floatingViewController.createController(widget.playerData);
    showPLayer = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlayerSettingsController>(
        init: floatingViewController.playerSettingsController,
        builder: (model) {
          if (!showPLayer ||
              floatingViewController.subtitleController == null) {
            return Center(child: CircularProgressIndicator());
          }
          return SubTitleWrapper(
            key: Key(
                floatingViewController.playerSettingsController!.getVideo()! +
                    'sub'),
            videoPlayerController: floatingViewController.subtitleController!,
            subtitleController: model.subtitleController!,
            subtitleStyle: SubtitleStyle(
              textColor: Colors.white,
              fontSize: model.isEnabled ? model.textSize : 0,
              hasBorder: true,
            ),
            videoChild: VlcPlayerWithControls(
              key: Key(
                  floatingViewController.playerSettingsController!.getVideo()!),
              controller: floatingViewController.videoPlayerController!,
            ),
          );
        });
  }
}
