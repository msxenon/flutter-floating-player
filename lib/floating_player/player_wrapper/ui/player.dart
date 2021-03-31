import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/controllers/video_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';
import 'package:subtitle_wrapper_package/data/models/style/subtitle_style.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';

class Player extends StatefulWidget {
  Player({Key key, @required this.floatingViewController, @required this.tag})
      : super(key: key);
  final FloatingViewController floatingViewController;
  final String tag;
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  bool showPLayer = false;

  @override
  void initState() {
    _setControllers();
    super.initState();
  }

  void _setControllers() async {
    await widget.floatingViewController.createController();
    showPLayer = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FloatingViewController>(
        init: widget.floatingViewController,
        tag: widget.tag,
        key: Key(widget.tag),
        builder: (model) {
          if (model.playerSettingsController.subtitleController == null ||
              !showPLayer) {
            return Center(child: CircularProgressIndicator());
          }
          return SubTitleWrapper(
            videoPlayerController: model.playerSettingsController,
            subtitleController:
                model.playerSettingsController.subtitleController,
            subtitleStyle: SubtitleStyle(
              textColor: Colors.white,
              fontSize: model.playerSettingsController.isEnabled
                  ? model.playerSettingsController.textSize
                  : 0,
              hasBorder: true,
            ),
            videoChild: VlcPlayerWithControls(
              controller: model,
            ),
          );
        });
  }
}
