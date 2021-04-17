import 'package:flutter/material.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/floating_view_controller.dart';
import 'package:flutter_player/floating_player/player_wrapper/logic/player_state_enum.dart';
import 'package:flutter_player/floating_player/player_wrapper/ui/player_wth_controllers.dart';
import 'package:get/get.dart';

class Player extends StatefulWidget {
  Player({
    @required this.floatingViewController,
    @required this.tag,
    Key key,
  }) : super(key: key);
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
        // tag: widget.tag,
        key: Key(widget.tag),
        builder: (model) {
          if (model.playerState == PlayerState.error) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(model.errorMessage)));
          }
          if (model.playerState == PlayerState.casting) {
            return Center(
                child: IconButton(
              icon: const Icon(
                Icons.cast_connected,
                color: Colors.white,
              ),
              onPressed: model.disconnectCasting,
            ));
          }
          if (model.playerSettingsController.subtitleController == null ||
              !showPLayer) {
            return const Center(child: CircularProgressIndicator());
          }
          return VlcPlayerWithControls(
            controller: model,
          );
        });
  }
}
